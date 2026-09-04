package com.medbuddy.medbuddy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * Fires when the scheduled dose alarm reaches its time. Independent of the
 * Flutter VM — works whether the app is killed, backgrounded, or open.
 *
 * Marks the lock active, then hands off to [LockOverlayService] which does the
 * ringing. A partial wake lock is held across the handoff: the receiver's own
 * guarantee ends when onReceive returns, and without it the device can fall
 * back to sleep before the service has started its ringer.
 *
 * Re-schedules the same medication for the next day so the alarm recurs
 * without a trip through Dart.
 */
class LockAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_FIRE = "com.medbuddy.medbuddy.ACTION_LOCK_FIRE"
        const val EXTRA_MED_ID = "med_id"
        const val EXTRA_MED_NAME = "med_name"
        const val EXTRA_HOUR = "med_hour"
        const val EXTRA_MINUTE = "med_minute"
        private const val TAG = "LockAlarmReceiver"
        private const val WAKELOCK_TIMEOUT_MS = 10_000L
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_FIRE) return

        val medId = intent.getStringExtra(EXTRA_MED_ID) ?: ""
        val medName = intent.getStringExtra(EXTRA_MED_NAME) ?: "your medication"
        val hour = intent.getIntExtra(EXTRA_HOUR, -1)
        val minute = intent.getIntExtra(EXTRA_MINUTE, -1)

        // Always reschedule, even when the alarm is switched off — otherwise
        // turning it back on would leave a gap until the next Dart sync.
        if (medId.isNotEmpty() && hour in 0..23 && minute in 0..59) {
            LockAlarmScheduler.rescheduleForNextDay(context, medId, medName, hour, minute)
        }

        if (!AlarmPrefs.isEnabled(context)) {
            Log.i(TAG, "Dose alarm disabled by user — not ringing.")
            return
        }

        Log.i(TAG, "Dose alarm fired for med=$medId name=$medName")

        val wakeLock = acquireWakeLock(context)
        try {
            LockState.setLocked(context, true, medId = medId, medName = medName)

            val show = Intent(context, LockOverlayService::class.java)
                .setAction(LockOverlayService.ACTION_SHOW)
                .putExtra(LockOverlayService.EXTRA_MED_NAME, medName)
            try {
                context.startForegroundService(show)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start LockOverlayService", e)
                LockState.setLocked(context, false)
            }
        } finally {
            // The service holds the device awake from here via its own
            // FLAG_KEEP_SCREEN_ON overlay; this only covers the handoff.
            runCatching { if (wakeLock?.isHeld == true) wakeLock.release() }
        }
    }

    private fun acquireWakeLock(context: Context): PowerManager.WakeLock? = try {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "medbuddy:dose-alarm",
        ).apply { acquire(WAKELOCK_TIMEOUT_MS) }
    } catch (e: Exception) {
        Log.w(TAG, "Could not acquire wake lock", e)
        null
    }
}
