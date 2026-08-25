package com.nanobioai.app.sleep_safety

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build

class SleepSafetyAlertTonePlayer(context: Context) {
    private val appContext = context.applicationContext
    private val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val focusListener = AudioManager.OnAudioFocusChangeListener { }
    private var focusRequest: AudioFocusRequest? = null
    private var player: MediaPlayer? = null

    @Synchronized
    fun start() {
        if (player?.isPlaying == true) return
        stop()
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: return
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        requestFocus(attributes)
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(attributes)
                setDataSource(appContext, uri)
                isLooping = true
                setOnErrorListener { _, _, _ ->
                    stop()
                    true
                }
                prepare()
                start()
            }
        } catch (_: RuntimeException) {
            releasePlayer()
            abandonFocus()
        } catch (_: java.io.IOException) {
            releasePlayer()
            abandonFocus()
        }
    }

    @Synchronized
    fun stop() {
        releasePlayer()
        abandonFocus()
    }

    private fun releasePlayer() {
        val active = player ?: return
        player = null
        try {
            if (active.isPlaying) active.stop()
        } catch (_: RuntimeException) {
            // Best-effort release.
        }
        try {
            active.release()
        } catch (_: RuntimeException) {
            // Best-effort release.
        }
    }

    private fun requestFocus(attributes: AudioAttributes) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener(focusListener)
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let(audioManager::abandonAudioFocusRequest)
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
    }
}
