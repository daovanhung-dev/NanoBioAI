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
    private var recorder: AudioRecord? = null
    private var thread: Thread? = null

    fun start() {
        if (running.getAndSet(true)) return
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            running.set(false); onFailure("microphone_permission_missing"); return
        }
        val sampleRate = 16_000
        val min = AudioRecord.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (min <= 0) { running.set(false); onFailure("audio_buffer_unavailable"); return }
        try {
            recorder = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, maxOf(min * 2, 4096))
            if (recorder?.state != AudioRecord.STATE_INITIALIZED) { stop(); onFailure("audio_record_init_failed"); return }
            recorder?.startRecording()
            thread = Thread({
                val buffer = ShortArray(2048)
                while (running.get()) {
                    val count = recorder?.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING) ?: -1
                    if (count > 0) onFrame(buffer, count) else if (count < 0) { onFailure("audio_read_failed_$count"); break }
                }
            }, "NanoBioSleepSafetyAudio").apply { isDaemon = true; start() }
        } catch (_: SecurityException) { running.set(false); onFailure("microphone_permission_lost") }
        catch (_: Throwable) { running.set(false); onFailure("audio_capture_failed") }
    }

    fun stop() {
        running.set(false)
        try { recorder?.stop() } catch (_: Throwable) {}
        try { recorder?.release() } catch (_: Throwable) {}
        recorder = null
        thread = null
    }
}
