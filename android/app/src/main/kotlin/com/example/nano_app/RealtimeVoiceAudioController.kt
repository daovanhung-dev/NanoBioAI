package com.nanobioai.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Process
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Owns the device audio session used by Gemini Live. PCM is intentionally sent
 * straight to Dart in small chunks: input is 16 kHz mono PCM16 and output is
 * 24 kHz mono PCM16. No audio bytes are stored on disk.
 */
class RealtimeVoiceAudioController(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val methodChannelName = "com.nanobioai.app/realtime_voice_audio"
        private const val inputEventChannelName =
            "com.nanobioai.app/realtime_voice_audio/input_pcm"
        private const val inputSampleRate = 16_000
        private const val outputSampleRate = 24_000
    }

    private val lock = Any()
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val methodChannel = MethodChannel(messenger, methodChannelName)
    private val inputEventChannel = EventChannel(messenger, inputEventChannelName)

    private var inputEvents: EventChannel.EventSink? = null
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var echoCanceler: AcousticEchoCanceler? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var automaticGainControl: AutomaticGainControl? = null
    private var captureThread: Thread? = null
    private var captureActive = false
    private var outputMuted = false
    private var audioFocusRequest: AudioFocusRequest? = null
    private var previousMode = AudioManager.MODE_NORMAL

    init {
        methodChannel.setMethodCallHandler(this)
        inputEventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "prepare" -> {
                    prepare()
                    result.success(null)
                }
                "startCapture" -> {
                    startCapture()
                    result.success(null)
                }
                "pauseCapture" -> {
                    pauseCapture()
                    result.success(null)
                }
                "resumeCapture" -> {
                    startCapture()
                    result.success(null)
                }
                "playPcm" -> {
                    val pcm = call.argument<ByteArray>("pcm")
                        ?: throw IllegalArgumentException("Missing PCM output.")
                    playPcm(pcm)
                    result.success(null)
                }
                "stopPlayback" -> {
                    stopPlayback()
                    result.success(null)
                }
                "setOutputMuted" -> {
                    outputMuted = call.argument<Boolean>("muted") ?: false
                    if (outputMuted) stopPlayback()
                    result.success(null)
                }
                "dispose" -> {
                    dispose()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: VoiceAudioPermissionException) {
            result.error("permission_denied", error.message, null)
        } catch (error: Throwable) {
            result.error("audio_unavailable", error.message, null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        inputEvents = events
    }

    override fun onCancel(arguments: Any?) {
        inputEvents = null
    }

    private fun prepare() = synchronized(lock) {
        ensureMicrophonePermission()
        if (audioRecord != null && audioTrack != null) return

        previousMode = audioManager.mode
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        requestAudioFocus()
        selectCommunicationRoute()

        val inputMinBuffer = AudioRecord.getMinBufferSize(
            inputSampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (inputMinBuffer <= 0) throw IllegalStateException("No supported microphone PCM buffer.")
        val inputBuffer = maxOf(inputMinBuffer * 2, 3_200)
        val record = AudioRecord(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            inputSampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            inputBuffer,
        )
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            throw IllegalStateException("Unable to initialize voice microphone.")
        }
        audioRecord = record
        enableVoiceEffects(record.audioSessionId)

        val outputMinBuffer = AudioTrack.getMinBufferSize(
            outputSampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (outputMinBuffer <= 0) throw IllegalStateException("No supported speaker PCM buffer.")
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(outputSampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .build(),
            )
            .setBufferSizeInBytes(maxOf(outputMinBuffer * 3, 4_800))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
        if (track.state != AudioTrack.STATE_INITIALIZED) {
            track.release()
            throw IllegalStateException("Unable to initialize voice output.")
        }
        audioTrack = track
        track.play()
    }

    private fun startCapture() {
        synchronized(lock) {
            prepare()
            if (captureActive) return
            val record = audioRecord ?: return
            captureActive = true
            record.startRecording()
            captureThread = Thread {
                Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
                val buffer = ByteArray(3_200)
                while (captureActive) {
                    val bytesRead = record.read(buffer, 0, buffer.size)
                    if (bytesRead > 0 && captureActive) {
                        inputEvents?.success(buffer.copyOf(bytesRead))
                    }
                }
            }.apply {
                name = "RealtimeVoiceCapture"
                start()
            }
        }
    }

    private fun pauseCapture() {
        val thread: Thread?
        synchronized(lock) {
            if (!captureActive) return
            captureActive = false
            audioRecord?.takeIf { it.recordingState == AudioRecord.RECORDSTATE_RECORDING }
                ?.stop()
            thread = captureThread
            captureThread = null
        }
        thread?.join(250)
    }

    private fun playPcm(pcm: ByteArray) {
        if (pcm.isEmpty() || outputMuted) return
        val track = synchronized(lock) {
            prepare()
            audioTrack
        } ?: return
        if (track.playState != AudioTrack.PLAYSTATE_PLAYING) track.play()
        @Suppress("DEPRECATION")
        track.write(pcm, 0, pcm.size)
    }

    private fun stopPlayback() = synchronized(lock) {
        val track = audioTrack ?: return
        if (track.playState == AudioTrack.PLAYSTATE_PLAYING) track.pause()
        track.flush()
        if (!outputMuted) track.play()
    }

    fun dispose() {
        pauseCapture()
        synchronized(lock) {
            stopPlayback()
            echoCanceler?.release()
            echoCanceler = null
            noiseSuppressor?.release()
            noiseSuppressor = null
            automaticGainControl?.release()
            automaticGainControl = null
            audioRecord?.release()
            audioRecord = null
            audioTrack?.release()
            audioTrack = null
            abandonAudioFocus()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // A paired Bluetooth device can disappear, or its runtime
                // BLUETOOTH_CONNECT permission can be revoked while a session
                // is active. Releasing the rest of the audio session must not
                // depend on clearing that optional route succeeding.
                try {
                    audioManager.clearCommunicationDevice()
                } catch (_: SecurityException) {
                    // The normal speaker route remains usable without this
                    // permission, and mode/focus still need to be restored.
                }
            } else {
                @Suppress("DEPRECATION")
                run { audioManager.isSpeakerphoneOn = false }
            }
            audioManager.mode = previousMode
            outputMuted = false
        }
    }

    private fun enableVoiceEffects(audioSessionId: Int) {
        if (AcousticEchoCanceler.isAvailable()) {
            echoCanceler = AcousticEchoCanceler.create(audioSessionId)?.apply { enabled = true }
        }
        if (NoiseSuppressor.isAvailable()) {
            noiseSuppressor = NoiseSuppressor.create(audioSessionId)?.apply { enabled = true }
        }
        if (AutomaticGainControl.isAvailable()) {
            automaticGainControl = AutomaticGainControl.create(audioSessionId)?.apply { enabled = true }
        }
    }

    private fun selectCommunicationRoute() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // BLUETOOTH_CONNECT is a runtime permission on Android 12+.
            // Never make it a prerequisite for a voice session: prefer a
            // Bluetooth communication device only when it is available and
            // permitted, otherwise explicitly route to the built-in speaker.
            val devices = try {
                audioManager.availableCommunicationDevices
            } catch (_: SecurityException) {
                emptyList()
            }
            val bluetooth = if (hasBluetoothConnectPermission()) {
                devices.firstOrNull { isBluetoothCommunicationDevice(it) }
            } else {
                null
            }
            val speaker = devices.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            }
            if (!setCommunicationDeviceSafely(bluetooth ?: speaker)) {
                setSpeakerphoneFallback()
            }
        } else {
            setSpeakerphoneFallback()
        }
    }

    private fun hasBluetoothConnectPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                PackageManager.PERMISSION_GRANTED

    private fun isBluetoothCommunicationDevice(device: AudioDeviceInfo): Boolean =
        device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO

    private fun setCommunicationDeviceSafely(device: AudioDeviceInfo?): Boolean {
        if (device == null) return false
        return try {
            audioManager.setCommunicationDevice(device)
        } catch (_: SecurityException) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun setSpeakerphoneFallback() {
        audioManager.isSpeakerphoneOn = true
    }

    private fun requestAudioFocus() {
        val listener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            if (focusChange <= AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) stopPlayback()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE,
            )
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .setOnAudioFocusChangeListener(listener)
                .build()
            audioManager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                listener,
                AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE,
            )
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        }
    }

    private fun ensureMicrophonePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            throw VoiceAudioPermissionException()
        }
    }
}

private class VoiceAudioPermissionException : IllegalStateException(
    "Microphone permission has not been granted.",
)
