package com.darren.potts.seizure_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SeizureAlertWidgetProvider : HomeWidgetProvider() {
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

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
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
            val compact = width < 180 || height < 210
            val layout = when {
                compact -> R.layout.seizure_alert_widget_compact
                width >= 260 && height >= 280 -> R.layout.seizure_alert_widget_large
                else -> R.layout.seizure_alert_widget
            }
            val views = RemoteViews(context.packageName, layout).apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val diameter = minOf(width - 32, height - if (compact) 40 else 72).coerceIn(48, 320).toFloat()
                    setViewLayoutWidth(R.id.widget_ring, diameter, TypedValue.COMPLEX_UNIT_DIP)
                    setViewLayoutHeight(R.id.widget_ring, diameter, TypedValue.COMPLEX_UNIT_DIP)
                }
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
