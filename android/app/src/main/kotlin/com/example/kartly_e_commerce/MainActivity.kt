package com.example.kartly_e_commerce

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kartly_e_commerce/onesignal"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        handleColdStartNotification(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        handleColdStartNotification(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val data = intent?.data
        if (data != null) {
            intent.putExtra("deep_link_uri", data.toString())
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getColdStartNotification") {
                val notificationData = getColdStartData()
                if (notificationData != null) {
                    result.success(notificationData)
                    coldStartData = null
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    companion object {
        var coldStartData: MutableMap<String, String>? = null
    }

    private fun handleColdStartNotification(intent: Intent?) {
        if (intent?.extras != null) {
            val onesignalData = intent?.extras?.getString("onesignal_data")
            if (onesignalData != null) {
                try {
                    val json = org.json.JSONObject(onesignalData)
                    val custom = json.optJSONObject("custom")
                    if (custom != null) {
                        val map = mutableMapOf<String, String>()
                        val notificationId = custom.optString("notification_id")
                        if (notificationId.isNotEmpty()) {
                            map["notification_id"] = notificationId
                            map["notif_message"] = custom.optString("notif_message", "")
                            map["notif_title"] = custom.optString("notif_title", "")
                            map["notif_image"] = custom.optString("notif_image", "")
                            coldStartData = map
                        }
                    }
                } catch (e: Exception) {
                    // Ignore parsing errors
                }
            }
        }
    }

    private fun getColdStartData(): MutableMap<String, String>? {
        return coldStartData
    }
}
