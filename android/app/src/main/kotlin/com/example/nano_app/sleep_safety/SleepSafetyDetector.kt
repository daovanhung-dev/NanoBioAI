package com.nanobioai.app.sleep_safety

import java.util.ArrayDeque
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * On-device, non-medical acoustic safety detector.
 *
 * Only transient numeric features are produced. Raw PCM never leaves the
 * process and is never persisted. A single decision layer lives here so the
 * foreground service does not apply a second confidence/energy gate.
 */
class SleepSafetyDetector(
    private var sensitivity: String,
    initialNoiseFloor: Double?,
    private var calibrationSeconds: Int,
) {
    data class AudioMetrics(
        val signalLevel: Double,
        val peakLevel: Double,
        val relativeEnergy: Double,
        val baselineLevel: Double,
        val rms: Double,
        val peak: Double,
        val phase: String,
    )

    data class FrameResult(
        val relativeEnergy: Double,
        val baselineDelta: Double,
        val peakRatio: Double,
        val zeroCrossingRate: Double,
        val confidence: Double,
        val eventType: String,
        val repetitionCount: Int,
    )

    data class ProcessResult(
        val metrics: AudioMetrics,
        val confirmedEvent: FrameResult? = null,
        val candidateType: String? = null,
    )

    private data class Thresholds(
        val relative: Double,
        val minimumRms: Double,
        val extremeRms: Double,
        val extremePeak: Double,
    )

    private var noiseFloor = initialNoiseFloor?.takeIf { it > 0.00001 } ?: DEFAULT_NOISE_FLOOR
    private var calibrating = initialNoiseFloor == null
    private var calibrationStartedAt = System.currentTimeMillis()
    private val calibrationSamples = mutableListOf<Double>()
    private var lastProgressSecond = -1

    private val rollingRms = ArrayDeque<Double>()
    private var sustainedHighEnergyFrames = 0
    private var burstCount = 0
    private var lastBurstAt = 0L

    fun updateSensitivity(value: String) {
        sensitivity = value
    }

    fun startCalibration(seconds: Int = calibrationSeconds) {
        calibrationSeconds = seconds.coerceIn(10, 60)
        calibrating = true
        calibrationStartedAt = System.currentTimeMillis()
        calibrationSamples.clear()
        rollingRms.clear()
        sustainedHighEnergyFrames = 0
        burstCount = 0
        lastBurstAt = 0L
        lastProgressSecond = -1
        SleepSafetyRuntimeStatus.calibrationProgress = 0.0
    }

    fun isCalibrating(): Boolean = calibrating

    fun currentNoiseFloor(): Double = noiseFloor

    fun process(
        samples: ShortArray,
        length: Int,
        now: Long = System.currentTimeMillis(),
    ): ProcessResult? {
        if (length <= 0) return null

        var sumSquares = 0.0
        var peak = 0.0
        var zeroCrossings = 0
        var previous = 0.0
        for (index in 0 until length) {
            val normalized = samples[index].toDouble() / Short.MAX_VALUE.toDouble()
            sumSquares += normalized * normalized
            peak = max(peak, abs(normalized))
            if (
                index > 0 &&
                ((previous < 0 && normalized >= 0) || (previous >= 0 && normalized < 0))
            ) {
                zeroCrossings++
            }
            previous = normalized
        }

        val rms = sqrt(sumSquares / length.toDouble()).coerceAtLeast(MIN_AMPLITUDE)
        val zeroCrossingRate = zeroCrossings.toDouble() / length.toDouble()
        val baselineForFrame = if (calibrating) provisionalCalibrationFloor() else noiseFloor
        val relativeEnergy = rms / baselineForFrame.coerceAtLeast(MIN_NOISE_FLOOR)
        val baselineDelta = (rms - baselineForFrame).coerceAtLeast(0.0)
        val peakRatio = peak / rms.coerceAtLeast(MIN_NOISE_FLOOR)
        val previousRollingRms = rollingAverage().coerceAtLeast(baselineForFrame)
        val attackRatio = rms / previousRollingRms.coerceAtLeast(MIN_NOISE_FLOOR)
        pushRollingRms(rms)

        if (calibrating) {
            calibrationSamples += rms
            publishCalibrationProgress(now)

            val bypass = calibrationSafetyBypass(
                rms = rms,
                peak = peak,
                relativeEnergy = relativeEnergy,
                zeroCrossingRate = zeroCrossingRate,
                peakRatio = peakRatio,
                attackRatio = attackRatio,
            )

            if (calibrationElapsed(now)) {
                finishCalibration()
            }

            val metrics = metrics(
                rms = rms,
                peak = peak,
                relativeEnergy = relativeEnergy,
                baseline = baselineForFrame,
                phase = if (bypass != null) "candidate" else "calibrating",
            )
            return ProcessResult(
                metrics = metrics,
                confirmedEvent = bypass,
                candidateType = bypass?.eventType,
            )
        }

        val thresholds = thresholds()
        val isHighEnergy =
            relativeEnergy >= thresholds.relative && rms >= thresholds.minimumRms
        sustainedHighEnergyFrames = when {
            isHighEnergy -> (sustainedHighEnergyFrames + 1).coerceAtMost(12)
            else -> (sustainedHighEnergyFrames - 1).coerceAtLeast(0)
        }

        // Room baseline learns only from quiet frames. Candidate/alert frames are
        // deliberately excluded so a scream cannot teach the detector to ignore
        // subsequent loud events.
        if (
            relativeEnergy < 1.65 &&
            peak < 0.42 &&
            rms < thresholds.minimumRms
        ) {
            noiseFloor = (noiseFloor * 0.996 + rms * 0.004)
                .coerceIn(MIN_NOISE_FLOOR, MAX_NOISE_FLOOR)
        }

        val extreme =
            peak >= thresholds.extremePeak ||
            rms >= thresholds.extremeRms ||
            (rms >= thresholds.minimumRms * 1.7 && peak >= thresholds.extremePeak * 0.82)
        val impact =
            peak >= 0.72 &&
            peakRatio >= 3.0 &&
            attackRatio >= 2.0
        val vocalLike = zeroCrossingRate in 0.055..0.36
        val scream =
            vocalLike &&
            sustainedHighEnergyFrames >= 2 &&
            relativeEnergy >= thresholds.relative * 1.15 &&
            rms >= thresholds.minimumRms
        val shout =
            sustainedHighEnergyFrames >= 2 &&
            relativeEnergy >= thresholds.relative &&
            rms >= thresholds.minimumRms
        val sudden =
            extreme ||
            (relativeEnergy >= thresholds.relative * 1.35 && rms >= thresholds.minimumRms) ||
            (
                attackRatio >= 2.35 &&
                relativeEnergy >= thresholds.relative &&
                rms >= thresholds.minimumRms
            )

        val candidateType = when {
            impact -> "strongImpact"
            scream -> "abnormalScream"
            shout -> "abnormalShout"
            sudden -> "suddenLoudSound"
            else -> null
        }

        if (candidateType != null) {
            registerBurst(now)
        } else if (now - lastBurstAt > BURST_WINDOW_MS) {
            burstCount = 0
        }

        val repeated = burstCount >= 3 && now - lastBurstAt <= BURST_WINDOW_MS
        val resolvedType = when {
            impact -> "strongImpact"
            scream -> "abnormalScream"
            repeated -> "repeatedSuspiciousPattern"
            shout -> "abnormalShout"
            sudden -> "suddenLoudSound"
            else -> null
        }

        val confirmed = when {
            resolvedType == null -> false
            impact || extreme -> true
            scream && sustainedHighEnergyFrames >= 2 -> true
            repeated -> true
            shout && (sustainedHighEnergyFrames >= 3 || attackRatio >= 2.0) -> true
            sudden && (
                relativeEnergy >= thresholds.relative * 1.6 ||
                attackRatio >= 2.6
            ) -> true
            else -> false
        }

        val confidence = confidence(
            relativeEnergy = relativeEnergy,
            relativeThreshold = thresholds.relative,
            rms = rms,
            minimumRms = thresholds.minimumRms,
            peak = peak,
            attackRatio = attackRatio,
            sustainedFrames = sustainedHighEnergyFrames,
            extreme = extreme,
        )

        val event = if (confirmed && resolvedType != null) {
            FrameResult(
                relativeEnergy = relativeEnergy,
                baselineDelta = baselineDelta,
                peakRatio = peakRatio,
                zeroCrossingRate = zeroCrossingRate,
                confidence = confidence,
                eventType = resolvedType,
                repetitionCount = max(1, burstCount),
            )
        } else {
            null
        }

        val metricsPhase = when {
            event != null -> "alerting"
            resolvedType != null -> "candidate"
            else -> "monitoring"
        }
        return ProcessResult(
            metrics = metrics(
                rms = rms,
                peak = peak,
                relativeEnergy = relativeEnergy,
                baseline = noiseFloor,
                phase = metricsPhase,
            ),
            confirmedEvent = event,
            candidateType = resolvedType,
        )
    }

    private fun thresholds(): Thresholds = when (sensitivity) {
        "high" -> Thresholds(
            relative = 1.9,
            minimumRms = 0.032,
            extremeRms = 0.12,
            extremePeak = 0.78,
        )
        "low" -> Thresholds(
            relative = 3.1,
            minimumRms = 0.065,
            extremeRms = 0.20,
            extremePeak = 0.92,
        )
        else -> Thresholds(
            relative = 2.35,
            minimumRms = 0.045,
            extremeRms = 0.15,
            extremePeak = 0.86,
        )
    }

    private fun calibrationSafetyBypass(
        rms: Double,
        peak: Double,
        relativeEnergy: Double,
        zeroCrossingRate: Double,
        peakRatio: Double,
        attackRatio: Double,
    ): FrameResult? {
        val thresholds = thresholds()
        val bypass =
            peak >= 0.92 ||
            rms >= max(0.18, thresholds.extremeRms) ||
            (
                rms >= max(0.075, thresholds.minimumRms) &&
                peak >= 0.40 &&
                relativeEnergy >= 4.8
            )
        if (!bypass) return null

        val vocalLike = zeroCrossingRate in 0.055..0.36
        val type = when {
            peakRatio >= 3.2 && peak >= 0.82 -> "strongImpact"
            vocalLike && rms >= 0.10 -> "abnormalScream"
            else -> "suddenLoudSound"
        }
        return FrameResult(
            relativeEnergy = relativeEnergy,
            baselineDelta = (rms - provisionalCalibrationFloor()).coerceAtLeast(0.0),
            peakRatio = peakRatio,
            zeroCrossingRate = zeroCrossingRate,
            confidence = (0.76 + min(0.20, attackRatio / 10.0)).coerceAtMost(0.98),
            eventType = type,
            repetitionCount = 1,
        )
    }

    private fun publishCalibrationProgress(now: Long) {
        val elapsedMs = now - calibrationStartedAt
        val second = (elapsedMs / 1000L).toInt()
        if (second == lastProgressSecond) return
        lastProgressSecond = second
        val progress = (elapsedMs.toDouble() / (calibrationSeconds * 1000.0))
            .coerceIn(0.0, 1.0)
        SleepSafetyRuntimeStatus.calibrationProgress = progress
        SleepSafetyNativeEventBus.emit(
            "calibrationProgress",
            mapOf("progress" to progress),
        )
    }

    private fun calibrationElapsed(now: Long): Boolean =
        now - calibrationStartedAt >= calibrationSeconds * 1000L &&
            calibrationSamples.isNotEmpty()

    private fun finishCalibration() {
        noiseFloor = robustNoiseFloor(calibrationSamples)
        calibrating = false
        SleepSafetyRuntimeStatus.calibrationProgress = 1.0
        SleepSafetyNativeEventBus.emit(
            "calibrationCompleted",
            mapOf("noiseFloor" to noiseFloor),
        )
    }

    private fun provisionalCalibrationFloor(): Double {
        if (calibrationSamples.size < 4) return noiseFloor.coerceAtLeast(DEFAULT_NOISE_FLOOR)
        return robustNoiseFloor(calibrationSamples)
    }

    private fun robustNoiseFloor(values: List<Double>): Double {
        if (values.isEmpty()) return DEFAULT_NOISE_FLOOR
        val sorted = values.sorted()
        val retainedCount = max(1, (sorted.size * 0.85).toInt())
        val retained = sorted.take(retainedCount)
        val middle = retained.size / 2
        val median = if (retained.size % 2 == 0 && retained.size > 1) {
            (retained[middle - 1] + retained[middle]) / 2.0
        } else {
            retained[middle]
        }
        val trimmedMean = retained.average()
        return ((median * 0.7) + (trimmedMean * 0.3))
            .coerceIn(MIN_NOISE_FLOOR, MAX_NOISE_FLOOR)
    }

    private fun registerBurst(now: Long) {
        burstCount = if (now - lastBurstAt <= BURST_WINDOW_MS) {
            (burstCount + 1).coerceAtMost(8)
        } else {
            1
        }
        lastBurstAt = now
    }

    private fun pushRollingRms(value: Double) {
        rollingRms.addLast(value)
        while (rollingRms.size > ROLLING_FRAMES) {
            rollingRms.removeFirst()
        }
    }

    private fun rollingAverage(): Double {
        if (rollingRms.isEmpty()) return noiseFloor
        var sum = 0.0
        for (value in rollingRms) sum += value
        return sum / rollingRms.size.toDouble()
    }

    private fun confidence(
        relativeEnergy: Double,
        relativeThreshold: Double,
        rms: Double,
        minimumRms: Double,
        peak: Double,
        attackRatio: Double,
        sustainedFrames: Int,
        extreme: Boolean,
    ): Double {
        if (extreme) return 0.95
        val relativeScore = (relativeEnergy / (relativeThreshold * 2.0)).coerceIn(0.0, 1.0)
        val levelScore = (rms / (minimumRms * 3.0)).coerceIn(0.0, 1.0)
        val peakScore = (peak / 0.90).coerceIn(0.0, 1.0)
        val attackScore = (attackRatio / 3.0).coerceIn(0.0, 1.0)
        val persistenceScore = (sustainedFrames / 4.0).coerceIn(0.0, 1.0)
        return (
            relativeScore * 0.32 +
                levelScore * 0.22 +
                peakScore * 0.16 +
                attackScore * 0.14 +
                persistenceScore * 0.16
            ).coerceIn(0.0, 0.96)
    }

    private fun metrics(
        rms: Double,
        peak: Double,
        relativeEnergy: Double,
        baseline: Double,
        phase: String,
    ): AudioMetrics = AudioMetrics(
        signalLevel = amplitudeToLevel(rms),
        peakLevel = amplitudeToLevel(peak),
        relativeEnergy = relativeEnergy.coerceIn(0.0, 50.0),
        baselineLevel = amplitudeToLevel(baseline),
        rms = rms,
        peak = peak,
        phase = phase,
    )

    private fun amplitudeToLevel(amplitude: Double): Double {
        val safe = amplitude.coerceAtLeast(MIN_AMPLITUDE)
        val db = 20.0 * ln(safe) / LN_10
        return ((db - METER_FLOOR_DB) / (METER_CEILING_DB - METER_FLOOR_DB))
            .coerceIn(0.0, 1.0)
    }

    companion object {
        private const val MIN_AMPLITUDE = 0.000001
        private const val MIN_NOISE_FLOOR = 0.0005
        private const val MAX_NOISE_FLOOR = 0.12
        private const val DEFAULT_NOISE_FLOOR = 0.006
        private const val ROLLING_FRAMES = 12
        private const val BURST_WINDOW_MS = 2_500L
        private const val METER_FLOOR_DB = -56.0
        private const val METER_CEILING_DB = -4.0
        private val LN_10 = ln(10.0)
    }
}
