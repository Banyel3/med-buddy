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
 * For each active medication MedBuddy schedules one alarm at
 * `medSchedule + `[ALARM_DELAY_MINUTES]. When it fires, [LockAlarmReceiver]
 * marks the lock active and starts [LockOverlayService], which rings, even if
 * the app is backgrounded or killed. If the user verifies their dose before
 * the alarm fires the Dart layer calls [cancel] to unschedule it.
 *
 * Uses [AlarmManager.setAlarmClock] rather than setExactAndAllowWhileIdle: it
 * is the strongest scheduling guarantee Android offers, it survives Doze, and
 * it is what marks this as a genuine alarm app to the platform — the
 * status-bar alarm icon comes from here.
 *
 * Alarm IDs are derived from `medicationId.hashCode()` so reschedules
 * replace cleanly.
 */
object LockAlarmScheduler {

    private const val TAG = "LockAlarmScheduler"

    /**
     * Minutes after the scheduled dose time before the alarm starts ringing.
     *
     * Not zero on purpose: an alarm at dose time punishes the majority who
     * simply take their pill. Ringing is the escalation, not the opener. Set
     * this to 0 for a true alarm-at-dose-time; nothing else depends on it.
     */
    const val ALARM_DELAY_MINUTES = 15

    private const val PREFS = "medbuddy_lock_alarms"
    private const val KEY_ALL_IDS = "active_ids"

    /** Per-med schedule, `name|hour|minute`, so [rescheduleAll] can re-arm after reboot. */
    private const val KEY_MED_PREFIX = "med_"

    fun scheduleForMed(
        context: Context,
        medicationId: String,
        medicationName: String,
        hour: Int,
        minute: Int,
    ): Long {
        val triggerAt = nextOccurrenceMillis(hour, minute, ALARM_DELAY_MINUTES)
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
            val showIntent = PendingIntent.getActivity(
                context,
                requestCode,
                context.packageManager
                    .getLaunchIntentForPackage(context.packageName) ?: Intent(),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAt, showIntent), pi)
        }

        rememberAlarm(context, medicationId, medicationName, hour, minute)
        Log.i(TAG, "Scheduled lock alarm for $medicationId at $triggerAt")
        return triggerAt
    }

    /**
     * Re-arm every remembered medication. AlarmManager forgets everything on
     * reboot; [BootReceiver] calls this so the dose alarm survives without a
     * trip through Dart.
     */
    fun rescheduleAll(context: Context): Int {
        val p = prefs(context)
        val ids = p.getStringSet(KEY_ALL_IDS, emptySet()) ?: emptySet()
        var count = 0
        for (id in ids.toList()) {
            val raw = p.getString(KEY_MED_PREFIX + id, null) ?: continue
            val parts = raw.split('|')
            if (parts.size != 3) continue
            val hour = parts[1].toIntOrNull() ?: continue
            val minute = parts[2].toIntOrNull() ?: continue
            if (hour !in 0..23 || minute !in 0..59) continue
            scheduleForMed(context, id, parts[0], hour, minute)
            count++
        }
        Log.i(TAG, "Re-armed $count lock alarm(s) after boot.")
        return count
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

    private fun rememberAlarm(
        context: Context,
        medicationId: String,
        medicationName: String,
        hour: Int,
        minute: Int,
    ) {
        val p = prefs(context)
        val set = (p.getStringSet(KEY_ALL_IDS, emptySet()) ?: emptySet()).toMutableSet()
        set.add(medicationId)
        p.edit()
            .putStringSet(KEY_ALL_IDS, set)
            .putString(KEY_MED_PREFIX + medicationId, "${medicationName.replace('|', ' ')}|$hour|$minute")
            .apply()
    }

    private fun forgetAlarm(context: Context, medicationId: String) {
        val p = prefs(context)
        val set = (p.getStringSet(KEY_ALL_IDS, emptySet()) ?: emptySet()).toMutableSet()
        set.remove(medicationId)
        p.edit()
            .putStringSet(KEY_ALL_IDS, set)
            .remove(KEY_MED_PREFIX + medicationId)
            .apply()
    }
}
