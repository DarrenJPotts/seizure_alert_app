package com.darren.potts.seizure_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SeizureAlertWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString("widget_title", "Sign in required") ?: "Sign in required"
        val detail = widgetData.getString("widget_detail", "Open the app to continue.") ?: "Open the app to continue."
        val updated = widgetData.getString("widget_updated", "Not updated yet") ?: "Not updated yet"
        val actionLabel = widgetData.getString("widget_action_label", "OPEN APP") ?: "OPEN APP"
        val actionUri = widgetData.getString("widget_action_uri", "seizurealert://widget/openApp")
            ?: "seizurealert://widget/openApp"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.seizure_alert_widget).apply {
                setTextViewText(R.id.widget_status, title)
                setTextViewText(R.id.widget_updated, updated)
                setTextViewText(R.id.widget_action, actionLabel)
                setContentDescription(R.id.widget_action, "$actionLabel. $title. $detail")
                setContentDescription(R.id.widget_content, "$title. $detail. $actionLabel")
                val primaryIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse(actionUri),
                )
                setOnClickPendingIntent(R.id.widget_action, primaryIntent)
                setOnClickPendingIntent(R.id.widget_content, primaryIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
