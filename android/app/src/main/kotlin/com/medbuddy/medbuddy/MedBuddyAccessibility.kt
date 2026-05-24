package com.medbuddy.medbuddy

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Phase 1 stub. Phase 3 implements:
 *  - Window-state listener to detect user leaving MedBuddy during lock period
 *  - GLOBAL_ACTION_BACK / GLOBAL_ACTION_HOME suppression
 *  - Overlay activation via FlutterAccessibilityService
 *
 * Activating this service requires the user to enable it in
 * Settings > Accessibility > MedBuddy.
 */
class MedBuddyAccessibility : AccessibilityService() {

    private val tag = "MedBuddyAccessibility"

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(tag, "Accessibility service connected (Phase 1 stub).")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Phase 3 wires lock enforcement here.
    }

    override fun onInterrupt() {
        Log.w(tag, "Accessibility service interrupted.")
    }
}
