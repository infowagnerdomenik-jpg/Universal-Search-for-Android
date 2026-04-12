package de.search.dw.search

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class SearchTileService : TileService() {

    companion object {
        const val PREFS_NAME = "qs_tile_prefs"
        const val KEY_TILE_ADDED = "tile_added"
    }

    override fun onTileAdded() {
        super.onTileAdded()
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_TILE_ADDED, true).apply()
    }

    override fun onTileRemoved() {
        super.onTileRemoved()
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_TILE_ADDED, false).apply()
    }

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_ACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        startActivityAndCollapse(pendingIntent)
    }
}
