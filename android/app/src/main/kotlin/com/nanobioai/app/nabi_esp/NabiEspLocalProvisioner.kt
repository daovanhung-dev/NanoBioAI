package com.nanobioai.app.nabi_esp

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

/** Sends setup only through the local ESP access point; no Internet route is required. */
internal class NabiEspLocalProvisioner(context: Context) {
    private val connectivity =
        context.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    fun isEspApConnected(): Boolean = findEspApNetwork() != null

    fun getEspStatus(): Map<String, Any?> = requestEsp(
        method = "GET",
        path = NabiEspCloudContract.apStatusPath,
    )

    fun provisionEsp(
        ssid: String,
        wifiPassword: String,
        identifierType: String,
        identifier: String,
        accountPassword: String,
    ): Map<String, Any?> {
        require(ssid.isNotBlank() && ssid.toByteArray().size <= 32) {
            "Tên Wi-Fi không hợp lệ."
        }
        require(wifiPassword.length in 8..63) { "Mật khẩu Wi-Fi phải dài từ 8 đến 63 ký tự." }
        require(identifierType in setOf("phone", "email", "username")) {
            "Loại tài khoản Nabi không hợp lệ."
        }
        require(identifier.isNotBlank() && identifier.length <= 320) {
            "Tài khoản Nabi không hợp lệ."
        }
        require(accountPassword.isNotEmpty() && accountPassword.length <= 128) {
            "Mật khẩu tài khoản Nabi không hợp lệ."
        }

        val body = JSONObject().apply {
            put("ssid", ssid)
            put("wifi_password", wifiPassword)
            put("identifier_type", identifierType)
            put("identifier", identifier)
            put("account_password", accountPassword)
            put("contract_version", NabiEspCloudContract.contractVersion)
            put("protocol_version", NabiEspCloudContract.protocolVersion)
        }
        return requestEsp(
            method = "POST",
            path = NabiEspCloudContract.apProvisionPath,
            body = body.toString(),
        )
    }

    private fun requestEsp(method: String, path: String, body: String? = null): Map<String, Any?> {
        val wifiNetwork = findEspApNetwork()
            ?: throw IllegalStateException("Kết nối điện thoại với Wi-Fi của Nabi trước.")

        val connection = wifiNetwork.openConnection(
            URL(NabiEspCloudContract.apBaseUrl + path),
        ) as HttpURLConnection
        connection.requestMethod = method
        connection.connectTimeout = REQUEST_TIMEOUT_MS
        connection.readTimeout = REQUEST_TIMEOUT_MS
        connection.instanceFollowRedirects = false
        connection.setRequestProperty("Accept", "application/json")
        connection.setRequestProperty("Connection", "close")
        if (body != null) {
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.outputStream.use { output ->
                output.write(body.toByteArray(Charsets.UTF_8))
            }
        }

        try {
            val statusCode = connection.responseCode
            if (statusCode !in 200..299) {
                throw IllegalStateException("ESP chưa nhận được cấu hình. Thử lại từ Wi-Fi Nabi.")
            }
            val response = connection.inputStream.bufferedReader().use { it.readText() }
            require(response.length <= MAX_RESPONSE_LENGTH) { "ESP trả về dữ liệu không hợp lệ." }
            val envelope = JSONObject(response)
            if (!envelope.optBoolean("success")) {
                val error = envelope.optJSONObject("error")?.optString("code")
                throw IllegalStateException(error ?: "ESP chưa nhận được cấu hình.")
            }
            val data = envelope.optJSONObject("data")
                ?: throw IllegalStateException("ESP chưa trả trạng thái thiết lập.")
            return data.toMap()
        } finally {
            connection.disconnect()
        }
    }

    private fun findEspApNetwork() = connectivity.allNetworks.firstOrNull { network ->
            val capabilities = connectivity.getNetworkCapabilities(network)
            val properties = connectivity.getLinkProperties(network)
            capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true &&
                properties?.linkAddresses?.any {
                    it.address.hostAddress?.startsWith(ESP_AP_SUBNET_PREFIX) == true
                } == true
        }

    private fun JSONObject.toMap(): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        val names = keys()
        while (names.hasNext()) {
            val name = names.next()
            result[name] = get(name)
        }
        return result
    }

    private companion object {
        const val ESP_AP_SUBNET_PREFIX = "192.168.4."
        const val REQUEST_TIMEOUT_MS = 8_000
        const val MAX_RESPONSE_LENGTH = 4_096
    }
}
