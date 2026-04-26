package com.pixelchat.client

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.KeyAgreement
import java.security.spec.X509EncodedKeySpec

class CryptoPlugin : MethodChannel.MethodCallHandler {
    companion object {
        private const val KEY_ALIAS = "pixelchat_x25519"
    }
    
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply {
        load(null)
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateKeyPair" -> generateKeyPair(result)
            "deleteKeyPair" -> deleteKeyPair(result)
            "deleteAllKeyPairs" -> deleteAllKeyPairs(result)
            "getPrivateKey" -> getPrivateKey(result)
            "computeSharedSecret" -> computeSharedSecret(result, call)
            else -> result.notImplemented()
        }
    }
    
    private fun generateKeyPair(result: MethodChannel.Result) {
        try {
            // Сначала удаляем старый ключ, если есть
            try {
                keyStore.deleteEntry(KEY_ALIAS)
            } catch (e: Exception) {
                // Игнорируем, если ключа не было
            }
            
            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC,
                "AndroidKeyStore"
            )
            
            val spec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_AGREE_KEY
            ).apply {
                setAlgorithmParameterSpec(java.security.spec.ECGenParameterSpec("X25519"))
                setUserAuthenticationRequired(false)
            }.build()
            
            keyPairGenerator.initialize(spec)
            val keyPair = keyPairGenerator.generateKeyPair()
            
            val publicKeyBytes = keyPair.public.encoded
            val publicKeyBase64 = Base64.encodeToString(publicKeyBytes, Base64.DEFAULT)
            
            val response = mapOf(
                "publicKey" to publicKeyBase64,
                "keyAlias" to KEY_ALIAS
            )
            result.success(response)
        } catch (e: Exception) {
            result.error("KEY_GEN_ERROR", e.message, null)
        }
    }
    
    private fun getPrivateKey(result: MethodChannel.Result) {
        try {
            val privateKey = keyStore.getKey(KEY_ALIAS, null)
            val privateKeyBytes = privateKey.encoded
            val privateKeyBase64 = Base64.encodeToString(privateKeyBytes, Base64.DEFAULT)
            result.success(privateKeyBase64)
        } catch (e: Exception) {
            result.error("KEY_GET_ERROR", e.message, null)
        }
    }
    
    private fun computeSharedSecret(result: MethodChannel.Result, call: MethodCall) {
        try {
            val otherPublicKeyBase64 = call.argument<String>("otherPublicKey") ?: throw Exception("Missing otherPublicKey")
            
            val otherPublicKeyBytes = Base64.decode(otherPublicKeyBase64, Base64.DEFAULT)
            val otherPublicKeySpec = X509EncodedKeySpec(otherPublicKeyBytes)
            val keyFactory = KeyFactory.getInstance("EC")
            val otherPublicKey = keyFactory.generatePublic(otherPublicKeySpec)
            
            val privateKey = keyStore.getKey(KEY_ALIAS, null) as java.security.PrivateKey
            
            val keyAgreement = KeyAgreement.getInstance("ECDH")
            keyAgreement.init(privateKey)
            keyAgreement.doPhase(otherPublicKey, true)
            val sharedSecret = keyAgreement.generateSecret()
            
            result.success(Base64.encodeToString(sharedSecret, Base64.DEFAULT))
        } catch (e: Exception) {
            result.error("ECDH_ERROR", e.message, null)
        }
    }
    
    private fun deleteKeyPair(result: MethodChannel.Result) {
        try {
            keyStore.deleteEntry(KEY_ALIAS)
            result.success(true)
        } catch (e: Exception) {
            result.error("KEY_DELETE_ERROR", e.message, null)
        }
    }
    
    private fun deleteAllKeyPairs(result: MethodChannel.Result) {
        try {
            // Удаляем только наш ключ
            keyStore.deleteEntry(KEY_ALIAS)
            result.success(true)
        } catch (e: Exception) {
            result.error("KEY_DELETE_ALL_ERROR", e.message, null)
        }
    }
}