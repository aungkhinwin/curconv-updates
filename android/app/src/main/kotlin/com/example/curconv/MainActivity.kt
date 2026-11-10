package com.example.curconv

import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.os.Build
import android.provider.Settings
import java.io.File
import java.util.UUID
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    companion object {
        // Fallback is deliberately limited to this app process, not a fake boot ID.
        private val processIdentity = "process:" + UUID.randomUUID().toString()
    }
    private fun bootIdentity(): String {
        if (Build.VERSION.SDK_INT >= 24) {
            val count = Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT, -1)
            if (count >= 0) return "boot-count:$count"
        }
        return try {
            val id = File("/proc/sys/kernel/random/boot_id").readText().trim()
            if (id.isNotEmpty()) "boot-id:$id" else processIdentity
        } catch (_: Exception) { processIdentity }
    }
    private val alias = "curconv_offline_access_v1"
    private val prefs by lazy { getSharedPreferences("curconv_access_secure", MODE_PRIVATE) }

    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = store.getKey(alias, null)
        if (existing is SecretKey) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build())
        return generator.generateKey()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "curconv/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUrl" -> {
                        try {
                            val url = call.argument<String>("url")
                                ?: throw IllegalArgumentException("Missing URL")
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("open-url", "Could not open download link.", null)
                        }
                    }
                    "installApk" -> {
                        try {
                            val path = call.argument<String>("path")
                                ?: throw IllegalArgumentException("Missing APK path")
                            val apkFile = File(path)
                            require(apkFile.isFile) { "APK file does not exist" }
                            val apkUri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                apkFile
                            )
                            val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                                setDataAndType(apkUri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("install-apk", "Could not open Android installer.", error.message)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "curconv/access_clock")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "uptime" -> result.success(SystemClock.elapsedRealtime())
                        "bootIdentity" -> result.success(bootIdentity())
                        "deviceInfo" -> {
                            val deviceId = prefs.getString("device_id", null)
                                ?: UUID.randomUUID().toString().also {
                                    if (!prefs.edit().putString("device_id", it).commit()) {
                                        error("device id storage failed")
                                    }
                                }
                            val appVersion = packageManager
                                .getPackageInfo(packageName, 0).versionName ?: ""
                            result.success(mapOf(
                                "device_id" to deviceId,
                                "brand" to Build.MANUFACTURER.orEmpty().take(80),
                                "model" to Build.MODEL.orEmpty().take(120),
                                "android_version" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})".take(80),
                                "app_version" to appVersion.take(40)
                            ))
                        }
                        "readLease" -> {
                            val encoded = prefs.getString("lease", null)
                            if (encoded == null) result.success(null)
                            else {
                                val parts = encoded.split(":")
                                require(parts.size == 2)
                                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                                cipher.init(Cipher.DECRYPT_MODE, secretKey(),
                                    GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)))
                                result.success(String(cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)), Charsets.UTF_8))
                            }
                        }
                        "writeLease" -> {
                            val plain = call.argument<String>("lease") ?: error("missing lease")
                            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                            cipher.init(Cipher.ENCRYPT_MODE, secretKey())
                            val encoded = Base64.encodeToString(cipher.iv, Base64.NO_WRAP) + ":" +
                                Base64.encodeToString(cipher.doFinal(plain.toByteArray(Charsets.UTF_8)), Base64.NO_WRAP)
                            if (!prefs.edit().putString("lease", encoded).commit()) error("storage failed")
                            result.success(null)
                        }
                        "clearLease" -> {
                            prefs.edit().remove("lease").commit()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    // Corrupt/invalid encrypted state cannot grant offline access.
                    if (call.method == "readLease") {
                        prefs.edit().remove("lease").commit()
                        result.success(null)
                    } else result.error("access-storage", "Offline permission could not be stored.", null)
                }
            }
    }
}
