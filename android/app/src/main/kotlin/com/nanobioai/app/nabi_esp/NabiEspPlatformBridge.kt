package com.nanobioai.app.nabi_esp

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NabiEspPlatformBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val bleProvisioner = NabiEspBleProvisioner(context)

    init {
        channel.setMethodCallHandler(this)
        NabiEspForegroundService.stopRequested = {
            channel.invokeMethod("stopFromNotification", null)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "androidSdkInt" -> result.success(Build.VERSION.SDK_INT)
            "startForegroundService" -> startForegroundService(result)
            "updateForegroundNotification" -> updateForegroundNotification(call, result)
            "stopForegroundService" -> stopForegroundService(result)
            "startLocalOnlyHotspot" -> startLocalOnlyHotspot(result)
            "provisionEsp" -> provisionEsp(call, result)
            "stopLocalOnlyHotspot" -> {
                NabiEspHotspotState.release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        NabiEspForegroundService.stopRequested = null
    }

    private fun startForegroundService(result: MethodChannel.Result) {
        try {
            val intent = Intent(context, NabiEspForegroundService::class.java)
                .setAction(NabiEspForegroundService.ACTION_START)
            ContextCompat.startForegroundService(context, intent)
            result.success(null)
        } catch (_: RuntimeException) {
            result.error("foreground_service_failed", "Could not start Nabi service.", null)
        }
    }

    private fun updateForegroundNotification(call: MethodCall, result: MethodChannel.Result) {
        val title = call.argument<String>("title")?.take(80) ?: "Nabi đang chạy"
        val message = call.argument<String>("message")?.take(180) ?: "AI local đang sẵn sàng."
        try {
            context.startService(
                Intent(context, NabiEspForegroundService::class.java)
                    .setAction(NabiEspForegroundService.ACTION_UPDATE)
                    .putExtra(NabiEspForegroundService.EXTRA_TITLE, title)
                    .putExtra(NabiEspForegroundService.EXTRA_MESSAGE, message),
            )
            result.success(null)
        } catch (_: RuntimeException) {
            result.error("notification_update_failed", "Could not update Nabi status.", null)
        }
    }

    private fun stopForegroundService(result: MethodChannel.Result) {
        try {
            context.stopService(Intent(context, NabiEspForegroundService::class.java))
            NabiEspHotspotState.release()
            result.success(null)
        } catch (_: RuntimeException) {
            result.error("foreground_service_stop_failed", "Could not stop Nabi service.", null)
        }
    }

    private fun provisionEsp(call: MethodCall, result: MethodChannel.Result) {
        val ssid = call.argument<String>("ssid")?.takeIf { it.isNotBlank() }
        val password = call.argument<String>("password")?.takeIf { it.length >= 8 }
        val pairingCode = call.argument<String>("pairingCode")
        if (ssid == null || password == null || ssid.toByteArray().size > 32) {
            result.error("ble_config_invalid", "Hotspot configuration is invalid.", null)
            return
        }
        bleProvisioner.provision(ssid, password, pairingCode, result)
    }

    private fun startLocalOnlyHotspot(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("hotspot_unsupported", "Local-only hotspot requires Android 8.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.CHANGE_WIFI_STATE,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("hotspot_permission", "Wi-Fi state permission is missing.", null)
            return
        }
        val wifiManager = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager
        if (wifiManager == null) {
            result.error("hotspot_unsupported", "Wi-Fi is unavailable.", null)
            return
        }
        try {
            wifiManager.startLocalOnlyHotspot(
                object : WifiManager.LocalOnlyHotspotCallback() {
                    override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                        NabiEspHotspotState.reservation = reservation
                        try {
                            val (ssid, password) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                val configuration = reservation.softApConfiguration
                                configuration.ssid to configuration.passphrase
                            } else {
                                val configuration = reservation.wifiConfiguration
                                configuration?.SSID?.trim('"') to configuration?.preSharedKey?.trim('"')
                            }
                            if (ssid.isNullOrBlank() || password.isNullOrBlank()) {
                                NabiEspHotspotState.release()
                                result.error(
                                    "hotspot_credentials_missing",
                                    "Android did not provide hotspot credentials.",
                                    null,
                                )
                            } else {
                                result.success(mapOf("ssid" to ssid, "password" to password))
                            }
                        } catch (exception: RuntimeException) {
                            logHotspotFailure("read hotspot credentials", exception)
                            NabiEspHotspotState.release()
                            result.error(
                                "hotspot_credentials_missing",
                                "Could not read hotspot credentials.",
                                null,
                            )
                        }
                    }

                    override fun onStopped() {
                        NabiEspHotspotState.reservation = null
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("hotspotStopped", null)
                        }
                    }

                    override fun onFailed(reason: Int) {
                        val code = if (
                            reason == WifiManager.LocalOnlyHotspotCallback.ERROR_INCOMPATIBLE_MODE ||
                            reason == WifiManager.LocalOnlyHotspotCallback.ERROR_TETHERING_DISALLOWED
                        ) "hotspot_busy" else "hotspot_failed"
                        result.error(code, "Android could not start a local hotspot.", null)
                    }
                },
                Handler(Looper.getMainLooper()),
            )
        } catch (exception: SecurityException) {
            logHotspotFailure("start local-only hotspot", exception)
            result.error("hotspot_permission", "Wi-Fi permission was denied.", null)
        } catch (_: IllegalStateException) {
            result.error("hotspot_busy", "Another hotspot request is active.", null)
        } catch (exception: RuntimeException) {
            logHotspotFailure("request local-only hotspot", exception)
            result.error("hotspot_failed", "Android could not start a local hotspot.", null)
        }
    }

    private fun logHotspotFailure(stage: String, exception: RuntimeException) {
        if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            Log.e(TAG, "$stage failed: ${exception.javaClass.simpleName}: ${exception.message}")
        }
    }

    private companion object {
        const val TAG = "NabiEspHotspot"
        const val CHANNEL_NAME = "com.nanobioai.app/nabi_esp"
    }
}

internal object NabiEspHotspotState {
    @Volatile
    var reservation: WifiManager.LocalOnlyHotspotReservation? = null

    @Synchronized
    fun release() {
        val current = reservation
        reservation = null
        try {
            current?.close()
        } catch (_: RuntimeException) {
            // The OS may already have revoked the reservation.
        }
    }
}
