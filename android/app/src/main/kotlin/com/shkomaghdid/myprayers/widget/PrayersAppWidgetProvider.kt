package com.shkomaghdid.myprayers.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
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

            val arabic = prefs.getString("widget.${widgetId}.arabic", null)
                ?: prefs.getString("arabic", null)
                ?: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"
            val translation = prefs.getString("widget.${widgetId}.translation", null)
                ?: prefs.getString("translation", null)
                ?: "In the name of Allah, the Entirely Merciful, the Especially Merciful."
            val reference = prefs.getString("widget.${widgetId}.reference", null)
                ?: prefs.getString("reference", null)
                ?: "Al-Fātiḥah 1:1"

            val theme = prefs.getString("widget.${widgetId}.theme", "auto")
            val style = prefs.getString("widget.${widgetId}.style", "tinted")
            val layout = prefs.getString("widget.${widgetId}.layout", "default")
            val showTr = prefs.getBoolean("widget.${widgetId}.showTr", true)
            val showRef = prefs.getBoolean("widget.${widgetId}.showRef", true)
            val sizeKey = prefs.getString("widget.${widgetId}.size", "m")

            val (arSize, trSize, refSize) = when (sizeKey) {
                "s" -> Triple(15f, 11f, 9f)
                "l" -> Triple(23f, 13.5f, 11f)
                else -> Triple(19f, 12f, 10f)
            }

            val nightMode = when (theme) {
                "light" -> false
                "dark" -> true
                else -> context.resources.configuration.uiMode and
                    android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                    android.content.res.Configuration.UI_MODE_NIGHT_YES
            }

            val onAccentColor = if (nightMode) Color.parseColor("#0E1013") else Color.WHITE
            val isAccent = style == "accent"

            val textColor = when {
                isAccent -> onAccentColor
                nightMode -> Color.parseColor("#F1F3F5")
                else -> Color.parseColor("#15171A")
            }
            val mutedColor = when {
                isAccent -> Color.parseColor(if (nightMode) "#660E1013" else "#CCFFFFFF")
                nightMode -> Color.parseColor("#B6BBC2")
                else -> Color.parseColor("#5A5F66")
            }
            val subtleColor = when {
                isAccent -> Color.parseColor(if (nightMode) "#440E1013" else "#99FFFFFF")
                nightMode -> Color.parseColor("#8A8F96")
                else -> Color.parseColor("#898E95")
            }

            val bgRes = when (style) {
                "solid" -> if (nightMode) R.drawable.widget_bg_solid_dark else R.drawable.widget_bg_solid_light
                "accent" -> R.drawable.widget_bg_accent
                "tinted" -> if (nightMode) R.drawable.widget_bg_tinted_dark else R.drawable.widget_bg_tinted_light
                else -> R.drawable.widget_bg_transparent
            }

            val isCentered = layout == "centered"
            views.setViewVisibility(R.id.widget_card_default,
                if (isCentered) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_card_centered,
                if (isCentered) View.VISIBLE else View.GONE)

            val activeCardId = if (isCentered)
                R.id.widget_card_centered else R.id.widget_card_default
            views.setInt(activeCardId, "setBackgroundResource", bgRes)

            if (isCentered) {
                val centeredArabic = "﴿  $arabic  ﴾"
                views.setTextViewText(R.id.widget_arabic_centered, centeredArabic)
                views.setTextColor(R.id.widget_arabic_centered, textColor)
                views.setTextViewTextSize(R.id.widget_arabic_centered,
                    android.util.TypedValue.COMPLEX_UNIT_SP, arSize)

                views.setTextViewText(R.id.widget_translation_centered, translation)
                views.setTextColor(R.id.widget_translation_centered, mutedColor)
                views.setTextViewTextSize(R.id.widget_translation_centered,
                    android.util.TypedValue.COMPLEX_UNIT_SP, trSize)
                views.setViewVisibility(R.id.widget_translation_centered,
                    if (showTr) View.VISIBLE else View.GONE)

                views.setTextViewText(R.id.widget_reference_centered, reference)
                views.setTextColor(R.id.widget_reference_centered, subtleColor)
                views.setTextViewTextSize(R.id.widget_reference_centered,
                    android.util.TypedValue.COMPLEX_UNIT_SP, refSize)
                views.setViewVisibility(R.id.widget_reference_centered,
                    if (showRef) View.VISIBLE else View.GONE)
            } else {
                views.setTextViewText(R.id.widget_arabic, arabic)
                views.setTextColor(R.id.widget_arabic, textColor)
                views.setTextViewTextSize(R.id.widget_arabic,
                    android.util.TypedValue.COMPLEX_UNIT_SP, arSize)

                views.setTextViewText(R.id.widget_translation, translation)
                views.setTextColor(R.id.widget_translation, mutedColor)
                views.setTextViewTextSize(R.id.widget_translation,
                    android.util.TypedValue.COMPLEX_UNIT_SP, trSize)
                views.setViewVisibility(R.id.widget_translation,
                    if (showTr) View.VISIBLE else View.GONE)

                views.setTextViewText(R.id.widget_reference, reference)
                views.setTextColor(R.id.widget_reference, subtleColor)
                views.setTextViewTextSize(R.id.widget_reference,
                    android.util.TypedValue.COMPLEX_UNIT_SP, refSize)
                views.setViewVisibility(R.id.widget_reference,
                    if (showRef) View.VISIBLE else View.GONE)
            }

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
