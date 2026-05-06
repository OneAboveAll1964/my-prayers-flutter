package com.shkomaghdid.myprayers.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.TextView
import com.shkomaghdid.myprayers.R
import es.antonborri.home_widget.HomeWidgetPlugin

class WidgetConfigActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

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
        wireUp()
    }

    private fun wireUp() {
        val prefs = HomeWidgetPlugin.getData(this)
        val typeGroup = findViewById<RadioGroup>(R.id.config_type)
        val themeGroup = findViewById<RadioGroup>(R.id.config_theme)
        val sizeGroup = findViewById<RadioGroup>(R.id.config_size)
        val showTr = findViewById<RadioGroup>(R.id.config_show_tr)
        val randomize = findViewById<Button>(R.id.config_randomize)
        val save = findViewById<Button>(R.id.config_save)

        val type = prefs.getString("widget.${widgetId}.type", "mix")
        when (type) {
            "ayah" -> typeGroup.check(R.id.config_type_ayah)
            "azkar" -> typeGroup.check(R.id.config_type_azkar)
            else -> typeGroup.check(R.id.config_type_mix)
        }
        val theme = prefs.getString("widget.${widgetId}.theme", "auto")
        when (theme) {
            "light" -> themeGroup.check(R.id.config_theme_light)
            "dark" -> themeGroup.check(R.id.config_theme_dark)
            else -> themeGroup.check(R.id.config_theme_auto)
        }
        val size = prefs.getString("widget.${widgetId}.size", "m")
        when (size) {
            "s" -> sizeGroup.check(R.id.config_size_s)
            "l" -> sizeGroup.check(R.id.config_size_l)
            else -> sizeGroup.check(R.id.config_size_m)
        }
        if (prefs.getBoolean("widget.${widgetId}.showTr", true)) {
            showTr.check(R.id.config_show_tr_yes)
        } else {
            showTr.check(R.id.config_show_tr_no)
        }

        randomize.setOnClickListener {
            persistTo(prefs.edit(), typeGroup, themeGroup, sizeGroup, showTr)
            WidgetRandomizer.rotate(this, widgetId)
            push()
        }

        save.setOnClickListener {
            persistTo(prefs.edit(), typeGroup, themeGroup, sizeGroup, showTr)
            push()
            val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            setResult(RESULT_OK, result)
            finish()
        }
    }

    private fun persistTo(
        editor: android.content.SharedPreferences.Editor,
        typeGroup: RadioGroup,
        themeGroup: RadioGroup,
        sizeGroup: RadioGroup,
        showTr: RadioGroup
    ) {
        val type = when (typeGroup.checkedRadioButtonId) {
            R.id.config_type_ayah -> "ayah"
            R.id.config_type_azkar -> "azkar"
            else -> "mix"
        }
        val theme = when (themeGroup.checkedRadioButtonId) {
            R.id.config_theme_light -> "light"
            R.id.config_theme_dark -> "dark"
            else -> "auto"
        }
        val size = when (sizeGroup.checkedRadioButtonId) {
            R.id.config_size_s -> "s"
            R.id.config_size_l -> "l"
            else -> "m"
        }
        val show = showTr.checkedRadioButtonId == R.id.config_show_tr_yes
        editor
            .putString("widget.${widgetId}.type", type)
            .putString("widget.${widgetId}.theme", theme)
            .putString("widget.${widgetId}.size", size)
            .putBoolean("widget.${widgetId}.showTr", show)
            .apply()
    }

    private fun push() {
        val mgr = AppWidgetManager.getInstance(this)
        mgr.updateAppWidget(widgetId,
            PrayersAppWidgetProvider.buildViews(
                this, widgetId, HomeWidgetPlugin.getData(this)
            ))
    }
}
