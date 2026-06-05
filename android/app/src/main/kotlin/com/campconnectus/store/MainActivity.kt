package com.campconnectus.store

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val ONESIGNAL_CHANNEL = "com.campconnectus.store/onesignal"
    private val DEEP_LINK_CHANNEL = "com.campconnectus.store/deeplink"

    private var deepLinkChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    private fun writeLog(msg: String) {
        try {
            val file = java.io.File(getExternalFilesDir(null), "deeplink_log.txt")
            file.appendText("${System.currentTimeMillis()}: $msg\n")
        } catch (_: Exception) {}
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        writeLog("onCreate called - intent data: ${intent?.data}")
        super.onCreate(savedInstanceState)
        handleColdStartNotification(intent)
        intent?.data?.let { pendingDeepLink = it.toString() }
    }

    override fun onNewIntent(intent: Intent) {
        writeLog("onNewIntent called - intent data: ${intent.data}")
        super.onNewIntent(intent)
        setIntent(intent)
        handleColdStartNotification(intent)
        intent.data?.let { uri ->
            val link = uri.toString()
            if (deepLinkChannel != null) {
                deepLinkChannel!!.invokeMethod("onDeepLink", link)
            } else {
                pendingDeepLink = link
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        deepLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEEP_LINK_CHANNEL
        ).also { channel ->
            pendingDeepLink?.let {
                channel.invokeMethod("onDeepLink", it)
                pendingDeepLink = null
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ONESIGNAL_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getColdStartNotification" -> {
                    result.success(coldStartData)
                    coldStartData = null
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        var coldStartData: MutableMap<String, String>? = null
    }

    private fun handleColdStartNotification(intent: Intent?) {
        val onesignalData = intent?.extras?.getString("onesignal_data") ?: return
        try {
            val json = org.json.JSONObject(onesignalData)
            val custom = json.optJSONObject("custom") ?: return
            val notificationId = custom.optString("notification_id")
            if (notificationId.isNotEmpty()) {
                coldStartData = mutableMapOf(
                    "notification_id" to notificationId,
                    "notif_message"   to custom.optString("notif_message", ""),
                    "notif_title"     to custom.optString("notif_title", ""),
                    "notif_image"     to custom.optString("notif_image", "")
                )
            }
        } catch (_: Exception) {}
    }
}
