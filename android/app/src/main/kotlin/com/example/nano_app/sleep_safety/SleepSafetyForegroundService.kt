package com.nanobioai.app.sleep_safety

import android.Manifest
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.ActivityCompat
import java.time.Instant
import java.util.UUID

class SleepSafetyForegroundService : Service() {
    companion object {
        const val ACTION_START = "com.nanobioai.app.sleep_safety.START"
        const val ACTION_STOP = "com.nanobioai.app.sleep_safety.STOP"
        const val ACTION_CALIBRATE = "com.nanobioai.app.sleep_safety.CALIBRATE"
        const val ACTION_UPDATE = "com.nanobioai.app.sleep_safety.UPDATE"
        const val ACTION_RESPONSE_OK = "com.nanobioai.app.sleep_safety.RESPONSE_OK"
        const val ACTION_RESPONSE_HELP = "com.nanobioai.app.sleep_safety.RESPONSE_HELP"
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var notifications: SleepSafetyNotificationFactory
    private var capture: SleepSafetyAudioCapture? = null
    private var detector: SleepSafetyDetector? = null
    private var currentEventId: String? = null
    private var detectionSuppressed = false
    private var cooldownSeconds = 120
    private var scheduledEndEpochMs: Long? = null
    private var reminderRunnable: Runnable? = null
    private var escalationRunnable: Runnable? = null
    private var stopRunnable: Runnable? = null
    private var currentSensitivity: String = "balanced"
    private var starting = false
    private var foregroundStarted = false

    override fun onCreate() {
        super.onCreate()
        notifications = SleepSafetyNotificationFactory(this)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                ACTION_START -> startMonitoring(intent)
                ACTION_STOP -> stopMonitoring(
                    intent.getStringExtra("reason") ?: "user",
                )
                ACTION_CALIBRATE -> detector?.startCalibration(
                    intent.getIntExtra("calibrationSeconds", 30),
                )
                ACTION_UPDATE -> updateConfig(intent)
                ACTION_RESPONSE_OK -> handleResponse(
                    intent.getStringExtra("eventId"),
                    "ok",
                )
                ACTION_RESPONSE_HELP -> handleResponse(
                    intent.getStringExtra("eventId"),
                    "need_help",
                )
            }
        } catch (error: RuntimeException) {
            val code = classifyStartFailure(error)
            SleepSafetyNativeEventBus.emit("nativeFailure", mapOf("code" to code))
            if (SleepSafetyRuntimeStatus.active || foregroundStarted) {
                stopMonitoring(code)
            } else {
                resetRuntimeStatus()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startMonitoring(intent: Intent) {
        if (SleepSafetyRuntimeStatus.active || starting) return
        starting = true
        try {
            if (
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.RECORD_AUDIO,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                SleepSafetyNativeEventBus.emit(
                    "permissionLost",
                    mapOf("code" to "microphone_permission_missing"),
                )
                resetRuntimeStatus()
                stopSelf()
                return
            }

            SleepSafetyRuntimeStatus.sessionId = intent.getStringExtra("sessionId")
            SleepSafetyRuntimeStatus.phase = "arming"
            cooldownSeconds = intent.getIntExtra(
                "cooldownSeconds",
                120,
            ).coerceIn(30, 900)
            currentSensitivity = intent.getStringExtra("sensitivity") ?: "balanced"
            scheduledEndEpochMs = intent.getLongExtra(
                "scheduledEndEpochMs",
                -1L,
            ).takeIf { it > 0 }
            detector = SleepSafetyDetector(
                sensitivity = currentSensitivity,
                initialNoiseFloor = intent.getDoubleExtra(
                    "calibrationNoiseFloor",
                    -1.0,
                ).takeIf { it > 0 },
                calibrationSeconds = intent.getIntExtra(
                    "calibrationSeconds",
                    30,
                ).coerceIn(10, 60),
            )

            if (!promoteToForegroundSafely()) return

            SleepSafetyRuntimeStatus.active = true
            val audioCapture = SleepSafetyAudioCapture(
                this,
                ::onAudioFrame,
                ::onCaptureFailure,
            )
            capture = audioCapture
            if (!audioCapture.start()) return
            if (!SleepSafetyRuntimeStatus.active) return

            SleepSafetyRuntimeStatus.phase = if (
                detector?.isCalibrating() == true
            ) {
                "calibrating"
            } else {
                "monitoring"
            }
            SleepSafetyNativeEventBus.emit("serviceStarted")
            if (detector?.isCalibrating() != true) {
                SleepSafetyNativeEventBus.emit("monitoringReady")
            }
            scheduleAutoStop()
        } catch (error: RuntimeException) {
            failNativeStart(classifyStartFailure(error))
        } finally {
            starting = false
        }
    }

    private fun promoteToForegroundSafely(): Boolean {
        return try {
            val notification = notifications.monitoring()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    SleepSafetyNotificationFactory.NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
            } else {
                startForeground(
                    SleepSafetyNotificationFactory.NOTIFICATION_ID,
                    notification,
                )
            }
            foregroundStarted = true
            true
        } catch (error: SecurityException) {
            failNativeStart(classifyStartFailure(error))
            false
        } catch (error: IllegalArgumentException) {
            failNativeStart("service_not_registered")
            false
        } catch (error: IllegalStateException) {
            failNativeStart("microphone_fgs_not_allowed")
            false
        } catch (error: RuntimeException) {
            failNativeStart(classifyStartFailure(error))
            false
        }
    }

    private fun failNativeStart(code: String) {
        cleanupRuntimeResources()
        resetRuntimeStatus()
        SleepSafetyNativeEventBus.emit("nativeFailure", mapOf("code" to code))
        if (foregroundStarted) {
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } catch (_: RuntimeException) {
                // Best-effort cleanup only. Never crash while handling a start failure.
            }
            foregroundStarted = false
        }
        stopSelf()
    }

