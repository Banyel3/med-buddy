package com.medbuddy.medbuddy

/**
 * Shared volatile flag. Set from MainActivity's MethodChannel handler
 * (which Dart drives via accessibility_lock_service.dart). Read by
 * MedBuddyAccessibility on every window event.
 */
object LockState {
    @Volatile var locked: Boolean = false
}
