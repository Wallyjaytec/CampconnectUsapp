package com.campconnectus.store

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val ONESIGNAL_CHANNEL = "com.campconnectus.store/onesignal"
    private val DEEP_LINK_CHANNEL = "com.campconnectus.store/deeplink"
    private val SKIP_SPLASH_CHANNEL = "com.campconnectus.store/skip_splash"
    private val WIDGET_UPDATE_CHANNEL = "com.campconnectus.store/widget_update"

    private var deepLinkChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    private fun writeLog(msg: String) {
        try {
            val file = java.io.File(getExternalFilesDir(null), "deeplink_log.txt")
            file.appendText("${System.currentTimeMillis()}: $msg\n")
        } catch (_: Exception) {}
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val skipFile = java.io.File(filesDir, "skip_splash_flag")
        if (skipFile.exists()) {
            setTheme(R.style.InstantTheme)
        }

        writeLog("onCreate called - savedInstanceState: ${savedInstanceState != null} - intent data: ${intent?.data}")
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
            val path = uri.pathSegments
            if (path.size >= 2 && path[0] == "shortcut") {
                try {
                    val file = java.io.File(filesDir, "skip_splash_flag")
                    file.writeText(path[1])
                } catch (_: Exception) {}
            }

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
            SKIP_SPLASH_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "shouldSkip") {
                try {
                    val file = java.io.File(filesDir, "skip_splash_flag")
                    if (file.exists()) {
                        val dest = file.readText().trim()
                        file.delete()
                        result.success(dest)
                    } else {
                        result.success(null)
                    }
                } catch (_: Exception) {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_UPDATE_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgets") {
                try {
                    val context = this
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    
                    // Update all 3 widgets
                    val searchWidget = ComponentName(context, SearchActionsWidgetProvider::class.java)
                    val orderWidget = ComponentName(context, OrderTrackingWidgetProvider::class.java)
                    val cartWidget = ComponentName(context, CartSummaryWidgetProvider::class.java)
                    
                    val searchIds = appWidgetManager.getAppWidgetIds(searchWidget)
                    val orderIds = appWidgetManager.getAppWidgetIds(orderWidget)
                    val cartIds = appWidgetManager.getAppWidgetIds(cartWidget)
                    
                    if (searchIds.isNotEmpty()) {
                        SearchActionsWidgetProvider.Companion.updateAppWidget(context, appWidgetManager, searchIds[0])
                    }
                    if (orderIds.isNotEmpty()) {
                        OrderTrackingWidgetProvider.Companion.updateAppWidget(context, appWidgetManager, orderIds[0])
                    }
                    if (cartIds.isNotEmpty()) {
                        CartSummaryWidgetProvider.Companion.updateAppWidget(context, appWidgetManager, cartIds[0])
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
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
