package com.example.kartly_e_commerce

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val ONESIGNAL_CHANNEL = "com.example.kartly_e_commerce/onesignal"
    private val DEEP_LINK_CHANNEL = "com.example.kartly_e_commerce/deeplink"

    private var deepLinkChannel: MethodChannel? = null

    // Holds a deep-link URI that arrived before the Flutter engine was ready
    // (i.e. during onCreate on a cold or warm-restart path).
    // Flushed to Flutter inside configureFlutterEngine once the channel exists.
    private var pendingDeepLink: String? = null

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleColdStartNotification(intent)

        // Engine is NOT ready yet — stash the URI so configureFlutterEngine
        // can forward it once the MethodChannel exists.
        intent?.data?.let { uri ->
            pendingDeepLink = uri.toString()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Keep getIntent() current so any future call returns the latest intent.
        setIntent(intent)
        handleColdStartNotification(intent)

        intent.data?.let { uri ->
            val link = uri.toString()
            if (deepLinkChannel != null) {
                // Engine is already running — forward immediately.
                deepLinkChannel!!.invokeMethod("onDeepLink", link)
            } else {
                // Engine not yet ready (rare, but possible if onNewIntent fires
                // very early). Stash so configureFlutterEngine can flush it.
                pendingDeepLink = link
            }
        }
    }

    // -------------------------------------------------------------------------
    // Flutter engine setup
    // -------------------------------------------------------------------------

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Deep-link channel — flush any URI that arrived before the engine was ready.
        deepLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEEP_LINK_CHANNEL
        ).also { channel ->
            pendingDeepLink?.let { link ->
                channel.invokeMethod("onDeepLink", link)
                pendingDeepLink = null
            }
        }

        // OneSignal / notification channel
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

    // -------------------------------------------------------------------------
    // OneSignal cold-start notification handling
    // -------------------------------------------------------------------------

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
        } catch (_: Exception) {
            // Malformed JSON — ignore silently.
        }
    }
}
