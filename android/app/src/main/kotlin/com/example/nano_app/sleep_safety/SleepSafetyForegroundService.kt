package com.nanobioai.app.sleep_safety

import android.Manifest
import android.app.NotificationManager
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
        const val ACTION_DISMISS_ALERT = "com.nanobioai.app.sleep_safety.DISMISS_ALERT"

        private const val METRICS_EMIT_INTERVAL_MS = 160L
        private const val CANDIDATE_EMIT_INTERVAL_MS = 300L
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var notifications: SleepSafetyNotificationFactory
    private lateinit var alertTone: SleepSafetyAlertTonePlayer
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
    private var lastMetricsEmitAt = 0L
    private var lastCandidateEmitAt = 0L

    override fun onCreate() {
        super.onCreate()
        notifications = SleepSafetyNotificationFactory(this)
        alertTone = SleepSafetyAlertTonePlayer(this)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                ACTION_START -> startMonitoring(intent)
                ACTION_STOP -> stopMonitoring(intent.getStringExtra("reason") ?: "user")
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
                ACTION_DISMISS_ALERT -> dismissAlert(intent.getStringExtra("eventId"))
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
            cooldownSeconds = intent.getIntExtra("cooldownSeconds", 120).coerceIn(30, 900)
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

            SleepSafetyRuntimeStatus.phase = if (detector?.isCalibrating() == true) {
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
                    SleepSafetyNotificationFactory.MONITOR_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
            } else {
                startForeground(
                    SleepSafetyNotificationFactory.MONITOR_NOTIFICATION_ID,
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
                // Best-effort cleanup only.
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
        val activeDetector = detector ?: return
        val output = activeDetector.process(samples, length) ?: return
        val now = System.currentTimeMillis()

        emitAudioMetrics(output.metrics, now)

        if (
            SleepSafetyRuntimeStatus.phase == "calibrating" &&
            !activeDetector.isCalibrating()
        ) {
            SleepSafetyRuntimeStatus.phase = "monitoring"
            SleepSafetyNativeEventBus.emit("monitoringReady")
        }

        if (detectionSuppressed) return

        if (
            output.confirmedEvent == null &&
            output.candidateType != null &&
            now - lastCandidateEmitAt >= CANDIDATE_EMIT_INTERVAL_MS
        ) {
            lastCandidateEmitAt = now
            SleepSafetyNativeEventBus.emit(
                "detectorCandidate",
                mapOf(
                    "eventType" to output.candidateType,
                    "relativeEnergy" to output.metrics.relativeEnergy,
                    "signalLevel" to output.metrics.signalLevel,
                ),
            )
        }

        output.confirmedEvent?.let(::beginAlert)
    }

    private fun emitAudioMetrics(
        metrics: SleepSafetyDetector.AudioMetrics,
        now: Long,
    ) {
        if (now - lastMetricsEmitAt < METRICS_EMIT_INTERVAL_MS) return
        lastMetricsEmitAt = now
        val runtimePhase = when {
            detectionSuppressed -> SleepSafetyRuntimeStatus.phase
            else -> metrics.phase
        }
        SleepSafetyNativeEventBus.emit(
            "audioMetrics",
            mapOf(
                "signalLevel" to metrics.signalLevel,
                "peakLevel" to metrics.peakLevel,
                "relativeEnergy" to metrics.relativeEnergy,
                "baselineLevel" to metrics.baselineLevel,
                "phase" to runtimePhase,
                "capturedAtEpochMs" to now,
            ),
        )
    }

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
            "severity" to if (
                result.relativeEnergy >= 5.0 || result.confidence >= 0.90
            ) "high" else "attention",
            "confidence" to result.confidence,
            "relativeEnergy" to result.relativeEnergy,
            "baselineDelta" to result.baselineDelta,
            "repetitionCount" to result.repetitionCount,
        )
        SleepSafetyRuntimeStatus.currentEvent = eventData
        SleepSafetyNativeEventBus.emit("confirmedSafetyEvent", eventData)
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        alertTone.start()
        manager.notify(
            SleepSafetyNotificationFactory.ALERT_NOTIFICATION_ID,
            notifications.alert(eventId),
        )
        reminderRunnable = Runnable {
            if (currentEventId == eventId) {
                manager.notify(
                    SleepSafetyNotificationFactory.ALERT_NOTIFICATION_ID,
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
        stopPersistentAlert()
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
        SleepSafetyRuntimeStatus.phase = "cooldown"
        handler.postDelayed({
            if (SleepSafetyRuntimeStatus.active) {
                detectionSuppressed = false
                SleepSafetyRuntimeStatus.phase = "monitoring"
                SleepSafetyNativeEventBus.emit("monitoringReady")
            }
        }, cooldownSeconds * 1000L)
    }

    private fun dismissAlert(eventId: String?) {
        val current = currentEventId ?: return
        if (eventId != null && eventId != current) return
        cancelAlertTimers()
        stopPersistentAlert()
        currentEventId = null
        SleepSafetyRuntimeStatus.currentEvent = null
        detectionSuppressed = false
        SleepSafetyRuntimeStatus.phase = "monitoring"
        SleepSafetyNativeEventBus.emit("monitoringReady")
    }

    private fun stopPersistentAlert() {
        alertTone.stop()
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(SleepSafetyNotificationFactory.ALERT_NOTIFICATION_ID)
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
        stopPersistentAlert()
        stopRunnable?.let(handler::removeCallbacks)
        stopRunnable = null
        capture?.stop()
        capture = null
        detector = null
        currentEventId = null
        detectionSuppressed = false
        lastMetricsEmitAt = 0L
        lastCandidateEmitAt = 0L
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
