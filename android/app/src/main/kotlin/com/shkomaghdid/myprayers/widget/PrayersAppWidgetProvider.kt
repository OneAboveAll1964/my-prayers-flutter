package com.shkomaghdid.myprayers.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.shkomaghdid.myprayers.MainActivity
import com.shkomaghdid.myprayers.R
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayersAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = buildViews(context, id, prefs)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_RANDOMIZE) {
            val widgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                WidgetRandomizer.rotate(context, widgetId)
                val mgr = AppWidgetManager.getInstance(context)
                onUpdate(context, mgr, intArrayOf(widgetId))
            }
        }
    }

    companion object {
        const val ACTION_RANDOMIZE = "com.shkomaghdid.myprayers.WIDGET_RANDOMIZE"

        fun buildViews(
            context: Context,
            widgetId: Int,
            prefs: SharedPreferences
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayers_app_widget)

            val arabic = prefs.getString("arabic", null)
                ?: prefs.getString("widget.${widgetId}.arabic", null)
                ?: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"
            val translation = prefs.getString("translation", null)
                ?: prefs.getString("widget.${widgetId}.translation", null)
                ?: "In the name of Allah, the Entirely Merciful, the Especially Merciful."
            val reference = prefs.getString("reference", null)
                ?: prefs.getString("widget.${widgetId}.reference", null)
                ?: ""

            val theme = prefs.getString("widget.${widgetId}.theme", "auto")
            val showTr = prefs.getBoolean("widget.${widgetId}.showTr", true)
            val sizeKey = prefs.getString("widget.${widgetId}.size", "m")
            val (arSize, trSize) = when (sizeKey) {
                "s" -> 16f to 11f
                "l" -> 24f to 14f
                else -> 20f to 12.5f
            }

            val nightMode = if (theme == "light") false
                else if (theme == "dark") true
                else context.resources.configuration.uiMode and
                    android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                    android.content.res.Configuration.UI_MODE_NIGHT_YES

            val textColor = if (nightMode) Color.parseColor("#F1F3F5") else Color.parseColor("#15171A")
            val mutedColor = if (nightMode) Color.parseColor("#B6BBC2") else Color.parseColor("#5A5F66")

            views.setTextViewText(R.id.widget_arabic, arabic)
            views.setTextColor(R.id.widget_arabic, textColor)
            views.setTextViewTextSize(R.id.widget_arabic,
                android.util.TypedValue.COMPLEX_UNIT_SP, arSize)

            views.setTextViewText(R.id.widget_translation, translation)
            views.setTextColor(R.id.widget_translation, mutedColor)
            views.setTextViewTextSize(R.id.widget_translation,
                android.util.TypedValue.COMPLEX_UNIT_SP, trSize)
            views.setViewVisibility(
                R.id.widget_translation,
                if (showTr) View.VISIBLE else View.GONE
            )

            views.setTextViewText(R.id.widget_reference, reference)
            views.setTextColor(R.id.widget_reference, mutedColor)

            val openIntent = Intent(context, MainActivity::class.java)
            openIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            val openPI = PendingIntent.getActivity(
                context, widgetId, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openPI)

            return views
        }
    }
}
