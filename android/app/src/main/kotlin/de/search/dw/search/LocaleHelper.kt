package de.search.dw.search

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

object LocaleHelper {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_LANGUAGE = "flutter.app_language"

    fun wrap(base: Context): Context {
        val prefs = base.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val langCode = prefs.getString(KEY_LANGUAGE, "auto") ?: "auto"
        if (langCode == "auto") return base
        val locale = Locale(langCode)
        val config = Configuration(base.resources.configuration)
        config.setLocale(locale)
        return base.createConfigurationContext(config)
    }
}
