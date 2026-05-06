package com.shkomaghdid.myprayers.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.RadioGroup
import android.widget.TextView
import androidx.core.content.res.ResourcesCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.shkomaghdid.myprayers.R
import es.antonborri.home_widget.HomeWidgetPlugin

class WidgetConfigActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        WindowCompat.setDecorFitsSystemWindows(window, false)

        val extras = intent.extras
        if (extras != null) {
            widgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        setContentView(R.layout.widget_config_activity)
        applyEdgeToEdgeInsets()
        wireUp()
    }

    private fun applyEdgeToEdgeInsets() {
        val header = findViewById<View>(R.id.config_header)
        val bottomBar = findViewById<View>(R.id.config_bottom_bar)
        val basePaddingHeaderTop = header.paddingTop
        val basePaddingBottomBar = bottomBar.paddingBottom

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.config_root)) { _, insets ->
            val sys = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            header.setPadding(
                header.paddingLeft,
                basePaddingHeaderTop + sys.top,
                header.paddingRight,
                header.paddingBottom
            )
            bottomBar.setPadding(
                bottomBar.paddingLeft,
                bottomBar.paddingTop,
                bottomBar.paddingRight,
                basePaddingBottomBar + sys.bottom
            )
            insets
        }
        header.requestApplyInsets()
    }

    private fun wireUp() {
        val prefs = HomeWidgetPlugin.getData(this)

        val groupType = findViewById<RadioGroup>(R.id.group_type)
        val groupStyle = findViewById<RadioGroup>(R.id.group_style)
        val groupLayout = findViewById<RadioGroup>(R.id.group_layout)
        val groupTheme = findViewById<RadioGroup>(R.id.group_theme)
        val groupFont = findViewById<RadioGroup>(R.id.group_font)
        val groupSize = findViewById<RadioGroup>(R.id.group_size)
        val groupShowTr = findViewById<RadioGroup>(R.id.group_show_tr)
        val groupLang = findViewById<RadioGroup>(R.id.group_lang)
        val langSection = findViewById<View>(R.id.section_lang)
        val groupShowRef = findViewById<RadioGroup>(R.id.group_show_ref)
        val randomize = findViewById<Button>(R.id.config_randomize)
        val save = findViewById<Button>(R.id.config_save)

        groupType.check(when (prefs.getString("widget.${widgetId}.type", "mix")) {
            "ayah" -> R.id.type_ayah
            "azkar" -> R.id.type_azkar
            else -> R.id.type_mix
        })
        groupStyle.check(when (prefs.getString("widget.${widgetId}.style", "transparent")) {
            "tinted" -> R.id.style_tinted
            "solid" -> R.id.style_solid
            "accent" -> R.id.style_accent
            else -> R.id.style_transparent
        })
        groupLayout.check(when (prefs.getString("widget.${widgetId}.layout", "centered")) {
            "default" -> R.id.layout_default
            else -> R.id.layout_centered
        })
        groupTheme.check(when (prefs.getString("widget.${widgetId}.theme", "dark")) {
            "light" -> R.id.theme_light
            "auto" -> R.id.theme_auto
            else -> R.id.theme_dark
        })
        groupLang.check(when (prefs.getString("widget.${widgetId}.lang", "en")) {
            "ar" -> R.id.lang_ar
            "ku" -> R.id.lang_ku
            else -> R.id.lang_en
        })
        groupFont.check(when (prefs.getString("widget.${widgetId}.font", "uthmanic_hafs")) {
            "qpc_hafs" -> R.id.font_qpc_hafs
            "nastaleeq" -> R.id.font_nastaleeq
            "scheherazade" -> R.id.font_scheherazade
            else -> R.id.font_uthmanic
        })

        val fontPreview = findViewById<TextView>(R.id.font_preview)
        fun updateFontPreview() {
            val resId = when (groupFont.checkedRadioButtonId) {
                R.id.font_qpc_hafs -> R.font.qpc_hafs
                R.id.font_nastaleeq -> R.font.kfgqpc_nastaleeq
                R.id.font_scheherazade -> R.font.scheherazade
                else -> R.font.uthmanic_hafs
            }
            fontPreview.typeface = ResourcesCompat.getFont(this, resId)
        }
        updateFontPreview()
        groupFont.setOnCheckedChangeListener { _, _ -> updateFontPreview() }
        groupSize.check(when (prefs.getString("widget.${widgetId}.size", "m")) {
            "s" -> R.id.size_s
            "l" -> R.id.size_l
            else -> R.id.size_m
        })
        val showTr = prefs.getBoolean("widget.${widgetId}.showTr", true)
        groupShowTr.check(if (showTr) R.id.show_tr_on else R.id.show_tr_off)
        groupShowRef.check(
            if (prefs.getBoolean("widget.${widgetId}.showRef", false))
                R.id.show_ref_on else R.id.show_ref_off
        )

        fun updateLangVisibility() {
            langSection.visibility =
                if (groupShowTr.checkedRadioButtonId == R.id.show_tr_on) View.VISIBLE else View.GONE
        }
        updateLangVisibility()
        groupShowTr.setOnCheckedChangeListener { _, _ -> updateLangVisibility() }

        randomize.setOnClickListener {
            persist(prefs.edit(),
                groupType, groupStyle, groupLayout, groupTheme, groupFont, groupSize, groupShowTr, groupLang, groupShowRef)
            WidgetRandomizer.rotate(this, widgetId)
            push()
        }

        save.setOnClickListener {
            persist(prefs.edit(),
                groupType, groupStyle, groupLayout, groupTheme, groupFont, groupSize, groupShowTr, groupLang, groupShowRef)
            WidgetRandomizer.rotate(this, widgetId)
            push()
            val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            setResult(RESULT_OK, result)
            finish()
        }
    }

    private fun persist(
        editor: android.content.SharedPreferences.Editor,
        groupType: RadioGroup,
        groupStyle: RadioGroup,
        groupLayout: RadioGroup,
        groupTheme: RadioGroup,
        groupFont: RadioGroup,
        groupSize: RadioGroup,
        groupShowTr: RadioGroup,
        groupLang: RadioGroup,
        groupShowRef: RadioGroup
    ) {
        val type = when (groupType.checkedRadioButtonId) {
            R.id.type_ayah -> "ayah"
            R.id.type_azkar -> "azkar"
            else -> "mix"
        }
        val style = when (groupStyle.checkedRadioButtonId) {
            R.id.style_transparent -> "transparent"
            R.id.style_solid -> "solid"
            R.id.style_accent -> "accent"
            else -> "tinted"
        }
        val layout = when (groupLayout.checkedRadioButtonId) {
            R.id.layout_centered -> "centered"
            else -> "default"
        }
        val theme = when (groupTheme.checkedRadioButtonId) {
            R.id.theme_light -> "light"
            R.id.theme_dark -> "dark"
            else -> "auto"
        }
        val font = when (groupFont.checkedRadioButtonId) {
            R.id.font_qpc_hafs -> "qpc_hafs"
            R.id.font_nastaleeq -> "nastaleeq"
            R.id.font_scheherazade -> "scheherazade"
            else -> "uthmanic_hafs"
        }
        val size = when (groupSize.checkedRadioButtonId) {
            R.id.size_s -> "s"
            R.id.size_l -> "l"
            else -> "m"
        }
        val showTr = groupShowTr.checkedRadioButtonId == R.id.show_tr_on
        val showRef = groupShowRef.checkedRadioButtonId == R.id.show_ref_on
        val lang = when (groupLang.checkedRadioButtonId) {
            R.id.lang_ar -> "ar"
            R.id.lang_ku -> "ku"
            else -> "en"
        }

        editor
            .putString("widget.${widgetId}.type", type)
            .putString("widget.${widgetId}.style", style)
            .putString("widget.${widgetId}.layout", layout)
            .putString("widget.${widgetId}.theme", theme)
            .putString("widget.${widgetId}.font", font)
            .putString("widget.${widgetId}.size", size)
            .putString("widget.${widgetId}.lang", lang)
            .putBoolean("widget.${widgetId}.showTr", showTr)
            .putBoolean("widget.${widgetId}.showRef", showRef)
            .apply()
    }

    private fun push() {
        val mgr = AppWidgetManager.getInstance(this)
        val opts = mgr.getAppWidgetOptions(widgetId) ?: Bundle()
        mgr.updateAppWidget(
            widgetId,
            PrayersAppWidgetProvider.buildViews(
                this, widgetId, HomeWidgetPlugin.getData(this), opts
            )
        )
    }
}
