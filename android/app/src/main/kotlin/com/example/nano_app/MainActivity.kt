package com.nanobioai.app

import com.nanobioai.app.sleep_safety.SleepSafetyChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var sleepSafetyChannelHandler: SleepSafetyChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
}
