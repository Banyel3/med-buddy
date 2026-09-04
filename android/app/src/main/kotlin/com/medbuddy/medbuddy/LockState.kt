package com.medbuddy.medbuddy

import android.content.Context

/**
 * Whether a dose alarm is currently active.
 *
 * Persisted, not just held in memory: the alarm fires from a BroadcastReceiver
 * that may run in a freshly-spawned process, and Android can kill that process
 * while the alarm is still going. An in-memory flag loses the lock in both
 * cases. [restore] is called on every entry point so a cold process picks the
 * state back up.
 */
object LockState {

    private const val PREFS = "medbuddy_lock_prefs"
    private const val KEY_LOCKED = "locked"
    private const val KEY_MED_ID = "locked_med_id"
    private const val KEY_MED_NAME = "locked_med_name"
    private const val KEY_STARTED_AT = "locked_started_at"

    @Volatile
    private var lockedCache: Boolean = false

    /** Fast path for the accessibility service, which reads this per event. */
    var locked: Boolean
        get() = lockedCache
        set(value) { lockedCache = value }

    fun setLocked(
        context: Context,
        value: Boolean,
        medId: String = "",
        medName: String = "",
    ) {
        lockedCache = value
        val e = prefs(context).edit().putBoolean(KEY_LOCKED, value)
        if (value) {
            e.putString(KEY_MED_ID, medId)
                .putString(KEY_MED_NAME, medName)
                .putLong(KEY_STARTED_AT, System.currentTimeMillis())
        } else {
            e.remove(KEY_MED_ID).remove(KEY_MED_NAME).remove(KEY_STARTED_AT)
        }
        e.apply()
    }

    /** Re-hydrate [locked] from disk. Call from any cold entry point. */
    fun restore(context: Context): Boolean {
        lockedCache = prefs(context).getBoolean(KEY_LOCKED, false)
        return lockedCache
    }

    fun medId(context: Context): String =
        prefs(context).getString(KEY_MED_ID, "") ?: ""

    fun medName(context: Context): String =
        prefs(context).getString(KEY_MED_NAME, "") ?: ""

    /** Milliseconds since the alarm started, or 0 when not locked. */
    fun elapsedMillis(context: Context): Long {
        val startedAt = prefs(context).getLong(KEY_STARTED_AT, 0L)
        if (startedAt == 0L) return 0L
        return (System.currentTimeMillis() - startedAt).coerceAtLeast(0L)
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/**
 * Outcomes of alarms that ended without a verification, waiting to be written
 * to `compliance_logs`.
 *
 * The alarm runs in a process that may have no Flutter engine at all, and it
 * can end (ceiling reached, or the user pressed "I can't take it now") while
 * the app is not running. Rather than trying to wake Dart from a receiver,
 * outcomes are parked here and drained by the Dart layer the next time it
 * runs. If the phone is never opened again that day, `daily-rollover` marks
 * the dose missed anyway — so the worst case is a late `skipped_at`, never a
 * lost dose.
 *
 * Entries are `medId|reason|epochMillis`.
 */
object PendingOutcomes {

    private const val PREFS = "medbuddy_lock_prefs"
    private const val KEY = "pending_outcomes"

    fun add(context: Context, medId: String, reason: String) {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val existing = (p.getStringSet(KEY, emptySet()) ?: emptySet()).toMutableSet()
        existing.add("$medId|$reason|${System.currentTimeMillis()}")
        p.edit().putStringSet(KEY, existing).apply()
    }

    /** Returns everything queued and clears the queue in one step. */
    fun drain(context: Context): List<String> {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val all = (p.getStringSet(KEY, emptySet()) ?: emptySet()).toList()
        if (all.isNotEmpty()) p.edit().remove(KEY).apply()
        return all.sortedBy { it.substringAfterLast('|').toLongOrNull() ?: 0L }
    }
}

/**
 * Whether dose alarms are switched on at all.
 *
 * Replaces the old `LockMode { HARD, SOFT }`. The two lock modes collapsed into
 * one behaviour when the lock became an alarm: it rings, it caps itself at
 * [AlarmPrefs.CEILING_MINUTES], and there is always an escape hatch. "Softness"
 * is no longer a mode, it's the ceiling and the escape button.
 *
 * Persisted in SharedPreferences so the AlarmManager-driven receiver can read
 * it without starting the Flutter VM.
 */
object AlarmPrefs {

    /** How long the alarm may ring before it gives up and marks the dose missed. */
    const val CEILING_MINUTES = 5

    private const val PREFS = "medbuddy_lock_prefs"
    private const val KEY_ENABLED = "alarm_enabled"

    fun setEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ENABLED, enabled)
            .apply()
    }

    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, true)
}
