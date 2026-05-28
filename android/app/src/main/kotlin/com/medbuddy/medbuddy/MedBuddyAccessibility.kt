package com.medbuddy.medbuddy

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Phase 3 — keeps the MedBuddy lock overlay on top whenever
 * `LockState.locked == true`. Strategy:
 *
 *  1. Watch typeWindowStateChanged events.
 *  2. If lock is active and the user moves to any non-MedBuddy / non-overlay
 *     foreground window, bring MedBuddy MainActivity back to the front and
 *     re-show the overlay via LockOverlayService.
 *  3. performGlobalAction(GLOBAL_ACTION_BACK / GLOBAL_ACTION_HOME) presses
 *     are observed as window changes — same handler re-asserts the lock.
 *  4. Emergency dialer ("com.android.server.telecom", "com.android.dialer",
 *     "com.google.android.dialer") and Settings → Accessibility (so the
 *     user can disable the service if needed) are always allowed through.
 *
 * Activated only after the user enables MedBuddy in Settings →
 * Accessibility → MedBuddy.
 */
class MedBuddyAccessibility : AccessibilityService() {

    private val tag = "MedBuddyAccessibility"
    private val handler = Handler(Looper.getMainLooper())

    private val passthroughPackages = setOf(
        "com.android.systemui",
        "com.android.server.telecom",
        "com.android.dialer",
        "com.google.android.dialer",
        "com.android.settings",
        BuildConfigCompat.applicationId,
    )

    companion object {
        @Volatile var instance: MedBuddyAccessibility? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(tag, "Accessibility service connected.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!LockState.locked) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg in passthroughPackages) return

        Log.d(tag, "Lock active, intercepting nav to $pkg")
        bringBackToLock()
    }

    override fun onInterrupt() {
        Log.w(tag, "Accessibility service interrupted.")
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    /** Public hook for LockController.dart to perform a back press. */
    fun assertLock() {
        bringBackToLock()
    }

    private fun bringBackToLock() {
        // Re-show the overlay window (no-op if already visible).
        val overlay = Intent(this, LockOverlayService::class.java)
        overlay.action = LockOverlayService.ACTION_SHOW
        startService(overlay)

        // And bring MedBuddy's MainActivity to front as a safety net.
        handler.postDelayed({
            val launch = packageManager.getLaunchIntentForPackage(packageName)
            if (launch != null) {
                launch.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP,
                )
                startActivity(launch)
            }
        }, 80)
    }
}

/** Tiny shim so we don't have to depend on BuildConfig generation timing. */
private object BuildConfigCompat {
    const val applicationId = "com.medbuddy.medbuddy"
}
