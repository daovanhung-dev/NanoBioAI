package com.nanobioai.app.nabi_esp

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.core.content.ContextCompat
import com.espressif.provisioning.DeviceConnectionEvent
import com.espressif.provisioning.ESPConstants
import com.espressif.provisioning.ESPDevice
import com.espressif.provisioning.ESPProvisionManager
import com.espressif.provisioning.listeners.BleScanListener
import com.espressif.provisioning.listeners.ResponseListener
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

/** Owns the one-device BLE Security 2 provisioning exchange for Nabi. */
internal class NabiEspBleProvisioner(context: Context) {
    private val appContext = context.applicationContext
    private val pairingStore = NabiEspPairingStore(appContext)
    private val executor = Executors.newSingleThreadExecutor()

    fun provision(
        ssid: String,
        password: String,
        pairingCode: String?,
        result: io.flutter.plugin.common.MethodChannel.Result,
    ) {
        // Espressif's manager creates a default Handler, so initialize it on
        // the MethodChannel main thread before moving blocking work off-thread.
        val manager = try {
            ESPProvisionManager.getInstance(appContext)
        } catch (exception: Exception) {
            Log.w(TAG, "BLE manager setup exception: ${exception.javaClass.simpleName}")
            postError(result, "ble_provision_failed")
            return
        }
        executor.execute {
            try {
                checkBluetoothPermissions()
                val found = findEsp(manager)
                val storedKey = pairingStore.get(found.device.address)
                if (storedKey == null && pairingCode.isNullOrBlank()) {
                    postSuccess(result, mapOf("status" to "pairing_required"))
                    return@execute
                }
                if (storedKey == null && !pairingCode!!.matches(Regex("^[0-9]{8}$"))) {
                    throw NabiEspBleFailure("pairing_failed")
                }

                val secret = storedKey ?: pairingCode!!
                val device = manager.createESPDevice(
                    ESPConstants.TransportType.TRANSPORT_BLE,
                    ESPConstants.SecurityType.SECURITY_2,
                )
                device.setUserName(NabiEspGeneratedContract.bleSecurityUsername)
                device.setProofOfPossession(secret)

                val events = NabiEspConnectionEvents()
                EventBus.getDefault().register(events)
                try {
                    device.connectBLEDevice(found.device, found.serviceUuid)
                    if (!events.done.await(18, TimeUnit.SECONDS)) {
                        throw NabiEspBleFailure("esp_connection_timeout")
                    }
                    if (events.failure.get()) {
                        throw NabiEspBleFailure("pairing_failed")
                    }
                    val config = JSONObject()
                        .put("contract_version", NabiEspGeneratedContract.contractVersion)
                        .put("protocol_version", NabiEspGeneratedContract.protocolVersion)
                        .put("port", NabiEspGeneratedContract.port)
                        .put("ota_path", NabiEspGeneratedContract.otaPath)
                        .put("websocket_path", NabiEspGeneratedContract.websocketPath)
                        .put("ssid", ssid)
                        .put("password", password)
                    val response = sendConfig(device, config.toString().toByteArray(StandardCharsets.UTF_8))
                    val body = JSONObject(String(response, StandardCharsets.UTF_8))
                    if (body.optBoolean("ok") != true) {
                        throw NabiEspBleFailure(
                            if (body.optString("reason") == "pairing_expired") {
                                "pairing_failed"
                            } else {
                                "ble_provision_failed"
                            },
                        )
                    }
                    val deviceKey = body.optString("pairing_key").ifBlank { storedKey.orEmpty() }
                    if (!deviceKey.matches(Regex("^[0-9a-fA-F]{64}$"))) {
                        throw NabiEspBleFailure("pairing_key_missing")
                    }
                    if (storedKey == null) pairingStore.put(found.device.address, deviceKey)
                    postSuccess(
                        result,
                        mapOf("status" to "provisioned", "deviceKey" to deviceKey),
                    )
                } finally {
                    EventBus.getDefault().unregister(events)
                    device.disconnectDevice()
                }
            } catch (failure: NabiEspBleFailure) {
                Log.w(TAG, "BLE provisioning failed: ${failure.code}")
                postError(result, failure.code)
            } catch (_: SecurityException) {
                Log.w(TAG, "BLE provisioning requires a permission")
                postError(result, "ble_permission")
            } catch (exception: Exception) {
                val scanCode = Regex("error code:\\s*(\\d+)", RegexOption.IGNORE_CASE)
                    .find(exception.message.orEmpty())
                    ?.groupValues
                    ?.getOrNull(1)
                    ?: "none"
                val source = exception.stackTrace.firstOrNull()
                    ?.let { "${it.className}.${it.methodName}" }
                    ?: "unknown"
                Log.w(
                    TAG,
                    "BLE provisioning exception ${exception.javaClass.simpleName}; source=$source; scanCode=$scanCode",
                )
                postError(result, "ble_provision_failed")
            }
        }
    }

