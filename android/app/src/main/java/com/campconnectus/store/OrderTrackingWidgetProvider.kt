package com.campconnectus.store

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class OrderTrackingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                val views = RemoteViews(context.packageName, R.layout.order_tracking_widget_layout)
                views.setTextViewText(R.id.widget_order_id, "No orders yet")
                views.setTextViewText(R.id.widget_order_amount, "")
                views.setTextViewText(R.id.widget_order_product, "")
                views.setTextViewText(R.id.widget_order_status, "")
                views.setTextViewText(R.id.widget_refund_id, "No refunds")
                views.setTextViewText(R.id.widget_refund_amount, "")
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
            val views = RemoteViews(context.packageName, R.layout.order_tracking_widget_layout)

            views.setTextViewText(R.id.widget_order_id, "No orders yet")
            views.setTextViewText(R.id.widget_order_amount, "")
            views.setTextViewText(R.id.widget_order_product, "")
            views.setTextViewText(R.id.widget_order_status, "")
            views.setTextViewText(R.id.widget_refund_id, "No refunds")
            views.setTextViewText(R.id.widget_refund_amount, "")

            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = prefs.getString("flutter.widget_data", null)

                if (jsonStr != null) {
                    val json = org.json.JSONObject(jsonStr)
                    val orderId = json.optString("latestOrderId", "")
                    val orderAmount = json.optString("latestOrderAmount", "")
                    val orderProduct = json.optString("latestOrderProduct", "")
                    val orderStatus = json.optString("latestOrderStatus", "0")
                    val refundId = json.optString("refundId", "")
                    val refundAmount = json.optString("refundAmount", "")
                    val currencySymbol = json.optString("currencySymbol", "₦")

                    if (orderId.isNotEmpty()) {
                        views.setTextViewText(R.id.widget_order_id, orderId)
                        views.setTextViewText(R.id.widget_order_amount, orderAmount)
                        if (orderProduct.isNotEmpty()) {
                            views.setTextViewText(R.id.widget_order_status, orderProduct)
                        }
                    }
                    if (refundId.isNotEmpty()) {
                        views.setTextViewText(R.id.widget_refund_id, refundId)
                        views.setTextViewText(R.id.widget_refund_amount, refundAmount)
                    }
                }
            } catch (_: Exception) {}

            // Orders intent
            val ordersIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/refunds")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val ordersPending = PendingIntent.getActivity(
                context, appWidgetId * 10, ordersIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Refund intent — goes to refund page
            val refundIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/refunds")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val refundPending = PendingIntent.getActivity(
                context, appWidgetId * 10 + 1, refundIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_latest_order, ordersPending)
            views.setOnClickPendingIntent(R.id.widget_refund, refundPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
