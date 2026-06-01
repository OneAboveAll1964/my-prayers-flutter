package com.shkomaghdid.sakina.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Bundle
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.res.ResourcesCompat
import com.shkomaghdid.sakina.MainActivity
import com.shkomaghdid.sakina.R
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.max
import kotlin.math.min

class PrayersAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = buildViews(context, id, prefs, appWidgetManager.getAppWidgetOptions(id))
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val prefs = HomeWidgetPlugin.getData(context)
        val views = buildViews(context, appWidgetId, prefs, newOptions ?: Bundle())
        appWidgetManager.updateAppWidget(appWidgetId, views)
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
        const val ACTION_RANDOMIZE = "com.shkomaghdid.sakina.WIDGET_RANDOMIZE"

        fun buildViews(
            context: Context,
            widgetId: Int,
            prefs: SharedPreferences,
            options: Bundle = Bundle()
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayers_app_widget)

            val arabic = prefs.getString("widget.${widgetId}.arabic", null)
                ?: prefs.getString("arabic", null)
                ?: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"
            val lang = prefs.getString("widget.${widgetId}.lang", "en") ?: "en"
            val translation = prefs.getString("widget.${widgetId}.translation_${lang}", null)
                ?: prefs.getString("widget.${widgetId}.translation_en", null)
                ?: prefs.getString("widget.${widgetId}.translation", null)
                ?: prefs.getString("translation_${lang}", null)
                ?: prefs.getString("translation_en", null)
                ?: prefs.getString("translation", null)
                ?: "In the name of Allah, the Entirely Merciful, the Especially Merciful."
            val reference = prefs.getString("widget.${widgetId}.reference", null)
                ?: prefs.getString("reference", null)
                ?: "Al-Fātiḥah 1:1"

            val theme = prefs.getString("widget.${widgetId}.theme", "dark")
            val style = prefs.getString("widget.${widgetId}.style", "transparent")
            val layoutKey = prefs.getString("widget.${widgetId}.layout", "centered")
            val font = prefs.getString("widget.${widgetId}.font", "uthmanic_hafs")
            val showTr = prefs.getBoolean("widget.${widgetId}.showTr", true)
            val showRef = prefs.getBoolean("widget.${widgetId}.showRef", false)
            val sizeKey = prefs.getString("widget.${widgetId}.size", "m")

            val (arSize, trSize, refSize) = when (sizeKey) {
                "s" -> Triple(18f, 11f, 9f)
                "l" -> Triple(36f, 17f, 13f)
                else -> Triple(28f, 14f, 11f)
            }

            val nightMode = when (theme) {
                "light" -> false
                "auto" -> context.resources.configuration.uiMode and
                    android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                    android.content.res.Configuration.UI_MODE_NIGHT_YES
                else -> true
            }

            val isAccent = style == "accent"

            val textColor = when {
                isAccent -> Color.WHITE
                nightMode -> Color.parseColor("#F1F3F5")
                else -> Color.parseColor("#15171A")
            }
            val mutedColor = when {
                isAccent -> Color.parseColor("#CCFFFFFF")
                nightMode -> Color.parseColor("#B6BBC2")
                else -> Color.parseColor("#5A5F66")
            }
            val subtleColor = when {
                isAccent -> Color.parseColor("#99FFFFFF")
                nightMode -> Color.parseColor("#8A8F96")
                else -> Color.parseColor("#898E95")
            }

            val bgRes = when (style) {
                "solid" -> if (nightMode) R.drawable.widget_bg_solid_dark else R.drawable.widget_bg_solid_light
                "accent" -> R.drawable.widget_bg_accent
                "tinted" -> if (nightMode) R.drawable.widget_bg_tinted_dark else R.drawable.widget_bg_tinted_light
                else -> R.drawable.widget_bg_transparent
            }

            val isCentered = layoutKey == "centered"
            views.setViewVisibility(R.id.widget_card_default,
                if (isCentered) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_card_centered,
                if (isCentered) View.VISIBLE else View.GONE)

            val activeCardId = if (isCentered)
                R.id.widget_card_centered else R.id.widget_card_default
            views.setInt(activeCardId, "setBackgroundResource", bgRes)

            val displayMetrics = context.resources.displayMetrics
            val density = displayMetrics.density
            val screenWidthDp = (displayMetrics.widthPixels / density).toInt()
            val optionsWidthDp = options.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0
            )

            val widthDp = if (optionsWidthDp > 0) optionsWidthDp else screenWidthDp
            val padDp = 8 * 2
            val widthPx = max(192, ((widthDp - padDp) * density).toInt())

            val typeface = loadTypeface(context, font)
            val displayedArabic = if (isCentered) "﴿ $arabic ﴾" else arabic
            val arabicBitmap = renderArabicBitmap(
                text = displayedArabic,
                widthPx = widthPx,
                sizeSp = arSize,
                color = textColor,
                typeface = typeface,
                centered = isCentered,
                density = density
            )

            if (isCentered) {
                views.setImageViewBitmap(R.id.widget_arabic_centered, arabicBitmap)

                views.setTextViewText(R.id.widget_translation_centered, translation)
                views.setTextColor(R.id.widget_translation_centered, mutedColor)
                views.setTextViewTextSize(R.id.widget_translation_centered,
                    TypedValue.COMPLEX_UNIT_SP, trSize)
                views.setViewVisibility(R.id.widget_translation_centered,
                    if (showTr) View.VISIBLE else View.GONE)

                views.setTextViewText(R.id.widget_reference_centered, reference)
                views.setTextColor(R.id.widget_reference_centered, subtleColor)
                views.setTextViewTextSize(R.id.widget_reference_centered,
                    TypedValue.COMPLEX_UNIT_SP, refSize)
                views.setViewVisibility(R.id.widget_reference_centered,
                    if (showRef) View.VISIBLE else View.GONE)
            } else {
                views.setImageViewBitmap(R.id.widget_arabic, arabicBitmap)

                views.setTextViewText(R.id.widget_translation, translation)
                views.setTextColor(R.id.widget_translation, mutedColor)
                views.setTextViewTextSize(R.id.widget_translation,
                    TypedValue.COMPLEX_UNIT_SP, trSize)
                views.setViewVisibility(R.id.widget_translation,
                    if (showTr) View.VISIBLE else View.GONE)

                views.setTextViewText(R.id.widget_reference, reference)
                views.setTextColor(R.id.widget_reference, subtleColor)
                views.setTextViewTextSize(R.id.widget_reference,
                    TypedValue.COMPLEX_UNIT_SP, refSize)
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

        private fun loadTypeface(context: Context, fontKey: String?): Typeface? {
            val resId = when (fontKey) {
                "amiri_quran" -> R.font.amiri_quran
                "nastaleeq" -> R.font.kfgqpc_nastaleeq
                "scheherazade" -> R.font.scheherazade
                "noto_naskh" -> R.font.noto_naskh
                else -> R.font.uthmanic_hafs
            }
            return try {
                ResourcesCompat.getFont(context, resId)
            } catch (_: Throwable) {
                null
            }
        }

        private fun renderArabicBitmap(
            text: String,
            widthPx: Int,
            sizeSp: Float,
            color: Int,
            typeface: Typeface?,
            centered: Boolean,
            density: Float
        ): Bitmap {
            val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                this.textSize = sizeSp * density
                this.isSubpixelText = true
                if (typeface != null) this.typeface = typeface
            }
            val alignment = if (centered) Layout.Alignment.ALIGN_CENTER
                            else Layout.Alignment.ALIGN_OPPOSITE
            val safeWidth = max(64, widthPx)
            val builder = StaticLayout.Builder
                .obtain(text, 0, text.length, paint, safeWidth)
                .setAlignment(alignment)
                .setTextDirection(TextDirectionHeuristics.RTL)
                .setLineSpacing(0f, 1.25f)
                .setIncludePad(false)
                .setMaxLines(3)
                .setEllipsize(android.text.TextUtils.TruncateAt.END)
            val layout = builder.build()
            val height = max(1, min(2000, layout.height + 4))
            val bitmap = Bitmap.createBitmap(safeWidth, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.translate(0f, 2f)
            layout.draw(canvas)
            return bitmap
        }
    }
}
