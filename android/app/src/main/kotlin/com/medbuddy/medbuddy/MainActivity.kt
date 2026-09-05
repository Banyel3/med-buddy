package com.medbuddy.medbuddy

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "medbuddy/lock"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // A dose alarm has to reach a phone that is face-down, dark and locked.
        // Without these the activity launches behind the keyguard and the user
        // sees nothing until they happen to pick the phone up. Only while an
        // alarm is live, though — otherwise every launch bypasses the keyguard.
        if (LockState.restore(this)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(
                    android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" ->
                        result.success(isAccessibilityServiceEnabled())
                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(true)
                    }
                    "canDrawOverlays" -> {
                        val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                        result.success(ok)
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                            !Settings.canDrawOverlays(this)
                        ) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    android.net.Uri.parse("package:$packageName"),
                                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                            )
                        }
                        result.success(true)
                    }
                    "scheduleLockAlarm" -> {
                        val medId = call.argument<String>("medId") ?: ""
                        val medName = call.argument<String>("medName") ?: ""
                        val hour = call.argument<Int>("hour") ?: -1
                        val minute = call.argument<Int>("minute") ?: -1
                        if (medId.isEmpty() || hour !in 0..23 || minute !in 0..59) {
                            result.error("ARG", "Bad args for scheduleLockAlarm", null)
                        } else {
                            val triggerAt = LockAlarmScheduler.scheduleForMed(
                                this, medId, medName, hour, minute,
                            )
                            result.success(triggerAt)
                        }
                    }
                    "cancelLockAlarm" -> {
                        val medId = call.argument<String>("medId") ?: ""
                        if (medId.isEmpty()) {
                            result.error("ARG", "medId required", null)
                        } else {
                            LockAlarmScheduler.cancel(this, medId)
                            result.success(true)
                        }
                    }
                    "cancelAllLockAlarms" -> {
                        LockAlarmScheduler.cancelAll(this)
                        result.success(true)
                    }
                    "setAlarmEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AlarmPrefs.setEnabled(this, enabled)
                        result.success(enabled)
                    }
                    "isAlarmEnabled" -> {
                        result.success(AlarmPrefs.isEnabled(this))
                    }
                    "stopAlarm" -> {
                        // Verification succeeded — silence everything now.
                        LockState.setLocked(this, false)
                        startService(
                            Intent(this, LockOverlayService::class.java)
                                .setAction(LockOverlayService.ACTION_HIDE),
                        )
                        result.success(true)
                    }
                    "skipDose" -> {
                        // "I can't take it now" pressed inside the Flutter UI.
                        // Same path as the overlay button so both are logged.
                        startService(
                            Intent(this, LockOverlayService::class.java)
                                .setAction(LockOverlayService.ACTION_SKIP),
                        )
                        result.success(true)
                    }
                    "isLocked" -> {
                        result.success(LockState.restore(this))
                    }
                    "alarmCeilingMinutes" -> {
                        result.success(AlarmPrefs.CEILING_MINUTES)
                    }
                    "drainPendingOutcomes" -> {
                        // Alarms that ended while Dart wasn't running.
                        result.success(PendingOutcomes.drain(this))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val target = ComponentName(this, MedBuddyAccessibility::class.java)
            .flattenToString()
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            if (splitter.next().equals(target, ignoreCase = true)) return true
        }
        return false
    }
}

