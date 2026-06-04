package com.example.kartly_e_commerce

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONObject

class HomeWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout)

            // Read saved widget data
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(DATA_KEY, null)

            var cartItems = "0 items"
            var cartTotal = "₦0"
            var orderId = ""
            var orderAmount = ""
            var orderProgress = 0
            var refundId = ""
            var refundAmount = ""
            var refundProgress = 0

            if (jsonStr != null) {
                try {
                    val json = JSONObject(jsonStr)
                    val count = json.optInt("cartItems", 0)
                    cartItems = if (count == 1) "1 item" else "$count items"
                    cartTotal = json.optString("cartTotal", "₦0")
                    orderId = json.optString("latestOrderId", "")
                    orderAmount = json.optString("latestOrderAmount", "")
                    orderProgress = json.optString("latestOrderStatus", "0").toIntOrNull() ?: 0
                    refundId = json.optString("refundId", "")
                    refundAmount = json.optString("refundAmount", "")
                    refundProgress = json.optString("refundStatus", "0").toIntOrNull() ?: 0
                } catch (_: Exception) {}
            }

            // Update text views
            views.setTextViewText(R.id.widget_cart_items, cartItems)
            views.setTextViewText(R.id.widget_cart_total, cartTotal)

            if (orderId.isNotEmpty()) {
                views.setTextViewText(R.id.widget_order_id, orderId)
                views.setTextViewText(R.id.widget_order_amount, orderAmount)
                // Update order progress bar
                views.setViewVisibility(R.id.widget_order_bar, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_order_progress, android.view.View.VISIBLE)
                // Set progress width as fraction of parent
                val orderWidth = (orderProgress * 0.01).toFloat()
                // We'll handle progress bar sizing differently below
            } else {
                views.setTextViewText(R.id.widget_order_id, "No orders")
                views.setTextViewText(R.id.widget_order_amount, "")
            }

            if (refundId.isNotEmpty()) {
                views.setTextViewText(R.id.widget_refund_id, refundId)
                views.setTextViewText(R.id.widget_refund_amount, refundAmount)
            } else {
                views.setTextViewText(R.id.widget_refund_id, "No refunds")
                views.setTextViewText(R.id.widget_refund_amount, "")
            }

            // Set click intents
            setClickIntent(context, views, R.id.widget_search_bar, "https://campconnectus.store/shortcut/search", 0)
            setClickIntent(context, views, R.id.widget_account, "https://campconnectus.store/shortcut/account", 1)
            setClickIntent(context, views, R.id.widget_cart, "https://campconnectus.store/shortcut/cart", 2)
            setClickIntent(context, views, R.id.widget_orders, "https://campconnectus.store/shortcut/orders", 3)
            setClickIntent(context, views, R.id.widget_notifications, "https://campconnectus.store/shortcut/notifications", 4)
            setClickIntent(context, views, R.id.widget_cart_bar, "https://campconnectus.store/shortcut/cart", 5)
            setClickIntent(context, views, R.id.widget_latest_order, "https://campconnectus.store/shortcut/orders", 6)
            setClickIntent(context, views, R.id.widget_refund, "https://campconnectus.store/shortcut/orders", 7)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun setClickIntent(
            context: Context,
            views: RemoteViews,
            viewId: Int,
            url: String,
            requestCode: Int
        ) {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse(url)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(viewId, pending)
        }
    }
}
