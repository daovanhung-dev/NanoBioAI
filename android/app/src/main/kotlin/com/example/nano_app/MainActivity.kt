package com.example.nano_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
    }

    private companion object {
        const val runtimeConfigChannel = "com.example.nano_app/runtime_config"
    }
}