    private fun classifyStartFailure(error: RuntimeException): String {
        if (
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return "microphone_permission_missing"
        }
        if (error is SecurityException) return "microphone_fgs_not_allowed"
        if (error is IllegalArgumentException) return "service_not_registered"
        if (error is IllegalStateException) return "microphone_fgs_not_allowed"
        if (error.javaClass.simpleName == "ForegroundServiceStartNotAllowedException") {
            return "microphone_fgs_not_allowed"
        }
        return "sleep_safety_native_start_failed"
    }

    private fun onAudioFrame(samples: ShortArray, length: Int) {
        if (detectionSuppressed) return
        val result = detector?.process(samples, length) ?: return
        val energyFloor = when (intentSensitivity()) {
            "low" -> 4.4
            "high" -> 2.5
            else -> 3.2
        }
        val confidenceFloor = when (intentSensitivity()) {
            "low" -> 0.78
            "high" -> 0.58
            else -> 0.66
        }
        if (
            result.relativeEnergy < energyFloor ||
            result.confidence < confidenceFloor
        ) {
            return
        }
        beginAlert(result)
    }

    private fun intentSensitivity(): String = currentSensitivity

    private fun beginAlert(result: SleepSafetyDetector.FrameResult) {
        if (currentEventId != null) return
        val eventId = UUID.randomUUID().toString()
        currentEventId = eventId
        detectionSuppressed = true
        SleepSafetyRuntimeStatus.phase = "alerting"
        val now = Instant.now().toString()
        val eventData = mapOf<String, Any?>(
            "eventId" to eventId,
            "detectedAt" to now,
            "eventType" to result.eventType,
            "severity" to if (result.relativeEnergy >= 6.0) "high" else "attention",
            "confidence" to result.confidence,
            "relativeEnergy" to result.relativeEnergy,
            "baselineDelta" to result.baselineDelta,
            "repetitionCount" to 1,
        )
        SleepSafetyRuntimeStatus.currentEvent = eventData
        SleepSafetyNativeEventBus.emit("confirmedSafetyEvent", eventData)
        val manager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        manager.notify(
            SleepSafetyNotificationFactory.NOTIFICATION_ID,
            notifications.alert(eventId),
        )
        reminderRunnable = Runnable {
            if (currentEventId == eventId) {
                manager.notify(
                    SleepSafetyNotificationFactory.NOTIFICATION_ID,
                    notifications.alert(eventId, true),
                )
                SleepSafetyNativeEventBus.emit(
                    "alertReminder",
                    mapOf("eventId" to eventId),
                )
            }
        }.also { handler.postDelayed(it, 30_000L) }
        escalationRunnable = Runnable {
            if (currentEventId == eventId) {
                SleepSafetyRuntimeStatus.phase = "escalating"
                SleepSafetyNativeEventBus.emit(
                    "escalationRequired",
                    mapOf("eventId" to eventId),
                )
            }
        }.also { handler.postDelayed(it, 60_000L) }
    }

