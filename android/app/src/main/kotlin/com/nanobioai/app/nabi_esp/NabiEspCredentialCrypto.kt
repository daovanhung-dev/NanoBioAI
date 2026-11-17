package com.nanobioai.app.nabi_esp

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Encrypts the Nabi setup credential for storage in the app's SQLite database. */
internal object NabiEspCredentialCrypto {
    private const val KEY_ALIAS = "nabi_esp_credential_v1"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val TAG_LENGTH_BITS = 128

    fun encrypt(value: String): Map<String, String> {
        val clearBytes = value.toByteArray(StandardCharsets.UTF_8)
        try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
            val ciphertext = cipher.doFinal(clearBytes)
            return mapOf(
                "ciphertext" to Base64.encodeToString(ciphertext, Base64.NO_WRAP),
                "iv" to Base64.encodeToString(cipher.iv, Base64.NO_WRAP),
            )
        } finally {
            clearBytes.fill(0)
        }
    }

    fun decrypt(ciphertext: String, iv: String): String {
        val encryptedBytes = Base64.decode(ciphertext, Base64.NO_WRAP)
        val ivBytes = Base64.decode(iv, Base64.NO_WRAP)
        require(ivBytes.size == 12) { "Invalid credential IV." }
        val clearBytes = Cipher.getInstance(TRANSFORMATION).run {
            init(
                Cipher.DECRYPT_MODE,
                getOrCreateKey(),
                GCMParameterSpec(TAG_LENGTH_BITS, ivBytes),
            )
            doFinal(encryptedBytes)
        }
        try {
            return String(clearBytes, StandardCharsets.UTF_8)
        } finally {
            clearBytes.fill(0)
            encryptedBytes.fill(0)
            ivBytes.fill(0)
        }
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing

        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setRandomizedEncryptionRequired(true)
                .setUserAuthenticationRequired(false)
                .build(),
        )
        return generator.generateKey()
    }
}
