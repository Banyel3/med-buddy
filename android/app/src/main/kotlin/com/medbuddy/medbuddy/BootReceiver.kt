package com.medbuddy.medbuddy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * AlarmManager drops every alarm on reboot. Re-arm the native dose alarms from
 * the schedule [LockAlarmScheduler] persisted, so the phone still rings on a
 * day the user never opens the app. Also runs after an app update, which
 * clears alarms on some OEMs.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            -> {
                Log.i("BootReceiver", "${intent.action}: re-arming dose alarms")
                LockAlarmScheduler.rescheduleAll(context)
            }
        }
    }
}
