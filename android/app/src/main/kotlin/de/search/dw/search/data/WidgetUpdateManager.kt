package de.search.dw.search.data

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.Toast
import de.search.dw.search.widgets.searchbar.SearchbarWidgetProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

object WidgetUpdateManager {

    private val managerScope = CoroutineScope(Dispatchers.IO)

    fun updateGlobal(context: Context, showToast: Boolean = false) {
        managerScope.launch {
            // Kurze Verzögerung, um sicherzustellen, dass Writes im DataStore fertig sind
            delay(100)

            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, SearchbarWidgetProvider::class.java)
                val widgetIds = appWidgetManager.getAppWidgetIds(componentName)

                if (widgetIds.isNotEmpty()) {
                    val updateIntent = Intent(context, SearchbarWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                    }
                    context.sendBroadcast(updateIntent)

                    if (showToast) {
                        withContext(Dispatchers.Main) {
                            Toast.makeText(context, "Widget aktualisiert!", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
