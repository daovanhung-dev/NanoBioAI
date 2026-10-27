package com.xiaozhi.xiaozhi_local_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class XiaoZhiServerService : Service() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var cpuWakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> requestStopFromFlutter()
            ACTION_START, null -> {
                if (cpuWakeLock?.isHeld != true) {
                    val powerManager = getSystemService(PowerManager::class.java)
                    cpuWakeLock = powerManager.newWakeLock(
                        PowerManager.PARTIAL_WAKE_LOCK,
                        "XiaoZhiLocalAi:Server",
                    ).apply { acquire() }
                }
                val notification = buildNotification(
                    this,
                    "Server AI local đang khởi chạy",
                    "Kết nối nội bộ · Chạm Dừng server để kết thúc",
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            }
            else -> stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    private fun requestStopFromFlutter() {
        val engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (engine == null) {
            stopSelf()
            return
        }
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.invokeMethod(
            "stopServerFromNotification",
            null,
            object : MethodChannel.Result {
                override fun success(result: Any?) = Unit

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    stopSelf()
                }

                override fun notImplemented() {
                    stopSelf()
                }
            },
        )
        mainHandler.postDelayed({ stopSelf() }, STOP_REQUEST_TIMEOUT_MS)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        cpuWakeLock?.let { if (it.isHeld) it.release() }
        cpuWakeLock = null
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "com.xiaozhi.xiaozhi_local_ai.SERVER_START"
        const val ACTION_STOP = "com.xiaozhi.xiaozhi_local_ai.SERVER_STOP"

        private const val ENGINE_ID = "xiaozhi-local-ai-engine"
        private const val CHANNEL_NAME = "xiaozhi.local_ai/server_service"
        private const val NOTIFICATION_CHANNEL_ID = "xiaozhi_local_ai_server"
        private const val NOTIFICATION_ID = 8765
        private const val STOP_REQUEST_TIMEOUT_MS = 5000L

        fun updateNotification(context: Context, title: String, body: String) {
            createNotificationChannel(context)
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, buildNotification(context, title, body))
        }

        private fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "XiaoZhi local server",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Trạng thái server AI nội bộ cho ESP"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        private fun buildNotification(context: Context, title: String, body: String): Notification {
            val stopIntent = PendingIntent.getService(
                context,
                0,
                Intent(context, XiaoZhiServerService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val openIntent = PendingIntent.getActivity(
                context,
                1,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            return Notification.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_upload_done)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setContentIntent(openIntent)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .addAction(
                    Notification.Action.Builder(
                        android.R.drawable.ic_media_pause,
                        "Dừng server",
                        stopIntent,
                    ).build(),
                )
                .build()
        }
    }
}
