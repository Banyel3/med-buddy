package com.medbuddy.medbuddy

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager

/**
 * Hosts a system-level overlay window that covers all other apps while the
 * lock is active. Uses TYPE_ACCESSIBILITY_OVERLAY when MedBuddyAccessibility
 * is enabled (most aggressive — survives BACK/HOME); falls back to
 * TYPE_APPLICATION_OVERLAY (requires SYSTEM_ALERT_WINDOW permission) when
 * the accessibility service is not yet granted.
 *
 * The overlay itself is a thin Android View — the user lands in MedBuddy's
 * Flutter LockScreen as soon as MedBuddyAccessibility re-fronts the app.
 */
class LockOverlayService : Service() {

    private val tag = "LockOverlayService"
    private var overlay: View? = null
    private var windowManager: WindowManager? = null

    companion object {
        const val ACTION_SHOW = "com.medbuddy.medbuddy.LOCK_SHOW"
        const val ACTION_HIDE = "com.medbuddy.medbuddy.LOCK_HIDE"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> showOverlay()
            ACTION_HIDE -> hideOverlay()
        }
        return START_NOT_STICKY
    }

    private fun showOverlay() {
        if (overlay != null) return
        val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else true

        val accessibilityActive = MedBuddyAccessibility.instance != null
        if (!accessibilityActive && !canDraw) {
            Log.w(tag, "No overlay permission — skipping overlay show.")
            return
        }

        val type = if (accessibilityActive)
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.TOP or Gravity.START

        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE)
                as LayoutInflater
        val view = inflater.inflate(R.layout.lock_overlay, null, false)

        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm.addView(view, params)
            overlay = view
            windowManager = wm
            Log.i(tag, "Overlay shown (type=$type).")
        } catch (e: Exception) {
            Log.e(tag, "addView failed", e)
        }
    }

    private fun hideOverlay() {
        val view = overlay ?: return
        try {
            windowManager?.removeView(view)
        } catch (e: Exception) {
            Log.w(tag, "removeView failed", e)
        }
        overlay = null
        windowManager = null
        Log.i(tag, "Overlay hidden.")
    }

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }
}
