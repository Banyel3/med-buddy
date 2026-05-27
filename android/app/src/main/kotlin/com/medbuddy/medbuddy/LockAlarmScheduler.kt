package com.medbuddy.medbuddy

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import java.util.Calendar

/**
 * Schedules per-medication "auto-lock" alarms via [AlarmManager].
 *
 * For each active medication MedBuddy schedules one exact alarm
 * `medSchedule + 30 minutes` (the same offset the T+30 reminder uses).
 * When it fires, [LockAlarmReceiver] flips [LockState.locked] true and
 * brings the overlay up, even if the app is in the background or killed.
 * If the user verifies their dose before the alarm fires the Dart layer
 * calls [cancel] to unschedule it.
 *
 * Alarm IDs are derived from `medicationId.hashCode()` so reschedules
 * replace cleanly.
 */
object LockAlarmScheduler {

    private const val TAG = "LockAlarmScheduler"
    private const val LOCK_OFFSET_MINUTES = 30
    private const val PREFS = "medbuddy_lock_alarms"
    private const val KEY_ALL_IDS = "active_ids"

    fun scheduleForMed(
        context: Context,
        medicationId: String,
        medicationName: String,
        hour: Int,
        minute: Int,
    ): Long {
        val triggerAt = nextOccurrenceMillis(hour, minute, LOCK_OFFSET_MINUTES)
        val requestCode = requestCodeForMed(medicationId)
        val intent = Intent(context, LockAlarmReceiver::class.java).apply {
            action = LockAlarmReceiver.ACTION_FIRE
            putExtra(LockAlarmReceiver.EXTRA_MED_ID, medicationId)
            putExtra(LockAlarmReceiver.EXTRA_MED_NAME, medicationName)
            putExtra(LockAlarmReceiver.EXTRA_HOUR, hour)
            putExtra(LockAlarmReceiver.EXTRA_MINUTE, minute)
        }
        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
            Log.w(TAG, "Exact alarm permission missing; falling back to inexact.")
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        } else {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }

        rememberAlarm(context, medicationId)
        Log.i(TAG, "Scheduled lock alarm for $medicationId at $triggerAt")
        return triggerAt
    }

    fun cancel(context: Context, medicationId: String) {
        val requestCode = requestCodeForMed(medicationId)
        val intent = Intent(context, LockAlarmReceiver::class.java).apply {
            action = LockAlarmReceiver.ACTION_FIRE
        }
        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pi)
        forgetAlarm(context, medicationId)
        Log.i(TAG, "Cancelled lock alarm for $medicationId")
    }

    fun cancelAll(context: Context) {
        val prefs = prefs(context)
        val ids = prefs.getStringSet(KEY_ALL_IDS, emptySet()) ?: emptySet()
        for (id in ids.toList()) cancel(context, id)
        prefs.edit().remove(KEY_ALL_IDS).apply()
    }

    /** Reschedule the SAME med 24h out — used after the alarm fires. */
    fun rescheduleForNextDay(
        context: Context,
        medicationId: String,
        medicationName: String,
        hour: Int,
        minute: Int,
    ) {
        scheduleForMed(context, medicationId, medicationName, hour, minute)
    }

    private fun nextOccurrenceMillis(hour: Int, minute: Int, offsetMinutes: Int): Long {
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.MINUTE, offsetMinutes)
        }
        if (target.timeInMillis <= now.timeInMillis) {
            target.add(Calendar.DAY_OF_YEAR, 1)
        }
        return target.timeInMillis
    }

    private fun requestCodeForMed(medicationId: String): Int =
        medicationId.hashCode() and 0x7FFFFFFF

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun rememberAlarm(context: Context, medicationId: String) {
        val p = prefs(context)
        val set = (p.getStringSet(KEY_ALL_IDS, emptySet()) ?: emptySet()).toMutableSet()
        set.add(medicationId)
        p.edit().putStringSet(KEY_ALL_IDS, set).apply()
    }

    private fun forgetAlarm(context: Context, medicationId: String) {
        val p = prefs(context)
        val set = (p.getStringSet(KEY_ALL_IDS, emptySet()) ?: emptySet()).toMutableSet()
        set.remove(medicationId)
        p.edit().putStringSet(KEY_ALL_IDS, set).apply()
    }
}
