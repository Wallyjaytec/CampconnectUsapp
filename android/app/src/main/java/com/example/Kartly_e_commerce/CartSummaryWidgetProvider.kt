package com.example.kartly_e_commerce

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONObject

class CartSummaryWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val DATA_KEY = "flutter.widget_data"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.cart_summary_widget_layout)

            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val jsonStr = prefs.getString(DATA_KEY, null)

                var cartItems = "0 items"
                var cartTotal = "\u20A60"

                if (jsonStr != null) {
                    val json = JSONObject(jsonStr)
                    val count = json.optInt("cartItems", 0)
                    cartItems = if (count == 1) "1 item" else "$count items"
                    cartTotal = json.optString("cartTotal", "\u20A60")
                }

                views.setTextViewText(R.id.widget_cart_items, cartItems)
                views.setTextViewText(R.id.widget_cart_total, cartTotal)

            } catch (_: Exception) {}

            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/cart")
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_cart_bar, pending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
