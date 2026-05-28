package com.medbuddy.medbuddy

import android.content.Context

/**
 * Shared volatile flag. Set from MainActivity's MethodChannel handler
 * (which Dart drives via accessibility_lock_service.dart). Read by
 * MedBuddyAccessibility on every window event.
 */
object LockState {
    @Volatile var locked: Boolean = false
}

/**
 * Lock-mode preference. Persisted in SharedPreferences so the native
 * overlay can read it without bouncing through Flutter.
 *
 * - HARD: original behavior. BACK / HOME bounce back; only verification
 *   releases the lock.
 * - SOFT: a "Skip for now" button appears on the overlay. User must tap
 *   it five times in a row to release. Annoying enough to discourage
 *   skipping while still recoverable. Verification flow (writeLog API)
 *   is unchanged: dismissing via the skip button leaves the dose pending
 *   and daily-rollover marks it missed at end of day, same as if the
 *   lock had never fired.
 */
enum class LockMode { HARD, SOFT }

object LockModePrefs {
    private const val PREFS = "medbuddy_lock_prefs"
    private const val KEY = "lock_mode"

    fun set(context: Context, mode: LockMode) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY, mode.name)
            .apply()
    }

    fun get(context: Context): LockMode {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, LockMode.HARD.name) ?: LockMode.HARD.name
        return runCatching { LockMode.valueOf(raw) }.getOrDefault(LockMode.HARD)
    }
}
