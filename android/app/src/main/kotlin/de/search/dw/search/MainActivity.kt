package de.search.dw.search

import android.Manifest
import android.app.StatusBarManager
import android.content.ComponentName
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Bundle
import android.provider.CalendarContract
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "de.search.dw.search/widget"
    private val QS_TILE_CHANNEL = "de.search.dw.search/qstile"
    private val CALENDAR_CHANNEL = "de.search.dw.search/calendar"
    private val FILE_CHANNEL = "de.search.dw.search/files"
    private val INTERNET_CHANNEL = "de.search.dw.search/internet"
    private val PERMISSION_CHANNEL = "de.search.dw.search/permissions"
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen().setKeepOnScreenCondition { false }
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QS_TILE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkQsTileAdded" -> {
                    val prefs = getSharedPreferences(SearchTileService.PREFS_NAME, Context.MODE_PRIVATE)
                    result.success(prefs.getBoolean(SearchTileService.KEY_TILE_ADDED, false))
                }
                "requestAddQsTile" -> {
                    val statusBarManager = getSystemService(StatusBarManager::class.java)
                    val componentName = ComponentName(this, SearchTileService::class.java)
                    val icon = Icon.createWithResource(this, R.drawable.search_48dp_ffffff_fill0_wght700_grad0_opsz48)
                    statusBarManager.requestAddTileService(
                        componentName,
                        getString(R.string.app_name),
                        icon,
                        mainExecutor
                    ) { resultCode ->
                        // 1 = TILE_ADDED, 2 = TILE_ALREADY_ADDED, 3 = TILE_NOT_ADDED
                        result.success(resultCode)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            val permission = call.argument<String>("permission") ?: ""
            when (call.method) {
                "checkPermission" -> result.success(hasCustomPermission(permission))
                "requestPermission" -> {
                    if (hasCustomPermission(permission)) result.success(true)
                    else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(permission), 200)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTERNET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkConnection" -> {
                    Thread {
                        val connected = checkInternetConnectionNative()
                        runOnUiThread { result.success(connected) }
                    }.start()
                }
                "fetchSuggestions" -> {
                    val query = call.argument<String>("query") ?: ""
                    val type = call.argument<String>("type") ?: "none"
                    Thread {
                        val suggestions = fetchSuggestionsNative(query, type)
                        runOnUiThread { result.success(suggestions) }
                    }.start()
                }
                "isCompanionInstalled" -> result.success(isInternetCompanionInstalled())
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openWidgetSettings") {
                try {
                    val intent = Intent(this, SearchbarSettingsActivity::class.java)
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Konnte Activity nicht starten: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "searchFiles" -> {
                    val query = call.argument<String>("query") ?: ""
                    result.success(searchFilesNative(query))
                }
                "openFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    openFileNative(path, result)
                }
                "getFileThumbnail" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(getFileThumbnailNative(path))
                }
                "requestFilePermissions" -> result.success(isCompanionInstalled())
                "hasFilePermissions" -> result.success(isCompanionInstalled())
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkVersion" -> result.success(android.os.Build.VERSION.SDK_INT)
                "checkPermission" -> result.success(hasCalendarPermission())
                "launchSettingsShortcut" -> {
                    val action = call.argument<String>("action")
                    if (action != null) {
                        try {
                            val intent = Intent(action)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallback = Intent(android.provider.Settings.ACTION_SETTINGS)
                                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(fallback)
                                result.success(false)
                            } catch (e2: Exception) { result.error("ERROR", e2.message, null) }
                        }
                    } else result.error("INVALID_ACTION", "Action fehlt", null)
                }
                "requestPermission" -> {
                    if (hasCalendarPermission()) result.success(true)
                    else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CALENDAR), 100)
                    }
                }
                "getFullCalendarData" -> {
                    if (hasCalendarPermission()) {
                        val data = mutableMapOf<String, Any>()
                        data["calendars"] = getNativeCalendars()
                        val start = System.currentTimeMillis() - (1000 * 60 * 60 * 24 * 7)
                        val end = System.currentTimeMillis() + (1000 * 60 * 60 * 24 * 60)
                        data["events"] = getNativeEvents(start, end, null)
                        result.success(data)
                    } else result.error("PERMISSION_DENIED", "Berechtigung fehlt", null)
                }
                "openEvent" -> {
                    val eventId = call.argument<String>("eventId")?.toLong()
                    val start = call.argument<Long>("start")
                    val end = call.argument<Long>("end")
                    if (eventId != null) {
                        try {
                            val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
                            val intent = Intent(Intent.ACTION_VIEW).setData(uri)
                            if (start != null) intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
                            if (end != null) intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) { result.error("ERROR", e.message, null) }
                    } else result.error("INVALID_ID", "ID fehlt", null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100 || requestCode == 200) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }

    private fun hasCustomPermission(permission: String): Boolean = 
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    private fun hasCalendarPermission(): Boolean = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED

    private fun isSignatureTrusted(targetPackage: String): Boolean {
        return try {
            val targetSigs = packageManager
                .getPackageInfo(targetPackage, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo?.apkContentsSigners
            val mySigs = packageManager
                .getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo?.apkContentsSigners
            targetSigs != null && mySigs != null && targetSigs.first() == mySigs.first()
        } catch (e: Exception) { false }
    }

    private fun isCompanionInstalled(): Boolean = try {
        packageManager.getPackageInfo("de.search.companion.dw", 0)
        isSignatureTrusted("de.search.companion.dw")
    } catch (e: PackageManager.NameNotFoundException) { false }

    private fun isInternetCompanionInstalled(): Boolean = try {
        packageManager.getPackageInfo("de.search.companion.internet.dw", 0)
        isSignatureTrusted("de.search.companion.internet.dw")
    } catch (e: PackageManager.NameNotFoundException) { false }

    private fun checkInternetConnectionNative(): Boolean {
        if (!isInternetCompanionInstalled()) return false
        val uri = Uri.parse("content://de.search.companion.internet.dw.provider/status")
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getInt(0) == 1
                } else false
            } ?: false
        } catch (e: Exception) { false }
    }

    private fun fetchSuggestionsNative(query: String, type: String): List<String> {
        val results = mutableListOf<String>()
        if (!isInternetCompanionInstalled()) return results
        val uri = Uri.parse("content://de.search.companion.internet.dw.provider/suggestions")
            .buildUpon()
            .appendQueryParameter("q", query)
            .appendQueryParameter("type", type)
            .build()
        
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    results.add(cursor.getString(0))
                }
            }
        } catch (e: Exception) { 
            android.util.Log.e("INTERNET_SEARCH", "Suggestion query failed: ${e.message}") 
        }
        return results
    }

    private fun searchFilesNative(query: String): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        if (!isCompanionInstalled()) return results
        val uri = Uri.parse("content://de.search.companion.dw.search/search").buildUpon().appendQueryParameter("q", query).build()
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val idIdx = cursor.getColumnIndex("id")
                val nameIdx = cursor.getColumnIndex("name")
                val pathIdx = cursor.getColumnIndex("path")
                val mimeIdx = cursor.getColumnIndex("mimeType")
                val sizeIdx = cursor.getColumnIndex("size")
                val dateIdx = cursor.getColumnIndex("dateModified")
                while (cursor.moveToNext()) {
                    val map = mutableMapOf<String, Any?>()
                    if (idIdx != -1) map["id"] = cursor.getString(idIdx)
                    if (nameIdx != -1) map["name"] = cursor.getString(nameIdx)
                    if (pathIdx != -1) map["path"] = cursor.getString(pathIdx)
                    if (mimeIdx != -1) map["mimeType"] = cursor.getString(mimeIdx)
                    if (sizeIdx != -1) map["size"] = cursor.getLong(sizeIdx)
                    if (dateIdx != -1) map["dateModified"] = cursor.getLong(dateIdx)
                    results.add(map)
                }
            }
        } catch (e: Exception) { android.util.Log.e("FILE_SEARCH", "Companion query failed: ${e.message}") }
        return results
    }

    private fun getFileThumbnailNative(path: String): ByteArray? {
        val uri = Uri.parse("content://de.search.companion.dw.search/thumbnail").buildUpon().appendQueryParameter("path", path).build()
        return try {
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (e: Exception) { null }
    }

    private fun openFileNative(path: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse("content://de.search.companion.dw.search/open").buildUpon().appendQueryParameter("path", path).build()
            
            // MIME-Typ präzise bestimmen
            val file = File(path)
            val extension = file.extension.lowercase(Locale.getDefault())
            val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "*/*"
            
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, mime)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) { result.error("OPEN_ERROR", e.message, null) }
    }

    private fun getNativeCalendars(): List<Map<String, String>> {
        val projection = arrayOf(CalendarContract.Calendars._ID, CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, CalendarContract.Calendars.ACCOUNT_NAME, CalendarContract.Calendars.OWNER_ACCOUNT)
        val calendars = mutableListOf<Map<String, String>>()
        try {
            contentResolver.query(CalendarContract.Calendars.CONTENT_URI, projection, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    calendars.add(mapOf("id" to cursor.getString(0), "name" to (cursor.getString(1) ?: "Unbenannt"), "account" to (cursor.getString(2) ?: cursor.getString(3) ?: "Lokal")))
                }
            }
        } catch (e: Exception) {}
        return calendars
    }

    private fun getNativeEvents(startMillis: Long, endMillis: Long, calendarIds: List<String>?): List<Map<String, Any?>> {
        val projection = arrayOf(CalendarContract.Instances.EVENT_ID, CalendarContract.Instances.TITLE, CalendarContract.Instances.DESCRIPTION, CalendarContract.Instances.BEGIN, CalendarContract.Instances.END, CalendarContract.Instances.EVENT_LOCATION, CalendarContract.Instances.ALL_DAY, CalendarContract.Instances.CALENDAR_ID, CalendarContract.Instances.CALENDAR_COLOR)
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, startMillis)
        ContentUris.appendId(builder, endMillis)
        val selection = if (calendarIds != null && calendarIds.isNotEmpty()) "${CalendarContract.Instances.CALENDAR_ID} IN (${calendarIds.joinToString(",")})" else null
        val events = mutableListOf<Map<String, Any?>>()
        try {
            contentResolver.query(builder.build(), projection, selection, null, "${CalendarContract.Instances.BEGIN} ASC")?.use { cursor ->
                while (cursor.moveToNext()) {
                    events.add(mapOf("id" to cursor.getString(0), "title" to cursor.getString(1), "description" to cursor.getString(2), "start" to cursor.getLong(3), "end" to cursor.getLong(4), "location" to cursor.getString(5), "allDay" to (cursor.getInt(6) == 1), "calendarId" to cursor.getString(7), "color" to cursor.getInt(8)))
                }
            }
        } catch (e: Exception) {}
        return events
    }
}
