package com.nanobioai.app.sleep_safety

object SleepSafetyNativeEventBus {
    private val listeners = mutableSetOf<(Map<String, Any?>) -> Unit>()
    @Synchronized fun addListener(listener: (Map<String, Any?>) -> Unit) { listeners.add(listener) }
    @Synchronized fun removeListener(listener: (Map<String, Any?>) -> Unit) { listeners.remove(listener) }
    @Synchronized fun emit(type: String, data: Map<String, Any?> = emptyMap()) {
        val event = HashMap<String, Any?>(data)
        event["type"] = type
        listeners.toList().forEach { it(event) }
    }
}

object SleepSafetyRuntimeStatus {
    @Volatile var active: Boolean = false
    @Volatile var sessionId: String? = null
    @Volatile var phase: String = "idle"
    @Volatile var calibrationProgress: Double = 0.0
    @Volatile var currentEvent: Map<String, Any?>? = null

    fun snapshot(): Map<String, Any?> = mapOf(
        "active" to active,
        "sessionId" to sessionId,
        "phase" to phase,
        "calibrationProgress" to calibrationProgress,
        "currentEvent" to currentEvent,
    )
}
