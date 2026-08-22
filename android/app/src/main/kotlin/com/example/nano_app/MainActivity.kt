package com.nanobioai.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.nanobioai.app.BuildConfig

class MainActivity : FlutterActivity() {
    private var realtimeVoiceAudio: RealtimeVoiceAudioController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        realtimeVoiceAudio = RealtimeVoiceAudioController(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            runtimeConfigChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "getPrivateRuntimeConfig") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val values = mutableMapOf<String, String>()
            BuildConfig.GEMINI_API_KEY
                .takeIf { it.isNotBlank() }
                ?.let { values["GEMINI_API_KEY"] = it }
            result.success(values)
        }
    }

    override fun onDestroy() {
        realtimeVoiceAudio?.dispose()
        realtimeVoiceAudio = null
        super.onDestroy()
    }

    override fun onStop() {
        // Do not leave the microphone or an active communication route held
        // while this activity is no longer visible. Flutter also closes the
        // Live session from its lifecycle observer; this makes the native
        // release immediate and safe if that callback is delayed.
        realtimeVoiceAudio?.dispose()
        super.onStop()
    }

    private companion object {
        const val runtimeConfigChannel = "com.example.nano_app/runtime_config"
    }
}
