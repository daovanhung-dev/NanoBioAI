package com.nanobioai.app.sleep_safety

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.core.app.ActivityCompat
import java.util.concurrent.atomic.AtomicBoolean

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

        return try {
            val created = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minBufferSize * 2, 4096),
            )
            recorder = created
            if (created.state != AudioRecord.STATE_INITIALIZED) {
                running.set(false)
                releaseRecorder()
                signalFailure("audio_record_init_failed")
                false
            } else {
                created.startRecording()
                if (created.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                    running.set(false)
                    releaseRecorder()
                    signalFailure("audio_record_start_failed")
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
        } catch (_: RuntimeException) {
            running.set(false)
            releaseRecorder()
            signalFailure("audio_capture_failed")
            false
        }
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
            // The audio worker must never terminate the app process because a
            // failure callback also failed. Native service cleanup is best effort.
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