    private fun checkBluetoothPermissions() {
        if (!appContext.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            throw NabiEspBleFailure("ble_unsupported")
        }
        val bluetoothManager = appContext.getSystemService(Context.BLUETOOTH_SERVICE)
            as? android.bluetooth.BluetoothManager ?: throw NabiEspBleFailure("ble_unsupported")
        if (bluetoothManager.adapter?.isEnabled != true) {
            throw NabiEspBleFailure("bluetooth_disabled")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            (ContextCompat.checkSelfPermission(appContext, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(appContext, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED)
        ) {
            throw NabiEspBleFailure("ble_permission")
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S &&
            ContextCompat.checkSelfPermission(appContext, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
        ) {
            throw NabiEspBleFailure("ble_permission")
        }
    }

    private fun findEsp(manager: ESPProvisionManager): FoundEsp {
        val found = AtomicReference<FoundEsp?>()
        val scanFailure = AtomicReference<String?>()
        val completed = CountDownLatch(1)
        val scanStarted = CountDownLatch(1)
        Handler(Looper.getMainLooper()).post {
            try {
                manager.searchBleEspDevices(
                    NabiEspGeneratedContract.bleNamePrefix,
                    object : BleScanListener {
                        override fun scanStartFailed() {
                            Log.w(TAG, "BLE scan could not start because Bluetooth is disabled")
                            scanFailure.set("bluetooth_disabled")
                            completed.countDown()
                        }

                        override fun onPeripheralFound(
                            device: BluetoothDevice,
                            scanResult: android.bluetooth.le.ScanResult,
                        ) {
                            val serviceUuid = scanResult.scanRecord?.serviceUuids
                                ?.firstOrNull {
                                    it.uuid.toString().equals(
                                        NabiEspGeneratedContract.bleServiceUuid,
                                        true,
                                    )
                                }
                                ?.uuid?.toString()
                            if (serviceUuid != null &&
                                found.compareAndSet(null, FoundEsp(device, serviceUuid))
                            ) {
                                manager.stopBleScan()
                                completed.countDown()
                            }
                        }

                        override fun scanCompleted() {
                            completed.countDown()
                        }

                        override fun onFailure(exception: Exception) {
                            Log.w(TAG, "BLE scan failed: ${exception.javaClass.simpleName}")
                            scanFailure.set("ble_scan_failed")
                            completed.countDown()
                        }
                    },
                )
            } catch (exception: Exception) {
                Log.w(TAG, "BLE scan setup exception: ${exception.javaClass.simpleName}")
                scanFailure.set("ble_scan_failed")
                completed.countDown()
            } finally {
                scanStarted.countDown()
            }
        }
        if (!scanStarted.await(5, TimeUnit.SECONDS)) {
            throw NabiEspBleFailure("ble_scan_failed")
        }
        if (!completed.await(9, TimeUnit.SECONDS)) {
            manager.stopBleScan()
        }
        scanFailure.get()?.let { throw NabiEspBleFailure(it) }
        return found.get() ?: throw NabiEspBleFailure("esp_not_found")
    }

    private fun sendConfig(device: ESPDevice, payload: ByteArray): ByteArray {
        val response = AtomicReference<ByteArray?>()
        val failure = AtomicReference<Exception?>()
        val complete = CountDownLatch(1)
        device.sendDataToCustomEndPoint(
            NabiEspGeneratedContract.bleConfigEndpoint,
            payload,
            object : ResponseListener {
                override fun onSuccess(returnData: ByteArray) {
                    response.set(returnData)
                    complete.countDown()
                }

                override fun onFailure(exception: Exception) {
                    failure.set(exception)
                    complete.countDown()
                }
            },
        )
        if (!complete.await(25, TimeUnit.SECONDS)) {
            throw NabiEspBleFailure("ble_provision_timeout")
        }
        failure.get()?.let { throw NabiEspBleFailure("pairing_failed") }
        return response.get() ?: throw NabiEspBleFailure("ble_provision_failed")
    }

    private fun postSuccess(result: io.flutter.plugin.common.MethodChannel.Result, value: Map<String, Any>) {
        android.os.Handler(android.os.Looper.getMainLooper()).post { result.success(value) }
    }

    private fun postError(result: io.flutter.plugin.common.MethodChannel.Result, code: String) {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            result.error(code, "Bluetooth setup did not complete.", null)
        }
    }

    private data class FoundEsp(val device: BluetoothDevice, val serviceUuid: String)

    private class NabiEspConnectionEvents {
        val done = CountDownLatch(1)
        val failure = AtomicReference(false)

        @Subscribe(threadMode = ThreadMode.BACKGROUND)
        fun onDeviceConnection(event: DeviceConnectionEvent) {
            when (event.eventType) {
                ESPConstants.EVENT_DEVICE_CONNECTED -> done.countDown()
                ESPConstants.EVENT_DEVICE_CONNECTION_FAILED -> {
                    failure.set(true)
                    done.countDown()
                }
            }
        }
    }

    private companion object {
        const val TAG = "NabiEspBle"
    }
}

private class NabiEspPairingStore(context: Context) {
    private val preferences = context.getSharedPreferences("nabi_esp_pairing", Context.MODE_PRIVATE)

    fun get(address: String): String? = runCatching {
        val encrypted = preferences.getString(storageKey(address), null) ?: return null
        val bytes = Base64.decode(encrypted, Base64.NO_WRAP)
        val iv = bytes.copyOfRange(0, 12)
        val ciphertext = bytes.copyOfRange(12, bytes.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, iv))
        String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8)
    }.getOrNull()

    fun put(address: String, value: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.iv + cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8))
        preferences.edit().putString(storageKey(address), Base64.encodeToString(encrypted, Base64.NO_WRAP)).apply()
    }

    private fun storageKey(address: String): String {
        val hash = MessageDigest.getInstance("SHA-256").digest(address.toByteArray(StandardCharsets.UTF_8))
        return hash.joinToString("") { "%02x".format(it) }
    }

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val alias = "nabi_esp_pairing_aes"
        val existing = keyStore.getKey(alias, null) as? SecretKey
        if (existing != null) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }
}

private class NabiEspBleFailure(val code: String) : Exception()
