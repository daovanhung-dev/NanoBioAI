package com.nanobioai.app.nabi_esp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class NabiEspForegroundService : Service() {
    companion object {
        const val ACTION_START = "com.nanobioai.app.nabi_esp.START"
        const val ACTION_STOP = "com.nanobioai.app.nabi_esp.STOP"
        const val ACTION_UPDATE = "com.nanobioai.app.nabi_esp.UPDATE"
        const val EXTRA_TITLE = "title"
        const val EXTRA_MESSAGE = "message"

        private const val CHANNEL_ID = "nabi_esp_assistant"
        private const val NOTIFICATION_ID = 31023
        @Volatile
        var stopRequested: (() -> Unit)? = null
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var title = "Nabi đang chạy"
    private var message = "AI local đang sẵn sàng."

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                try {
                    stopRequested?.invoke()
                } catch (_: RuntimeException) {
                    // The Flutter engine may already be shutting down.
                }
                mainHandler.postDelayed({ stopSelf(startId) }, 2_000L)
            }
            ACTION_UPDATE -> {
                title = intent.getStringExtra(EXTRA_TITLE)?.take(80) ?: title
                message = intent.getStringExtra(EXTRA_MESSAGE)?.take(180) ?: message
                getSystemService(NotificationManager::class.java)
                    .notify(NOTIFICATION_ID, buildNotification())
            }
            else -> startForegroundSafely()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        NabiEspHotspotState.release()
        super.onDestroy()
    }

    private fun startForegroundSafely() {
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: RuntimeException) {
            stopSelf()
        }
    }

    private fun buildNotification(): Notification {
        val stopIntent = Intent(this, NabiEspForegroundService::class.java)
            .setAction(ACTION_STOP)
        val stopPendingIntent = PendingIntent.getService(
            this,
            NOTIFICATION_ID,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setContentTitle(title)
            .setContentText(message)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Dừng Nabi",
                stopPendingIntent,
            )
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Nabi và ESP",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Trạng thái kết nối ESP với AI chạy cục bộ trên điện thoại."
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
