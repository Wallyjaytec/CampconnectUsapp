package com.campconnectus.store

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class CartSummaryWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                val views = RemoteViews(context.packageName, R.layout.cart_summary_widget_layout)
                views.setTextViewText(R.id.widget_cart_items, "0 items in cart")
                views.setTextViewText(R.id.widget_cart_total, "₦0")
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.cart_summary_widget_layout)

            views.setTextViewText(R.id.widget_cart_items, "0 items in cart")
            views.setTextViewText(R.id.widget_cart_total, "₦0")

            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = prefs.getString("flutter.widget_data", null)

                if (jsonStr != null) {
                    val json = org.json.JSONObject(jsonStr)
                    val count = json.optInt("cartItems", 0)
                    val cartItems = if (count == 1) "1 item in cart" else "$count items in cart"
                    val cartTotal = json.optString("cartTotal", "₦0")
                    views.setTextViewText(R.id.widget_cart_items, cartItems)
                    views.setTextViewText(R.id.widget_cart_total, cartTotal)
                }
            } catch (_: Exception) {}

            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/cart")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_cart_bar, pending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
