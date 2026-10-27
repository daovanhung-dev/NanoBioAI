package com.nanobioai.app

import com.nanobioai.app.sleep_safety.SleepSafetyChannelHandler
import com.nanobioai.app.nabi_esp.NabiEspPlatformBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var sleepSafetyChannelHandler: SleepSafetyChannelHandler? = null
    private var nabiEspPlatformBridge: NabiEspPlatformBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sleepSafetyChannelHandler = SleepSafetyChannelHandler(
            context = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        nabiEspPlatformBridge = NabiEspPlatformBridge(
            context = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        sleepSafetyChannelHandler?.dispose()
        sleepSafetyChannelHandler = null
        nabiEspPlatformBridge?.dispose()
        nabiEspPlatformBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
