package com.nanobioai.app.sleep_safety

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import java.util.concurrent.atomic.AtomicBoolean

/**
 * RAM-only PCM capture for Sleep Safety.
 *
 * UNPROCESSED is preferred when the device explicitly supports it so detector
 * features are less affected by automatic gain/noise processing. Unsupported
 * devices fall back safely without changing privacy guarantees.
 */
class SleepSafetyAudioCapture(
    private val context: Context,
    private val onFrame: (ShortArray, Int) -> Unit,
    private val onFailure: (String) -> Unit,
) {
    private val running = AtomicBoolean(false)
    private val failureSignaled = AtomicBoolean(false)
    private var recorder: AudioRecord? = null
    private var thread: Thread? = null

    fun start(): Boolean {
        if (running.getAndSet(true)) return true
        failureSignaled.set(false)

        if (
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            running.set(false)
            signalFailure("microphone_permission_missing")
            return false
        }

        val sampleRate = 16_000
        val minBufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBufferSize <= 0) {
            running.set(false)
            signalFailure("audio_buffer_unavailable")
            return false
        }

        val sources = preferredAudioSources()
        for (source in sources) {
            val started = tryStartRecorder(source, sampleRate, minBufferSize)
            if (started) return true
            if (!running.get()) return false
        }

        running.set(false)
        signalFailure("audio_record_init_failed")
        return false
    }

    private fun tryStartRecorder(
        source: Int,
        sampleRate: Int,
        minBufferSize: Int,
    ): Boolean {
        if (!running.get()) return false
        return try {
            val created = AudioRecord(
                source,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minBufferSize * 2, 4096),
            )
            if (created.state != AudioRecord.STATE_INITIALIZED) {
                try {
                    created.release()
                } catch (_: RuntimeException) {
                    // Try the next source.
                }
                false
            } else {
                recorder = created
                created.startRecording()
                if (created.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                    releaseRecorder()
                    false
                } else {
                    startReaderThread()
                    true
                }
            }
        } catch (_: SecurityException) {
            running.set(false)
            releaseRecorder()
            signalFailure("microphone_permission_lost")
            false
        } catch (_: IllegalArgumentException) {
            releaseRecorder()
            false
        } catch (_: RuntimeException) {
            releaseRecorder()
            false
        }
    }

    private fun preferredAudioSources(): List<Int> {
        val sources = mutableListOf<Int>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && supportsUnprocessedSource()) {
            sources += MediaRecorder.AudioSource.UNPROCESSED
        }
        // VOICE_RECOGNITION commonly applies less aggressive gain control than
        // MIC while still being widely supported. MIC remains the final fallback.
        sources += MediaRecorder.AudioSource.VOICE_RECOGNITION
        sources += MediaRecorder.AudioSource.MIC
        return sources.distinct()
    }

    private fun supportsUnprocessedSource(): Boolean {
        val manager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return false
        return manager.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED)
            ?.equals("true", ignoreCase = true) == true
    }

    private fun startReaderThread() {
        thread = Thread({
            val buffer = ShortArray(2048)
            try {
                while (running.get()) {
                    val activeRecorder = recorder ?: break
                    val count = activeRecorder.read(
                        buffer,
                        0,
                        buffer.size,
                        AudioRecord.READ_BLOCKING,
                    )
                    when {
                        count > 0 -> {
                            try {
                                onFrame(buffer, count)
                            } catch (_: RuntimeException) {
                                running.set(false)
                                signalFailure("audio_processing_failed")
                                break
                            }
                        }
                        count < 0 -> {
                            running.set(false)
                            signalFailure("audio_read_failed_$count")
                            break
                        }
                    }
                }
            } catch (_: SecurityException) {
                running.set(false)
                signalFailure("microphone_permission_lost")
            } catch (_: RuntimeException) {
                running.set(false)
                signalFailure("audio_capture_failed")
            }
        }, "NanoBioSleepSafetyAudio").apply {
            isDaemon = true
            start()
        }
    }

    private fun signalFailure(code: String) {
        if (!failureSignaled.compareAndSet(false, true)) return
        try {
            onFailure(code)
        } catch (_: RuntimeException) {
            // A failed callback must never terminate the audio worker/process.
        }
    }

    fun stop() {
        running.set(false)
        val currentThread = Thread.currentThread()
        val readerThread = thread
        thread = null
        releaseRecorder()
        if (readerThread != null && readerThread !== currentThread) {
            try {
                readerThread.join(250)
            } catch (_: InterruptedException) {
                currentThread.interrupt()
            }
        }
    }

    private fun releaseRecorder() {
        val activeRecorder = recorder
        recorder = null
        try {
            if (activeRecorder?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                activeRecorder.stop()
            }
        } catch (_: RuntimeException) {
            // Best effort.
        }
        try {
            activeRecorder?.release()
        } catch (_: RuntimeException) {
            // Best effort.
        }
    }
}
