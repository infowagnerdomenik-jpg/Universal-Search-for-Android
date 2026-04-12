package de.search.dw.search.data

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.globalDataStore by preferencesDataStore(name = "global_widget_prefs")

object GlobalWidgetPrefs {
    private val SEARCH_ENGINE = stringPreferencesKey("search_engine")
    private val VOICE_SEARCH_ENABLED = booleanPreferencesKey("voice_search_enabled")

    private val FINAL_BG_COLOR = intPreferencesKey("final_bg_color")
    private val FINAL_RING_COLOR = intPreferencesKey("final_ring_color")
    private val FINAL_ACCENT_COLOR = intPreferencesKey("final_accent_color")

    private val NEW_DESIGN_ENABLED = booleanPreferencesKey("new_design_enabled")
    private val NO_BACKGROUND_ENABLED = booleanPreferencesKey("no_background_enabled")
    private val GEMINI_ENABLED = booleanPreferencesKey("gemini_enabled")
    private val LENS_ENABLED = booleanPreferencesKey("lens_enabled")
    private val MUSIC_ENABLED = booleanPreferencesKey("music_enabled")
    private val CIRCLE_PILL_MODE = stringPreferencesKey("circle_pill_mode") // "music" | "maps"

    private val CORNER_RADIUS = intPreferencesKey("corner_radius")
    private val TINT_ALPHA = floatPreferencesKey("tint_alpha")

    // --- GETTER ---
    fun getSearchEngine(context: Context): Flow<String> = context.globalDataStore.data.map { it[SEARCH_ENGINE] ?: "engine_google_app" }
    fun getVoiceSearchEnabled(context: Context): Flow<Boolean> = context.globalDataStore.data.map { it[VOICE_SEARCH_ENABLED] ?: false }

    fun getFinalBgColor(context: Context): Flow<Int?> = context.globalDataStore.data.map { it[FINAL_BG_COLOR] }
    fun getFinalRingColor(context: Context): Flow<Int?> = context.globalDataStore.data.map { it[FINAL_RING_COLOR] }
    fun getFinalAccentColor(context: Context): Flow<Int?> = context.globalDataStore.data.map { it[FINAL_ACCENT_COLOR] }

    fun getNewDesignEnabled(context: Context): Flow<Boolean> = context.globalDataStore.data.map { it[NEW_DESIGN_ENABLED] ?: false }
    fun getNoBackgroundEnabled(context: Context): Flow<Boolean> = context.globalDataStore.data.map { it[NO_BACKGROUND_ENABLED] ?: false }
    fun getGeminiEnabled(context: Context): Flow<Boolean> = context.globalDataStore.data.map { it[GEMINI_ENABLED] ?: false }
    fun getLensEnabled(context: Context): Flow<Boolean> = context.globalDataStore.data.map { it[LENS_ENABLED] ?: true }
    fun getMusicEnabled(context: Context): Flow<Boolean> = context.globalDataStore.data.map { it[MUSIC_ENABLED] ?: true }
    fun getCirclePillMode(context: Context): Flow<String> = context.globalDataStore.data.map { it[CIRCLE_PILL_MODE] ?: "music" }

    fun getCornerRadius(context: Context): Flow<Int> = context.globalDataStore.data.map { it[CORNER_RADIUS] ?: 100 }
    fun getTintAlpha(context: Context): Flow<Float> = context.globalDataStore.data.map { it[TINT_ALPHA] ?: 0.6f }

    // --- SETTER ---
    suspend fun saveSearchEngine(context: Context, engine: String) { context.globalDataStore.edit { it[SEARCH_ENGINE] = engine } }
    suspend fun saveVoiceSearchEnabled(context: Context, enabled: Boolean) { context.globalDataStore.edit { it[VOICE_SEARCH_ENABLED] = enabled } }

    suspend fun saveFinalColors(context: Context, bg: Int, ring: Int, accent: Int) {
        context.globalDataStore.edit {
            it[FINAL_BG_COLOR] = bg
            it[FINAL_RING_COLOR] = ring
            it[FINAL_ACCENT_COLOR] = accent
        }
    }

    suspend fun saveNewDesignEnabled(context: Context, enabled: Boolean) { context.globalDataStore.edit { it[NEW_DESIGN_ENABLED] = enabled } }
    suspend fun saveNoBackgroundEnabled(context: Context, enabled: Boolean) { context.globalDataStore.edit { it[NO_BACKGROUND_ENABLED] = enabled } }
    suspend fun saveGeminiEnabled(context: Context, enabled: Boolean) { context.globalDataStore.edit { it[GEMINI_ENABLED] = enabled } }
    suspend fun saveLensEnabled(context: Context, enabled: Boolean) { context.globalDataStore.edit { it[LENS_ENABLED] = enabled } }
    suspend fun saveMusicEnabled(context: Context, enabled: Boolean) { context.globalDataStore.edit { it[MUSIC_ENABLED] = enabled } }
    suspend fun saveCirclePillMode(context: Context, mode: String) { context.globalDataStore.edit { it[CIRCLE_PILL_MODE] = mode } }

    suspend fun saveCornerRadius(context: Context, radius: Int) { context.globalDataStore.edit { it[CORNER_RADIUS] = radius } }
    suspend fun saveTintAlpha(context: Context, alpha: Float) { context.globalDataStore.edit { it[TINT_ALPHA] = alpha } }
}