    private fun handleResponse(eventId: String?, response: String) {
        val current = currentEventId ?: return
        if (eventId != null && eventId != current) return
        cancelAlertTimers()
        SleepSafetyRuntimeStatus.currentEvent =
            SleepSafetyRuntimeStatus.currentEvent?.toMutableMap()?.apply {
                this["response"] = response
            }
        SleepSafetyNativeEventBus.emit(
            "userResponse",
            mapOf("eventId" to current, "response" to response),
        )
        if (response == "need_help") {
            SleepSafetyRuntimeStatus.phase = "escalating"
            SleepSafetyNativeEventBus.emit(
                "escalationRequired",
                mapOf("eventId" to current),
            )
            return
        }
        currentEventId = null
        SleepSafetyRuntimeStatus.currentEvent = null
        handler.postDelayed({
            if (SleepSafetyRuntimeStatus.active) {
                detectionSuppressed = false
                SleepSafetyRuntimeStatus.phase = "monitoring"
                val manager =
                    getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
                manager.notify(
                    SleepSafetyNotificationFactory.NOTIFICATION_ID,
                    notifications.monitoring(),
                )
            }
        }, cooldownSeconds * 1000L)
    }

    private fun updateConfig(intent: Intent) {
        intent.getStringExtra("sensitivity")?.let {
            currentSensitivity = it
            detector?.updateSensitivity(it)
        }
        if (intent.hasExtra("cooldownSeconds")) {
            cooldownSeconds = intent.getIntExtra(
                "cooldownSeconds",
                cooldownSeconds,
            ).coerceIn(30, 900)
        }
    }

    private fun scheduleAutoStop() {
        stopRunnable?.let(handler::removeCallbacks)
        val end = scheduledEndEpochMs ?: return
        val delay = end - System.currentTimeMillis()
        if (delay <= 0) return
        stopRunnable = Runnable {
            stopMonitoring("schedule_end")
        }.also { handler.postDelayed(it, delay) }
    }

    private fun onCaptureFailure(code: String) {
        if (!SleepSafetyRuntimeStatus.active && !foregroundStarted) return
        SleepSafetyNativeEventBus.emit(
            if (code.contains("permission")) "permissionLost" else "nativeFailure",
            mapOf("code" to code),
        )
        stopMonitoring(code)
    }

    private fun cancelAlertTimers() {
        reminderRunnable?.let(handler::removeCallbacks)
        escalationRunnable?.let(handler::removeCallbacks)
        reminderRunnable = null
        escalationRunnable = null
    }

    private fun cleanupRuntimeResources() {
        cancelAlertTimers()
        stopRunnable?.let(handler::removeCallbacks)
        stopRunnable = null
        capture?.stop()
        capture = null
        detector = null
        currentEventId = null
        detectionSuppressed = false
    }

    private fun resetRuntimeStatus() {
        SleepSafetyRuntimeStatus.active = false
        SleepSafetyRuntimeStatus.phase = "idle"
        SleepSafetyRuntimeStatus.sessionId = null
        SleepSafetyRuntimeStatus.currentEvent = null
        SleepSafetyRuntimeStatus.calibrationProgress = 0.0
    }

    private fun stopMonitoring(reason: String) {
        val hadRuntime = SleepSafetyRuntimeStatus.active || foregroundStarted
        cleanupRuntimeResources()
        resetRuntimeStatus()
        if (hadRuntime) {
            SleepSafetyNativeEventBus.emit(
                "serviceStopped",
                mapOf("reason" to reason),
            )
        }
        if (foregroundStarted) {
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } catch (_: RuntimeException) {
                // Cleanup must remain fail-safe.
            }
            foregroundStarted = false
        }
        stopSelf()
    }

    override fun onDestroy() {
        val wasActive = SleepSafetyRuntimeStatus.active || foregroundStarted
        cleanupRuntimeResources()
        resetRuntimeStatus()
        if (foregroundStarted) {
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } catch (_: RuntimeException) {
                // Cleanup must remain fail-safe.
            }
            foregroundStarted = false
        }
        if (wasActive) {
            SleepSafetyNativeEventBus.emit(
                "serviceStopped",
                mapOf("reason" to "service_destroyed"),
            )
        }
        super.onDestroy()
    }
}
