package com.nanobioai.app.sleep_safety

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class SleepSafetyChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : EventChannel.StreamHandler {
    private val control = MethodChannel(
        messenger,
        "com.nanobioai.app/sleep_safety/control",
    )
    private val events = EventChannel(
        messenger,
        "com.nanobioai.app/sleep_safety/events",
    )
    private var sink: EventChannel.EventSink? = null
    private val listener: (Map<String, Any?>) -> Unit = { event ->
        sink?.success(event)
    }

    init {
        events.setStreamHandler(this)
        control.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> safeCommand(result, isStart = true) {
                    start(call.arguments as? Map<*, *>)
                }
                "stopMonitoring" -> safeCommand(result) {
                    if (!SleepSafetyRuntimeStatus.active) return@safeCommand
                    context.startService(
                        serviceIntent(SleepSafetyForegroundService.ACTION_STOP)
                            .putExtra("reason", call.argument<String>("reason") ?: "user"),
                    )
                }
                "startCalibration" -> safeCommand(result) {
                    if (!SleepSafetyRuntimeStatus.active) return@safeCommand
                    context.startService(
                        serviceIntent(SleepSafetyForegroundService.ACTION_CALIBRATE)
                            .putExtra("calibrationSeconds", 30),
                    )
                }
                "updateRuntimeConfig" -> safeCommand(result) {
                    if (!SleepSafetyRuntimeStatus.active) return@safeCommand
                    update(call.arguments as? Map<*, *>)
                }
                "respondToAlert" -> safeCommand(result) {
                    if (!SleepSafetyRuntimeStatus.active) return@safeCommand
                    respond(
                        call.argument<String>("eventId"),
                        call.argument<String>("response"),
                    )
                }
                "getMonitoringStatus" -> result.success(
                    SleepSafetyRuntimeStatus.snapshot(),
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun start(args: Map<*, *>?) {
        val intent = serviceIntent(SleepSafetyForegroundService.ACTION_START)
        args?.forEach { (key, value) ->
            when (value) {
                is String -> intent.putExtra(key.toString(), value)
                is Int -> intent.putExtra(key.toString(), value)
                is Long -> intent.putExtra(key.toString(), value)
                is Double -> intent.putExtra(key.toString(), value)
                is Boolean -> intent.putExtra(key.toString(), value)
                null -> Unit
            }
        }
        ContextCompat.startForegroundService(context, intent)
    }

    private fun update(args: Map<*, *>?) {
        val intent = serviceIntent(SleepSafetyForegroundService.ACTION_UPDATE)
        args?.forEach { (key, value) ->
            when (value) {
                is String -> intent.putExtra(key.toString(), value)
                is Int -> intent.putExtra(key.toString(), value)
                is Boolean -> intent.putExtra(key.toString(), value)
                else -> Unit
            }
        }
        context.startService(intent)
    }

    private fun respond(eventId: String?, response: String?) {
        val action = if (response == "need_help") {
            SleepSafetyForegroundService.ACTION_RESPONSE_HELP
        } else {
            SleepSafetyForegroundService.ACTION_RESPONSE_OK
        }
        context.startService(
            serviceIntent(action).putExtra("eventId", eventId),
        )
    }

    private inline fun safeCommand(
        result: MethodChannel.Result,
        isStart: Boolean = false,
        block: () -> Unit,
    ) {
        try {
            block()
            result.success(null)
        } catch (error: SecurityException) {
            val code = if (
                isStart &&
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.RECORD_AUDIO,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                "microphone_permission_missing"
            } else if (isStart) {
                "microphone_fgs_not_allowed"
            } else {
                "sleep_safety_native_command_failed"
            }
            result.error(code, safeMessage(code), null)
        } catch (error: IllegalArgumentException) {
            val code = if (isStart) {
                "service_not_registered"
            } else {
                "sleep_safety_native_command_failed"
            }
            result.error(code, safeMessage(code), null)
        } catch (error: IllegalStateException) {
            val code = if (isStart) {
                "microphone_fgs_not_allowed"
            } else {
                "sleep_safety_native_command_failed"
            }
            result.error(code, safeMessage(code), null)
        } catch (error: RuntimeException) {
            val code = if (
                isStart &&
                error.javaClass.simpleName == "ForegroundServiceStartNotAllowedException"
            ) {
                "microphone_fgs_not_allowed"
            } else if (isStart) {
                "sleep_safety_native_start_failed"
            } else {
                "sleep_safety_native_command_failed"
            }
            result.error(code, safeMessage(code), null)
        }
    }

    private fun safeMessage(code: String): String = when (code) {
        "microphone_permission_missing" -> "Microphone permission is required."
        "microphone_fgs_not_allowed" -> "Microphone monitoring cannot start now."
        "service_not_registered" -> "Sleep safety service is unavailable."
        else -> "Sleep safety native command failed."
    }

    private fun serviceIntent(action: String) =
        Intent(context, SleepSafetyForegroundService::class.java).setAction(action)

    override fun onListen(
        arguments: Any?,
        eventSink: EventChannel.EventSink?,
    ) {
        sink = eventSink
        SleepSafetyNativeEventBus.addListener(listener)
        sink?.success(
            mapOf("type" to "statusSnapshot") + SleepSafetyRuntimeStatus.snapshot(),
        )
    }

    override fun onCancel(arguments: Any?) {
        SleepSafetyNativeEventBus.removeListener(listener)
        sink = null
    }

    fun dispose() {
        SleepSafetyNativeEventBus.removeListener(listener)
        sink = null
        events.setStreamHandler(null)
        control.setMethodCallHandler(null)
    }
}
