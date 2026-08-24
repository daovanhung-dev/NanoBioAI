package com.nanobioai.app.sleep_safety

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

/// Experimental non-medical acoustic anomaly detector. It extracts only
/// transient numeric features from in-memory PCM and never writes audio bytes.
class SleepSafetyDetector(
    private var sensitivity: String,
    initialNoiseFloor: Double?,
    private var calibrationSeconds: Int,
) {
    data class FrameResult(
        val relativeEnergy: Double,
        val baselineDelta: Double,
        val peakRatio: Double,
        val zeroCrossingRate: Double,
        val confidence: Double,
        val eventType: String,
    )

    private var noiseFloor = initialNoiseFloor?.takeIf { it > 0.00001 } ?: 0.006
    private var calibrating = initialNoiseFloor == null
    private var calibrationStartedAt = System.currentTimeMillis()
    private var calibrationEnergySum = 0.0
    private var calibrationFrames = 0L
    private var lastProgressSecond = -1
    private var candidateCount = 0
    private var lastCandidateAt = 0L

    fun updateSensitivity(value: String) { sensitivity = value }

    fun startCalibration(seconds: Int = calibrationSeconds) {
        calibrationSeconds = seconds.coerceIn(10, 60)
        calibrating = true
        calibrationStartedAt = System.currentTimeMillis()
        calibrationEnergySum = 0.0
        calibrationFrames = 0
        lastProgressSecond = -1
    }

    fun isCalibrating(): Boolean = calibrating
    fun currentNoiseFloor(): Double = noiseFloor

    fun process(
        samples: ShortArray,
        length: Int,
        now: Long = System.currentTimeMillis(),
    ): FrameResult? {
        if (length <= 0) return null
        var sumSquares = 0.0
        var peak = 0.0
        var zeroCrossings = 0
        var previous = 0.0
        for (i in 0 until length) {
            val normalized = samples[i].toDouble() / Short.MAX_VALUE.toDouble()
            sumSquares += normalized * normalized
            peak = max(peak, abs(normalized))
            if (i > 0 && ((previous < 0 && normalized >= 0) || (previous >= 0 && normalized < 0))) {
                zeroCrossings++
            }
            previous = normalized
        }
        val rms = sqrt(sumSquares / length.toDouble()).coerceAtLeast(0.000001)
        val zeroCrossingRate = zeroCrossings.toDouble() / length.toDouble()

        if (calibrating) {
            calibrationEnergySum += rms
            calibrationFrames++
            val elapsedMs = now - calibrationStartedAt
            val second = (elapsedMs / 1000L).toInt()
            if (second != lastProgressSecond) {
                lastProgressSecond = second
                val progress = (elapsedMs.toDouble() / (calibrationSeconds * 1000.0))
                    .coerceIn(0.0, 1.0)
                SleepSafetyRuntimeStatus.calibrationProgress = progress
                SleepSafetyNativeEventBus.emit("calibrationProgress", mapOf("progress" to progress))
            }
            if (elapsedMs >= calibrationSeconds * 1000L && calibrationFrames > 0) {
                noiseFloor = (calibrationEnergySum / calibrationFrames.toDouble())
                    .coerceAtLeast(0.0005)
                calibrating = false
                SleepSafetyRuntimeStatus.calibrationProgress = 1.0
                SleepSafetyNativeEventBus.emit(
                    "calibrationCompleted",
                    mapOf("noiseFloor" to noiseFloor),
                )
            }
            return null
        }

        val relativeEnergy = rms / noiseFloor.coerceAtLeast(0.0005)
        val baselineDelta = (rms - noiseFloor).coerceAtLeast(0.0)
        val peakRatio = peak / rms.coerceAtLeast(0.0005)
        val energyFloor = when (sensitivity) {
            "low" -> 4.4
            "high" -> 2.5
            else -> 3.2
        }
        if (relativeEnergy < energyFloor) return null

        if (now - lastCandidateAt <= 8_000L) candidateCount++ else candidateCount = 1
        lastCandidateAt = now
        val confidence = (
            relativeEnergy / (energyFloor * 2.0) +
                if (candidateCount >= 3) 0.12 else 0.0
            ).coerceIn(0.0, 0.98)

        // Signal-shape labels are intentionally conservative and non-medical.
        // They are rollout-gated until benchmarked against real device data.
        val eventType = when {
            peakRatio >= 3.6 && peak >= 0.82 -> "strongImpact"
            relativeEnergy >= energyFloor * 1.8 && zeroCrossingRate >= 0.20 -> "abnormalScream"
            relativeEnergy >= energyFloor * 1.45 && zeroCrossingRate >= 0.10 -> "abnormalShout"
            candidateCount >= 3 -> "repeatedSuspiciousPattern"
            relativeEnergy >= energyFloor * 1.25 -> "suddenLoudSound"
            else -> "unknownHighEnergyEvent"
        }
        return FrameResult(
            relativeEnergy,
            baselineDelta,
            peakRatio,
            zeroCrossingRate,
            confidence,
            eventType,
        )
    }
}
