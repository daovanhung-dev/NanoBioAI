package com.nanobioai.app.sleep_safety

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
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

    fun alert(
        eventId: String,
        fallbackPhone: String? = null,
    ): Notification {
        ensureChannels()
        val ok = serviceIntent(SleepSafetyForegroundService.ACTION_RESPONSE_OK, eventId)
        val help = serviceIntent(SleepSafetyForegroundService.ACTION_RESPONSE_HELP, eventId)
        return NotificationCompat.Builder(context, ALERT_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Bạn có ổn không?")
            .setContentText("Nabi vừa nhận thấy một âm thanh bất thường cần chú ý.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .setOngoing(true)
            .setOnlyAlertOnce(false)
            .setVibrate(longArrayOf(0, 600, 250, 600, 250, 900))
            .addAction(0, "Tôi ổn", ok)
            .addAction(0, "Tôi cần hỗ trợ", help)
            .apply {
                if (!fallbackPhone.isNullOrBlank() &&
                    fallbackPhone.matches(Regex("^\\+[1-9][0-9]{7,14}$"))) {
                    val dialIntent = Intent(
                        Intent.ACTION_DIAL,
                        Uri.parse("tel:${Uri.encode(fallbackPhone)}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    val dial = PendingIntent.getActivity(
                        context,
                        ("dial" + eventId).hashCode(),
                        dialIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    addAction(0, "Gọi người liên hệ", dial)
                }
            }
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
