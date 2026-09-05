package com.medbuddy.medbuddy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

/**
 * The dose alarm: a foreground service that rings, covers the screen, and
 * releases only when the dose is verified, the user says they can't take it,
 * or the ceiling is reached.
 *
 * The overlay uses TYPE_ACCESSIBILITY_OVERLAY when MedBuddyAccessibility is
 * enabled (survives BACK/HOME); it falls back to TYPE_APPLICATION_OVERLAY when
 * only SYSTEM_ALERT_WINDOW is granted. If neither is available the service
 * still runs and still rings — the full-screen-intent notification is then the
 * way back into the app.
 *
 * The service MUST call [startForeground] on every entry into onStartCommand:
 * it is started via startForegroundService(), and Android 12+ throws
 * ForegroundServiceDidNotStartInTimeException if the promotion doesn't happen
 * within ~5 seconds.
 */
class LockOverlayService : Service() {

    private val tag = "LockOverlayService"
    private var overlay: View? = null
    private var windowManager: WindowManager? = null
    private var ringer: AlarmRinger? = null
    private val handler = Handler(Looper.getMainLooper())
    private var countdownView: TextView? = null

    companion object {
        const val ACTION_SHOW = "com.medbuddy.medbuddy.LOCK_SHOW"
        const val ACTION_HIDE = "com.medbuddy.medbuddy.LOCK_HIDE"

        /** User pressed "I can't take it now" — stop, and let Dart log it. */
        const val ACTION_SKIP = "com.medbuddy.medbuddy.LOCK_SKIP"

        /**
         * User pressed "Verify now" on the overlay: drop the window so the app
         * underneath is reachable, but keep ringing and keep the lock armed.
         * The accessibility service re-shows the overlay if they wander off.
         */
        const val ACTION_UNCOVER = "com.medbuddy.medbuddy.LOCK_UNCOVER"

        const val EXTRA_MED_NAME = "med_name"

        private const val CHANNEL_ID = "medbuddy_dose_alarm"
        private const val NOTIFICATION_ID = 4201

        /** Why an alarm ended without a verification. See [PendingOutcomes]. */
        const val REASON_SKIPPED = "skipped"
        const val REASON_CEILING = "ceiling"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        LockState.restore(this)
        ringer = AlarmRinger(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Promote first, always. Anything that can throw must happen after
        // this or the service is killed mid-start. On Android 12+ a start
        // from a background context can be refused outright
        // (ForegroundServiceStartNotAllowedException); treat that as "no alarm
        // this time" rather than crashing the process on the main thread.
        try {
            startForeground(NOTIFICATION_ID, buildNotification(intent))
        } catch (e: Exception) {
            Log.e(tag, "startForeground refused — alarm cannot run.", e)
            LockState.setLocked(this, false)
            stopSelf()
            return START_NOT_STICKY
        }

        when (intent?.action) {
            ACTION_SHOW -> beginAlarm()
            ACTION_UNCOVER -> uncoverForVerification()
            ACTION_SKIP -> endAlarm(REASON_SKIPPED)
            ACTION_HIDE -> stopAlarmAndSelf()
            else -> stopAlarmAndSelf()
        }
        return START_NOT_STICKY
    }

    // ---- Alarm lifecycle -------------------------------------------------

    private fun beginAlarm() {
        // Re-assert the window every time: the accessibility service sends
        // ACTION_SHOW when the user leaves the app mid-alarm, and the overlay
        // may have been dropped by ACTION_UNCOVER.
        showOverlay()
        if (ringer?.isRinging == true) return

        ringer?.start()

        // Hard ceiling. Never ring forever: a phone left in another room would
        // otherwise ring until the battery dies, and someone who genuinely
        // cannot take the dose would be trapped.
        val ceilingMillis = AlarmPrefs.CEILING_MINUTES * 60_000L
        handler.postDelayed({ endAlarm(REASON_CEILING) }, ceilingMillis)
        handler.post(countdownTick)
    }

    /**
     * Ends the alarm without a verification and parks the reason for Dart to
     * write to `compliance_logs`. Parked rather than pushed because this can
     * happen with no Flutter engine alive — see [PendingOutcomes].
     */
    private fun endAlarm(reason: String) {
        Log.i(tag, "Alarm ended: $reason")
        PendingOutcomes.add(this, LockState.medId(this), reason)
        stopAlarmAndSelf()
    }

    private fun uncoverForVerification() {
        hideOverlay()
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        if (launch != null) {
            try {
                startActivity(launch)
            } catch (e: Exception) {
                Log.w(tag, "Could not launch app from overlay", e)
            }
        }
    }

    private fun stopAlarmAndSelf() {
        handler.removeCallbacksAndMessages(null)
        ringer?.stop()
        hideOverlay()
        LockState.setLocked(this, false)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private val countdownTick = object : Runnable {
        override fun run() {
            val view = countdownView ?: return
            val ceilingMillis = AlarmPrefs.CEILING_MINUTES * 60_000L
            val remaining = (ceilingMillis - LockState.elapsedMillis(this@LockOverlayService))
                .coerceAtLeast(0L)
            val secs = remaining / 1000
            view.text = "Stops on its own in %d:%02d".format(secs / 60, secs % 60)
            if (remaining > 0) handler.postDelayed(this, 1000)
        }
    }

    // ---- Notification ----------------------------------------------------

    private fun buildNotification(intent: Intent?): Notification {
        ensureChannel()

        val medName = intent?.getStringExtra(EXTRA_MED_NAME)
            ?.takeIf { it.isNotBlank() }
            ?: LockState.medName(this).takeIf { it.isNotBlank() }
            ?: "your medication"

        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val contentPi = PendingIntent.getActivity(
            this,
            0,
            launch ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Time for $medName")
            .setContentText("Verify your dose to stop the alarm.")
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setContentIntent(contentPi)

        // The way back in when no overlay can be drawn. Requires
        // USE_FULL_SCREEN_INTENT in the manifest, which alarm apps get. Only
        // attach it when it is actually needed: with the overlay up, a
        // full-screen-intent notification just pins a heads-up over the top
        // of the camera screen and hides its close button.
        if (!canShowOverlay()) builder.setFullScreenIntent(contentPi, true)
        return builder.build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Dose alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Rings until you verify your dose."
            // The ringing is driven by AlarmRinger on STREAM_ALARM, not by the
            // notification, so the channel itself stays silent — otherwise the
            // user hears two sounds at once.
            setSound(null, null)
            enableVibration(false)
            setBypassDnd(true)
        }
        nm.createNotificationChannel(channel)
    }

    // ---- Overlay ---------------------------------------------------------

    private fun canShowOverlay(): Boolean =
        MedBuddyAccessibility.instance != null || Settings.canDrawOverlays(this)

    private fun showOverlay() {
        if (overlay != null) return
        val canDraw = Settings.canDrawOverlays(this)

        val accessibilityActive = MedBuddyAccessibility.instance != null
        if (!accessibilityActive && !canDraw) {
            // No overlay permission. The alarm still rings and the full-screen
            // intent still fires — we just can't cover other apps.
            Log.w(tag, "No overlay permission — ringing without overlay.")
            return
        }

        val type = if (accessibilityActive)
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.TOP or Gravity.START

        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        val view = inflater.inflate(R.layout.lock_overlay, null, false)

        view.findViewById<TextView>(R.id.lock_title)?.text =
            LockState.medName(this).takeIf { it.isNotBlank() }
                ?.let { "Time for $it" }
                ?: "Time to verify your dose"

        countdownView = view.findViewById(R.id.lock_countdown)

        // The escape hatch. Always present — someone who is out of medication,
        // in hospital, or driving must be able to stop this. It is recorded,
        // not silent: the monitor sees that they said they couldn't.
        view.findViewById<Button>(R.id.lock_skip)?.setOnClickListener {
            endAlarm(REASON_SKIPPED)
        }

        view.findViewById<Button>(R.id.lock_verify)?.setOnClickListener {
            // Launching the app while this opaque, touch-consuming window is
            // still attached puts MedBuddy *under* the overlay. Drop the
            // window first; the alarm keeps ringing until the dose is verified.
            uncoverForVerification()
        }

        // TYPE_ACCESSIBILITY_OVERLAY windows carry the accessibility service's
        // token, so they must be added through *its* WindowManager. Adding one
        // via a plain Service's WindowManager throws BadTokenException.
        val wm = (if (accessibilityActive) MedBuddyAccessibility.instance else null)
            ?.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            ?: getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm.addView(view, params)
            overlay = view
            windowManager = wm
            Log.i(tag, "Overlay shown (type=$type).")
        } catch (e: Exception) {
            Log.e(tag, "addView failed — ringing without overlay.", e)
        }
    }

    private fun hideOverlay() {
        countdownView = null
        val view = overlay ?: return
        runCatching { windowManager?.removeView(view) }
        overlay = null
        windowManager = null
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        ringer?.stop()
        hideOverlay()
        super.onDestroy()
    }
}
