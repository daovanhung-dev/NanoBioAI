package com.nanobioai.app.sleep_safety

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.nanobioai.app.R

class SleepSafetyNotificationFactory(private val context: Context) {
    companion object {
        const val MONITOR_CHANNEL = "sleep_safety_monitoring"
        const val ALERT_CHANNEL = "sleep_safety_alerts_v2"
        const val MONITOR_NOTIFICATION_ID = 319001
        const val ALERT_NOTIFICATION_ID = 319002
    }

    private val manager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        manager.createNotificationChannel(
            NotificationChannel(
                MONITOR_CHANNEL,
                "Giám sát giấc ngủ",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Hiển thị khi NanoBio đang dùng micro để giám sát âm thanh."
                setSound(null, null)
                enableVibration(false)
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                ALERT_CHANNEL,
                "Cảnh báo an toàn khi ngủ",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Cảnh báo dai dẳng khi NanoBio nhận thấy âm thanh cần được chú ý."
                setSound(null, null)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 600, 250, 600, 250, 900)
            },
        )
    }

    fun monitoring(): Notification {
        ensureChannels()
        val stop = serviceIntent(SleepSafetyForegroundService.ACTION_STOP)
        return NotificationCompat.Builder(context, MONITOR_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("NanoBio đang giám sát giấc ngủ")
            .setContentText(
                "Micro đang hoạt động. Âm thanh được phân tích trên thiết bị và không được lưu.",
            )
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .addAction(0, "Dừng giám sát", stop)
            .build()
    }

    fun alert(eventId: String, reminder: Boolean = false): Notification {
        ensureChannels()
        val ok = serviceIntent(SleepSafetyForegroundService.ACTION_RESPONSE_OK, eventId)
        val help = serviceIntent(SleepSafetyForegroundService.ACTION_RESPONSE_HELP, eventId)
        return NotificationCompat.Builder(context, ALERT_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Bạn có ổn không?")
            .setContentText(
                if (reminder) {
                    "Nabi vẫn đang chờ bạn xác nhận. Nếu không phản hồi, hệ thống sẽ liên hệ người hỗ trợ."
                } else {
                    "Nabi vừa nhận thấy một âm thanh bất thường cần chú ý."
                },
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .setOngoing(true)
            .setOnlyAlertOnce(false)
            .setVibrate(longArrayOf(0, 600, 250, 600, 250, 900))
            .addAction(0, "Tôi ổn", ok)
            .addAction(0, "Tôi cần hỗ trợ", help)
            .build()
    }

    private fun serviceIntent(action: String, eventId: String? = null): PendingIntent {
        val intent = Intent(context, SleepSafetyForegroundService::class.java).setAction(action)
        if (eventId != null) intent.putExtra("eventId", eventId)
        return PendingIntent.getService(
            context,
            (action + (eventId ?: "")).hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
