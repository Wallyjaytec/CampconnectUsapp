package com.example.kartly_e_commerce

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONObject

class OrderTrackingWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.order_tracking_widget_layout)

            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val jsonStr = prefs.getString(DATA_KEY, null)

                var orderId = ""
                var orderAmount = ""
                var orderProgress = 0
                var refundId = ""
                var refundAmount = ""
                var refundProgress = 0

                if (jsonStr != null) {
                    val json = JSONObject(jsonStr)
                    orderId = json.optString("latestOrderId", "")
                    orderAmount = json.optString("latestOrderAmount", "")
                    orderProgress = json.optString("latestOrderStatus", "0").toIntOrNull() ?: 0
                    refundId = json.optString("refundId", "")
                    refundAmount = json.optString("refundAmount", "")
                    refundProgress = json.optString("refundStatus", "0").toIntOrNull() ?: 0
                }

                if (orderId.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_order_id, orderId)
                    views.setTextViewText(R.id.widget_order_amount, orderAmount)
                    views.setViewVisibility(R.id.widget_order_progress, android.view.View.VISIBLE)
                } else {
                    views.setTextViewText(R.id.widget_order_id, "No orders yet")
                    views.setTextViewText(R.id.widget_order_amount, "")
                }

                if (refundId.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_refund_id, refundId)
                    views.setTextViewText(R.id.widget_refund_amount, refundAmount)
                    views.setViewVisibility(R.id.widget_refund_progress, android.view.View.VISIBLE)
                } else {
                    views.setTextViewText(R.id.widget_refund_id, "No refunds")
                    views.setTextViewText(R.id.widget_refund_amount, "")
                }

                // Click intents
                val orderIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("https://campconnectus.store/shortcut/orders")
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val orderPending = PendingIntent.getActivity(
                    context, 0, orderIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_latest_order, orderPending)
                views.setOnClickPendingIntent(R.id.widget_refund, orderPending)

            } catch (_: Exception) {}

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
