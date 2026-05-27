package com.medbuddy.medbuddy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Fires when the AlarmManager-scheduled "T+30 lock" reaches its time.
 * Independent of the Flutter VM — works whether the app is killed,
 * backgrounded, or open. Flips [LockState.locked] and starts the
 * [LockOverlayService] so the overlay covers the foreground app.
 * Re-schedules the same medication for the next day so the lock
 * recurs daily without a Dart trip.
 */
class LockAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_FIRE = "com.medbuddy.medbuddy.ACTION_LOCK_FIRE"
        const val EXTRA_MED_ID = "med_id"
        const val EXTRA_MED_NAME = "med_name"
        const val EXTRA_HOUR = "med_hour"
        const val EXTRA_MINUTE = "med_minute"
        private const val TAG = "LockAlarmReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_FIRE) return

        val medId = intent.getStringExtra(EXTRA_MED_ID) ?: ""
        val medName = intent.getStringExtra(EXTRA_MED_NAME) ?: "your medication"
        val hour = intent.getIntExtra(EXTRA_HOUR, -1)
        val minute = intent.getIntExtra(EXTRA_MINUTE, -1)

        Log.i(TAG, "Lock alarm fired for med=$medId name=$medName")

        LockState.locked = true
        val show = Intent(context, LockOverlayService::class.java)
            .setAction(LockOverlayService.ACTION_SHOW)
        try {
            context.startForegroundService(show)
        } catch (e: Exception) {
            // Pre-O / restricted background — best-effort start.
            try {
                context.startService(show)
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to start LockOverlayService", e2)
            }
        }

        if (medId.isNotEmpty() && hour in 0..23 && minute in 0..59) {
            LockAlarmScheduler.rescheduleForNextDay(
                context,
                medId,
                medName,
                hour,
                minute,
            )
        }
    }
}
