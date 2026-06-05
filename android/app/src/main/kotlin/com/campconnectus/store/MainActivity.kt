package com.campconnectus.store

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val ONESIGNAL_CHANNEL = "com.campconnectus.store/onesignal"
    private val DEEP_LINK_CHANNEL = "com.campconnectus.store/deeplink"

    private var deepLinkChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    companion object {
        const val ENGINE_ID = "main_engine"
        var coldStartData: MutableMap<String, String>? = null

        // Pre-warms the engine before MainActivity is created.
        // Call this from your Application class if you have one,
        // otherwise it is called lazily in provideFlutterEngine.
        fun warmUpEngine(context: Context) {
            if (FlutterEngineCache.getInstance().get(ENGINE_ID) != null) return
            val engine = FlutterEngine(context)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        }
    }

    // -------------------------------------------------------------------------
    // Engine caching — prevents full reinit on Samsung's second onCreate call
    // -------------------------------------------------------------------------

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        // Always return the cached engine if it exists.
        // This is what prevents the splash screen from showing twice.
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }
        // First launch — create, cache, and return.
        val engine = FlutterEngine(context)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    // -------------------------------------------------------------------------
    // Logging helper — remove after debugging is done
    // -------------------------------------------------------------------------

    private fun writeLog(msg: String) {
        try {
            val file = java.io.File(getExternalFilesDir(null), "deeplink_log.txt")
            file.appendText("${System.currentTimeMillis()}: $msg\n")
        } catch (_: Exception) {}
    }

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // Flutter engine setup
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // OneSignal cold-start notification handling
    // -------------------------------------------------------------------------

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
