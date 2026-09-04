package com.medbuddy.medbuddy

import android.content.Context
import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * The noise. Plays the device alarm tone on [AudioManager.STREAM_ALARM] and
 * vibrates until [stop] is called.
 *
 * STREAM_ALARM is deliberate: it is the one stream that still sounds when the
 * ringer is muted, which is the whole point — a dose alarm that a silent phone
 * swallows is not an alarm. It does NOT punch through full Do Not Disturb
 * unless the user has allowed alarms in their DND settings, and we don't try
 * to defeat that. DND is an explicit user choice about their own phone.
 *
 * Volume ramps from [START_VOLUME] to full over [RAMP_MILLIS] so the first
 * second is firm rather than hostile — you wake up, you don't get startled.
 *
 * If the user's alarm stream is turned down below [MIN_STREAM_FRACTION] we
 * raise it for the duration and put it back in [stop]. The pre-alarm level is
 * persisted, not just held in memory, so a process death mid-ring can't strand
 * someone's alarm volume at maximum forever.
 */
class AlarmRinger(private val context: Context) {

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var rampStartedAt = 0L
    private var ringing = false

    companion object {
        private const val TAG = "AlarmRinger"

        private const val START_VOLUME = 0.25f
        private const val RAMP_MILLIS = 20_000L
        private const val RAMP_TICK_MILLIS = 250L

        /** Floor we hold the alarm stream at while ringing, as a fraction of max. */
        private const val MIN_STREAM_FRACTION = 0.7

        private const val PREFS = "medbuddy_alarm_ringer"
        private const val KEY_PRIOR_VOLUME = "prior_stream_volume"

        /** 0.9s buzz, 0.6s gap, repeating. Long enough to feel through a pocket. */
        private val VIBRATION_PATTERN = longArrayOf(0, 900, 600)

        /**
         * Linear ramp, clamped to [START_VOLUME]..1.0. Pulled out as a pure
         * function so the curve can be reasoned about without a device.
         */
        fun volumeAt(elapsedMillis: Long): Float {
            if (elapsedMillis <= 0L) return START_VOLUME
            if (elapsedMillis >= RAMP_MILLIS) return 1f
            val progress = elapsedMillis.toFloat() / RAMP_MILLIS
            return START_VOLUME + (1f - START_VOLUME) * progress
        }
    }

    val isRinging: Boolean get() = ringing

    fun start() {
        if (ringing) return
        ringing = true
        raiseStreamVolume()
        startTone()
        startVibration()
        Log.i(TAG, "Ringing.")
    }

    fun stop() {
        if (!ringing && player == null) {
            // Still attempt a volume restore — a previous process may have died
            // mid-ring and left the stream raised.
            restoreStreamVolume()
            return
        }
        ringing = false
        handler.removeCallbacksAndMessages(null)
        runCatching { player?.stop() }
        runCatching { player?.release() }
        player = null
        runCatching { vibrator?.cancel() }
        vibrator = null
        restoreStreamVolume()
        Log.i(TAG, "Stopped.")
    }

    // ---- Tone ------------------------------------------------------------

    private fun startTone() {
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            ?: run {
                Log.w(TAG, "No alarm tone available; vibration only.")
                return
            }

        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        try {
            player = MediaPlayer().apply {
                setAudioAttributes(attrs)
                setDataSource(context, uri)
                isLooping = true
                setVolume(START_VOLUME, START_VOLUME)
                prepare()
                start()
            }
            rampStartedAt = System.currentTimeMillis()
            handler.post(rampTick)
        } catch (e: Exception) {
            Log.e(TAG, "Alarm tone failed to start; vibration only.", e)
            runCatching { player?.release() }
            player = null
        }
    }

    private val rampTick = object : Runnable {
        override fun run() {
            val p = player ?: return
            if (!ringing) return
            val v = volumeAt(System.currentTimeMillis() - rampStartedAt)
            runCatching { p.setVolume(v, v) }
            if (v < 1f) handler.postDelayed(this, RAMP_TICK_MILLIS)
        }
    }

    // ---- Vibration -------------------------------------------------------

    private fun startVibration() {
        val v = resolveVibrator() ?: return
        vibrator = v
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createWaveform(VIBRATION_PATTERN, 0))
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(VIBRATION_PATTERN, 0)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Vibration failed", e)
        }
    }

    private fun resolveVibrator(): Vibrator? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                    as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    } catch (e: Exception) {
        Log.w(TAG, "No vibrator", e)
        null
    }

    // ---- Stream volume ---------------------------------------------------

    private fun prefs(): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun raiseStreamVolume() {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        try {
            val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            val current = am.getStreamVolume(AudioManager.STREAM_ALARM)
            val floor = Math.ceil(max * MIN_STREAM_FRACTION).toInt().coerceIn(1, max)
            if (current >= floor) return

            // Remember where the user had it, so stop() can put it back.
            prefs().edit().putInt(KEY_PRIOR_VOLUME, current).apply()
            am.setStreamVolume(AudioManager.STREAM_ALARM, floor, 0)
            Log.i(TAG, "Raised alarm stream $current -> $floor (max=$max).")
        } catch (e: Exception) {
            // Some OEMs block setStreamVolume under DND. Not fatal — the tone
            // still plays at whatever the user had set.
            Log.w(TAG, "Could not raise alarm stream", e)
        }
    }

    private fun restoreStreamVolume() {
        val p = prefs()
        if (!p.contains(KEY_PRIOR_VOLUME)) return
        val prior = p.getInt(KEY_PRIOR_VOLUME, -1)
        p.edit().remove(KEY_PRIOR_VOLUME).apply()
        if (prior < 0) return
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        runCatching {
            am.setStreamVolume(AudioManager.STREAM_ALARM, prior, 0)
            Log.i(TAG, "Restored alarm stream to $prior.")
        }
    }
}
