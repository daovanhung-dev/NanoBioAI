package com.nanobioai.app

import com.nanobioai.app.BuildConfig
import com.nanobioai.app.sleep_safety.SleepSafetyChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sleepSafetyChannelHandler: SleepSafetyChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

        sleepSafetyChannelHandler = SleepSafetyChannelHandler(
            context = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        sleepSafetyChannelHandler?.dispose()
        sleepSafetyChannelHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private companion object {
        const val runtimeConfigChannel = "com.example.nano_app/runtime_config"
    }
}
