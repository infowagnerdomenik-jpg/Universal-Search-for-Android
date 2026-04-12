package de.search.dw.search.widgets.searchbar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import de.search.dw.search.MainActivity
import de.search.dw.search.R
import de.search.dw.search.data.GlobalWidgetPrefs
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SearchbarWidgetProvider : AppWidgetProvider() {

    private val coroutineScope = CoroutineScope(Dispatchers.IO)

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidgetAsync(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidgetAsync(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        coroutineScope.launch {
            val views = RemoteViews(context.packageName, R.layout.searchbar_widget_layout)

            // Einstellungen lesen
            val isNewDesign = GlobalWidgetPrefs.getNewDesignEnabled(context).first()
            val isLensEnabled = GlobalWidgetPrefs.getLensEnabled(context).first()
            val isMicEnabled = GlobalWidgetPrefs.getVoiceSearchEnabled(context).first()
            val isMusicEnabled = GlobalWidgetPrefs.getMusicEnabled(context).first()
            val isGeminiEnabled = GlobalWidgetPrefs.getGeminiEnabled(context).first()
            val circlePillMode = GlobalWidgetPrefs.getCirclePillMode(context).first()
            val cornerRadiusDp = GlobalWidgetPrefs.getCornerRadius(context).first().toFloat()

            // Farben aus DataStore lesen
            val finalBgOuter = GlobalWidgetPrefs.getFinalRingColor(context).first() ?: Color.parseColor("#C7C7C7")
            val finalBgInner = GlobalWidgetPrefs.getFinalBgColor(context).first() ?: Color.parseColor("#E2E2E2")
            val accentColor = GlobalWidgetPrefs.getFinalAccentColor(context).first() ?: Color.parseColor("#474747")

            // UI anpassen
            views.setInt(R.id.widget_root, "setBackgroundColor", finalBgOuter)
            views.setInt(R.id.main_pill_container, "setBackgroundColor", finalBgInner)
            views.setInt(R.id.circle_pill_container, "setBackgroundColor", finalBgInner)

            // Icons einfärben
            val icons = listOf(R.id.icon_launcher, R.id.icon_mic, R.id.icon_lens, R.id.icon_plus)
            icons.forEach { views.setInt(it, "setColorFilter", accentColor) }

            // Radien setzen
            views.setViewOutlinePreferredRadius(R.id.widget_root, cornerRadiusDp, TypedValue.COMPLEX_UNIT_DIP)
            val innerRad = (cornerRadiusDp - 4f).coerceAtLeast(0f)
            views.setViewOutlinePreferredRadius(R.id.main_pill_container, innerRad, TypedValue.COMPLEX_UNIT_DIP)
            views.setViewOutlinePreferredRadius(R.id.circle_pill_container, innerRad, TypedValue.COMPLEX_UNIT_DIP)

            // Circle Pill Icon je nach Modus
            if (circlePillMode == "maps") {
                views.setImageViewResource(R.id.icon_plus, R.drawable.google_maps_icon_2020_white)
            } else {
                views.setImageViewResource(R.id.icon_plus, R.drawable.music_note_48dp_ffffff_fill0_wght700_grad0_opsz48)
            }

            // Sichtbarkeiten
            views.setViewVisibility(R.id.split_gap, if (isMusicEnabled) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.circle_pill_container, if (isMusicEnabled) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.icon_mic, if (isMicEnabled) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.mic_lens_gap, if (isMicEnabled && isLensEnabled) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.icon_lens, if (isLensEnabled) View.VISIBLE else View.GONE)

            // Mic / Gemini Icon Tausch
            if (isGeminiEnabled) {
                views.setImageViewResource(R.id.icon_mic, R.drawable.google_gemini_no_color)
            } else {
                views.setImageViewResource(R.id.icon_mic, R.drawable.mic_48dp_ffffff_fill1_wght700_grad0_opsz48)
            }

            setupIntents(context, views, circlePillMode)

            withContext(Dispatchers.Main) {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    private fun setupIntents(context: Context, views: RemoteViews, circlePillMode: String) {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        val mainPI = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), flags)
        views.setOnClickPendingIntent(R.id.widget_root, mainPI)

        val lensIntent = Intent(Intent.ACTION_MAIN).apply {
            setClassName(
                "com.google.android.googlequicksearchbox",
                "com.google.android.apps.lens.DirectLensYoutubeActivity"
            )
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        views.setOnClickPendingIntent(R.id.icon_lens, PendingIntent.getActivity(context, 1, lensIntent, flags))

        val voiceIntent = Intent(Intent.ACTION_VOICE_COMMAND)
        views.setOnClickPendingIntent(R.id.icon_mic, PendingIntent.getActivity(context, 2, voiceIntent, flags))

        val circlePillIntent = if (circlePillMode == "maps") {
            Intent().apply {
                setClassName(
                    "com.google.android.apps.maps",
                    "com.google.android.apps.maps.OpenSearchActivity"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            Intent("com.google.android.googlequicksearchbox.MUSIC_SEARCH").apply {
                setClassName(
                    "com.google.android.googlequicksearchbox",
                    "com.google.android.googlequicksearchbox.MusicSearchGatewayInternal"
                )
            }
        }
        views.setOnClickPendingIntent(
            R.id.circle_pill_container,
            PendingIntent.getActivity(context, 3, circlePillIntent, flags)
        )
    }
}
