package com.campconnectus.store

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class RefundTrackingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                val views = RemoteViews(context.packageName, R.layout.refund_tracking_widget_layout)
                views.setTextViewText(R.id.widget_refund_id, "No refunds")
                views.setTextViewText(R.id.widget_refund_amount, "")
                views.setTextViewText(R.id.widget_refund_status, "")
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
            val views = RemoteViews(context.packageName, R.layout.refund_tracking_widget_layout)

            views.setTextViewText(R.id.widget_refund_id, "No refunds")
            views.setTextViewText(R.id.widget_refund_amount, "")
            views.setTextViewText(R.id.widget_refund_status, "")

            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = prefs.getString("flutter.widget_data", null)

                if (jsonStr != null) {
                    val json = org.json.JSONObject(jsonStr)
                    val refundId = json.optString("refundId", "")
                    val refundAmount = json.optString("refundAmount", "")
                    val refundStatus = json.optString("refundStatus", "")

                    if (refundId.isNotEmpty()) {
                        views.setTextViewText(R.id.widget_refund_id, refundId)
                        views.setTextViewText(R.id.widget_refund_amount, refundAmount)
                        if (refundStatus.isNotEmpty()) {
                            views.setTextViewText(R.id.widget_refund_status, refundStatus)
                        }
                    }
                }
            } catch (_: Exception) {}

            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/refunds")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context, appWidgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refund, pending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
