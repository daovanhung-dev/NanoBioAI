package com.nanobioai.app.sleep_safety

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class SleepSafetyChannelHandler(private val context: Context, messenger: BinaryMessenger) : EventChannel.StreamHandler {
    private val control = MethodChannel(messenger, "com.nanobioai.app/sleep_safety/control")
    private val events = EventChannel(messenger, "com.nanobioai.app/sleep_safety/events")
    private var sink: EventChannel.EventSink? = null
    private val listener: (Map<String, Any?>) -> Unit = { event -> sink?.success(event) }
    init {
        events.setStreamHandler(this)
        control.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> { start(call.arguments as? Map<*, *>); result.success(null) }
                "stopMonitoring" -> { serviceIntent(SleepSafetyForegroundService.ACTION_STOP).putExtra("reason", call.argument<String>("reason") ?: "user").also(context::startService); result.success(null) }
                "startCalibration" -> { context.startService(serviceIntent(SleepSafetyForegroundService.ACTION_CALIBRATE).putExtra("calibrationSeconds", 30)); result.success(null) }
                "updateRuntimeConfig" -> { update(call.arguments as? Map<*, *>); result.success(null) }
                "respondToAlert" -> { respond(call.argument<String>("eventId"), call.argument<String>("response")); result.success(null) }
                "getMonitoringStatus" -> result.success(SleepSafetyRuntimeStatus.snapshot())
                else -> result.notImplemented()
            }
        }
    }
    private fun start(args: Map<*, *>?) {
        val intent = serviceIntent(SleepSafetyForegroundService.ACTION_START)
        args?.forEach { (key, value) ->
            when (value) { is String -> intent.putExtra(key.toString(), value); is Int -> intent.putExtra(key.toString(), value); is Long -> intent.putExtra(key.toString(), value); is Double -> intent.putExtra(key.toString(), value); is Boolean -> intent.putExtra(key.toString(), value); null -> Unit }
        }
        ContextCompat.startForegroundService(context, intent)
    }
    private fun update(args: Map<*, *>?) {
        val intent = serviceIntent(SleepSafetyForegroundService.ACTION_UPDATE)
        args?.forEach { (key, value) -> when (value) { is String -> intent.putExtra(key.toString(), value); is Int -> intent.putExtra(key.toString(), value); is Boolean -> intent.putExtra(key.toString(), value); else -> Unit } }
        context.startService(intent)
    }
    private fun respond(eventId: String?, response: String?) {
        val action = if (response == "need_help") SleepSafetyForegroundService.ACTION_RESPONSE_HELP else SleepSafetyForegroundService.ACTION_RESPONSE_OK
        context.startService(serviceIntent(action).putExtra("eventId", eventId))
    }
    private fun serviceIntent(action: String) = Intent(context, SleepSafetyForegroundService::class.java).setAction(action)
    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) { sink = eventSink; SleepSafetyNativeEventBus.addListener(listener); sink?.success(mapOf("type" to "statusSnapshot") + SleepSafetyRuntimeStatus.snapshot()) }
    override fun onCancel(arguments: Any?) { SleepSafetyNativeEventBus.removeListener(listener); sink = null }
    fun dispose() {
        SleepSafetyNativeEventBus.removeListener(listener)
        sink = null
        events.setStreamHandler(null)
        control.setMethodCallHandler(null)
    }
}
