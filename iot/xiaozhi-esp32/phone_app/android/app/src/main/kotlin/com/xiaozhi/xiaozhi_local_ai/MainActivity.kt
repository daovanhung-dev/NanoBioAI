package com.xiaozhi.xiaozhi_local_ai

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var serverChannel: MethodChannel? = null
    private var permissionChannel: MethodChannel? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(ENGINE_ID)?.let { return it }

        return FlutterEngine(context.applicationContext).also { engine ->
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            cache.put(ENGINE_ID, engine)
        }
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val appContext = applicationContext
        serverChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SERVICE_CHANNEL_NAME,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        val intent = Intent(appContext, XiaoZhiServerService::class.java)
                            .setAction(XiaoZhiServerService.ACTION_START)
                        appContext.startForegroundService(intent)
                        result.success(null)
                    }
                    "stopForegroundService" -> {
                        appContext.stopService(
                            Intent(appContext, XiaoZhiServerService::class.java),
                        )
                        result.success(null)
                    }
                    "updateForegroundService" -> {
                        val title = call.argument<String>("title") ?: "Server AI local"
                        val body = call.argument<String>("body") ?: "Đang hoạt động trong mạng nội bộ"
                        XiaoZhiServerService.updateNotification(appContext, title, body)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        permissionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PERMISSION_CHANNEL_NAME,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "requestServerPermissions") {
                    requestServerPermissions(result)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        serverChannel = null
        permissionChannel?.setMethodCallHandler(null)
        permissionChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun requestServerPermissions(result: MethodChannel.Result) {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }
        if (permissions.isEmpty()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_request_active", "A permission request is already active.", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    @Deprecated("Deprecated in Android")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST_CODE) return
        val allGranted = grantResults.isNotEmpty() && grantResults.all {
            it == PackageManager.PERMISSION_GRANTED
        }
        pendingPermissionResult?.success(allGranted)
        pendingPermissionResult = null
    }

    companion object {
        private const val ENGINE_ID = "xiaozhi-local-ai-engine"
        private const val SERVICE_CHANNEL_NAME = "xiaozhi.local_ai/server_service"
        private const val PERMISSION_CHANNEL_NAME = "xiaozhi.local_ai/server_permissions"
        private const val PERMISSION_REQUEST_CODE = 8701
    }
}
