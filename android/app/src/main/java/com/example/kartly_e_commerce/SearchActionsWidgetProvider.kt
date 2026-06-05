package com.example.kartly_e_commerce

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class SearchActionsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.search_actions_widget_layout)

            val searchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/search")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_search_bar, PendingIntent.getActivity(
                context, 0, searchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val accountIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/account")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_account, PendingIntent.getActivity(
                context, 1, accountIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val cartIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/cart")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_cart, PendingIntent.getActivity(
                context, 2, cartIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val ordersIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/orders")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_orders, PendingIntent.getActivity(
                context, 3, ordersIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            val notifIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://campconnectus.store/shortcut/notifications")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_notifications, PendingIntent.getActivity(
                context, 4, notifIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
