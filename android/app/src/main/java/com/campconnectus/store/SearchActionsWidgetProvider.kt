package com.campconnectus.store

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
            val views = RemoteViews(
                context.packageName,
                R.layout.search_actions_widget_layout
            )

            fun makePendingIntent(dest: String, requestCode: Int): PendingIntent {
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("https://campconnectus.store/shortcut/$dest")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                return PendingIntent.getActivity(
                    context,
                    appWidgetId * 10 + requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            views.setOnClickPendingIntent(R.id.widget_search_bar, makePendingIntent("search", 0))
            views.setOnClickPendingIntent(R.id.widget_account, makePendingIntent("account", 1))
            views.setOnClickPendingIntent(R.id.widget_cart, makePendingIntent("cart", 2))
            views.setOnClickPendingIntent(R.id.widget_orders, makePendingIntent("orders", 3))
            views.setOnClickPendingIntent(R.id.widget_notifications, makePendingIntent("notifications", 4))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
