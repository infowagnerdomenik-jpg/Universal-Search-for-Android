package de.search.dw.search.ui

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import de.search.dw.search.LocaleHelper
import androidx.activity.compose.setContent
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

import androidx.activity.enableEdgeToEdge

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.core.view.WindowCompat
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import android.view.HapticFeedbackConstants
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

import de.search.dw.search.R
import de.search.dw.search.data.GlobalWidgetPrefs
import de.search.dw.search.data.WidgetUpdateManager
import de.search.dw.search.ui.components.WidgetLivePreview

import com.example.design_engine.layer3_logic.AppTheme
import com.example.design_engine.layer3_logic.DesignEngineController
import com.example.design_engine.layer3_logic.ThemeMode
import com.example.design_engine.layer4_ui.DesignEngineUI

fun getVordergrundAlpha(sliderWert: Float): Float {
    val gerundet = (sliderWert * 10f).roundToInt() / 10f
    return when (gerundet) {
        -0.1f -> 0.00f
        0.0f  -> 0.10f
        0.1f  -> 0.20f
        0.2f  -> 0.30f
        0.3f  -> 0.40f
        0.4f  -> 0.50f
        0.5f  -> 0.60f
        0.6f  -> 0.70f
        0.7f  -> 0.80f
        0.8f  -> 0.90f
        else  -> 1.00f
    }
}

fun getHintergrundAlpha(sliderWert: Float): Float {
    val gerundet = (sliderWert * 10f).roundToInt() / 10f
    return when (gerundet) {
        -0.1f -> 0.00f
        0.0f  -> 0.00f
        0.1f  -> 0.10f
        0.2f  -> 0.20f
        0.3f  -> 0.30f
        0.4f  -> 0.40f
        0.5f  -> 0.50f
        0.6f  -> 0.60f
        0.7f  -> 0.70f
        0.8f  -> 0.80f
        0.9f  -> 0.90f
        else  -> 1.00f
    }
}

class ThemeActivity : ComponentActivity() {

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrap(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(android.graphics.Color.TRANSPARENT))
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WALLPAPER)

        enableEdgeToEdge()

        DesignEngineController.init(applicationContext)

        setContent {
            ThemeControlScreen(onBackClick = { finish() })
        }
    }

    override fun finish() {
        super.finish()
        if (android.os.Build.VERSION.SDK_INT >= 34) {
            overrideActivityTransition(
                Activity.OVERRIDE_TRANSITION_CLOSE,
                R.anim.stay,
                android.R.anim.fade_out
            )
        } else {
            @Suppress("DEPRECATION")
            overridePendingTransition(R.anim.stay, android.R.anim.fade_out)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThemeControlScreen(onBackClick: () -> Unit) {
    val context = LocalContext.current
    val view = LocalView.current
    val systemInDark = isSystemInDarkTheme()
    val scope = rememberCoroutineScope()

    val isWidgetDark = when (DesignEngineController.widgetThemeMode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> systemInDark
    }

    SideEffect {
        WindowCompat.getInsetsController((view.context as Activity).window, view)
            .isAppearanceLightStatusBars = !isWidgetDark
    }

    LaunchedEffect(isWidgetDark) {
        if (!isWidgetDark) {
            DesignEngineController.widgetIsAmoled = false
        }
    }

    val ebg = DesignEngineUI.ewbackground(context)
    val esv = DesignEngineUI.ewsurfacevariant(context)
    val ep = DesignEngineUI.ewprimary(context)
    val eonbg = DesignEngineUI.ewonbackground(context)
    val eonsv = DesignEngineUI.ewonsurfacevariant(context)

    val isNoBackground by GlobalWidgetPrefs.getNoBackgroundEnabled(context).collectAsState(initial = false)
    val tintAlpha by GlobalWidgetPrefs.getTintAlpha(context).collectAsState(initial = 0.6f)

    val widgetHinten = if (isWidgetDark && DesignEngineController.widgetIsAmoled) {
        Color.Black
    } else {
        DesignEngineUI.ewonprimary(context)
    }

    val widgetVorne = DesignEngineUI.ewsurfacecontainer(context)
    val widgetAccent = DesignEngineUI.ewonprimarycontainer(context)

    Scaffold(
        containerColor = Color.Transparent,
        modifier = Modifier
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawBehind { drawRect(ebg) },
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.theme_screen_title), color = eonbg, fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = { view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY); onBackClick() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(id = R.string.navigate_back_description), tint = eonbg)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = {
                    view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                    scope.launch {
                        val vAlpha = getVordergrundAlpha(tintAlpha)
                        val hAlpha = if (isNoBackground) 0.0f else getHintergrundAlpha(tintAlpha)

                        val finalBgColor = widgetVorne.copy(alpha = vAlpha).toArgb()
                        val finalRingColor = widgetHinten.copy(alpha = hAlpha).toArgb()
                        val finalAccentColor = widgetAccent.toArgb()

                        GlobalWidgetPrefs.saveFinalColors(context, finalBgColor, finalRingColor, finalAccentColor)
                        WidgetUpdateManager.updateGlobal(context, showToast = true)
                    }
                },
                containerColor = ep,
                contentColor = esv,
                icon = { Icon(Icons.Default.Check, null) },
                text = { Text(stringResource(id = R.string.button_apply), fontWeight = FontWeight.SemiBold) }
            )
        }
    ) { padding ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .widthIn(max = 600.dp)
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(160.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .drawBehind {
                            drawRect(color = Color.Transparent, blendMode = BlendMode.Clear)
                            drawRect(color = Color.Black.copy(alpha = 0.15f))
                        },
                    contentAlignment = Alignment.Center
                ) {
                    WidgetLivePreview()
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                SettingsStackedCards(esv, ep, eonbg, eonsv, systemInDark)
                Spacer(modifier = Modifier.height(100.dp))
            }
        }
    }
}

@Composable
fun getPreviewColorForTheme(theme: AppTheme, isWidgetDark: Boolean): Color {
    val context = LocalContext.current
    return when (theme) {
        AppTheme.BLUE     -> if (!isWidgetDark) Color(0xFF2B4779) else Color(0xFFD3E3FD)
        AppTheme.GREEN    -> if (!isWidgetDark) Color(0xFF005235) else Color(0xFF5CFCB6)
        AppTheme.RED      -> if (!isWidgetDark) Color(0xFF930000) else Color(0xFFFFDAD4)
        AppTheme.STANDARD -> if (!isWidgetDark) Color(0xFFE2E2E2) else Color(0xFF262626)
        AppTheme.NOTHING  -> if (!isWidgetDark) Color(0xFFE2E2E2) else Color(0xFF303030)
        AppTheme.SYSTEM   -> if (!isWidgetDark) DesignEngineUI.ewprimaryLight(context) else DesignEngineUI.ewprimaryDark(context)
    }
}

@Composable
fun SettingsStackedCards(esv: Color, ep: Color, eonbg: Color, eonsv: Color, systemInDark: Boolean) {
    val context = LocalContext.current
    val view = LocalView.current
    val scope = rememberCoroutineScope()

    val sortedThemes = listOf(AppTheme.SYSTEM, AppTheme.STANDARD, AppTheme.BLUE, AppTheme.GREEN, AppTheme.RED, AppTheme.NOTHING)
    val currentTheme = DesignEngineController.widgetTheme
    val fixedLightColor = getPreviewColorForTheme(currentTheme, false)
    val fixedDarkColor = getPreviewColorForTheme(currentTheme, true)

    val isNewDesign by GlobalWidgetPrefs.getMusicEnabled(context).collectAsState(initial = false)
    val isNoBackground by GlobalWidgetPrefs.getNoBackgroundEnabled(context).collectAsState(initial = false)
    val cornerRadius by GlobalWidgetPrefs.getCornerRadius(context).collectAsState(initial = 30)
    val tintAlpha by GlobalWidgetPrefs.getTintAlpha(context).collectAsState(initial = 0.6f)

    val isWidgetDark = when (DesignEngineController.widgetThemeMode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> systemInDark
    }

    val topShape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp, bottomStart = 4.dp, bottomEnd = 4.dp)
    val midShape = RoundedCornerShape(4.dp)
    val botShape = RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp, bottomStart = 28.dp, bottomEnd = 28.dp)
    val singleShape = RoundedCornerShape(28.dp)

    var showCornerRadiusInfo by remember { mutableStateOf(false) }

    if (showCornerRadiusInfo) {
        AlertDialog(
            onDismissRequest = { showCornerRadiusInfo = false },
            title = {
                Text(
                    text = stringResource(id = R.string.theme_corner_radius_dialog_title),
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 20.sp
                )
            },
            text = {
                Text(
                    text = stringResource(id = R.string.theme_corner_radius_dialog_text),
                    fontSize = 15.sp,
                    lineHeight = 22.sp
                )
            },
            confirmButton = {
                TextButton(onClick = { showCornerRadiusInfo = false }) {
                    Text(stringResource(id = R.string.theme_corner_radius_dialog_confirm), color = ep, fontWeight = FontWeight.Bold)
                }
            },
            containerColor = esv,
            titleContentColor = eonbg,
            textContentColor = eonsv
        )
    }

    Column(modifier = Modifier.fillMaxWidth().widthIn(max = 600.dp).padding(horizontal = 16.dp)) {

        Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, topShape).clip(topShape).background(esv).padding(vertical = 16.dp)) {
            Column {
                Text(stringResource(id = R.string.theme_section_color), color = eonbg, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = 20.dp, end = 20.dp, bottom = 8.dp))
                Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 12.dp)) {
                    sortedThemes.forEach { theme ->
                        val themeColor = getPreviewColorForTheme(theme, isWidgetDark)
                        val labelRes = when (theme) {
                            AppTheme.SYSTEM -> R.string.theme_system
                            AppTheme.STANDARD -> R.string.theme_standard
                            AppTheme.BLUE -> R.string.theme_blue
                            AppTheme.GREEN -> R.string.theme_green
                            AppTheme.RED -> R.string.theme_red
                            AppTheme.NOTHING -> R.string.theme_nothing
                        }
                        ColorCircleItem(
                            label = stringResource(id = labelRes),
                            color = themeColor,
                            isSelected = DesignEngineController.widgetTheme == theme,
                            textColor = eonsv,
                            selectionColor = ep
                        ) { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); DesignEngineController.widgetTheme = theme }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(3.dp))

        val modeShape = if (isWidgetDark) midShape else botShape
        Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, modeShape).clip(modeShape).background(esv).padding(vertical = 16.dp)) {
            Column {
                Text(stringResource(id = R.string.theme_section_brightness), color = eonbg, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = 20.dp, end = 20.dp, bottom = 8.dp))
                Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp)) {
                    LightModeCircleItem(stringResource(id = R.string.theme_mode_auto_short), DesignEngineController.widgetThemeMode == ThemeMode.SYSTEM, true, fixedLightColor, fixedDarkColor, eonsv, ep) { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); DesignEngineController.widgetThemeMode = ThemeMode.SYSTEM }
                    LightModeCircleItem(stringResource(id = R.string.theme_mode_day_short), DesignEngineController.widgetThemeMode == ThemeMode.LIGHT, false, fixedLightColor, fixedLightColor, eonsv, ep) { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); DesignEngineController.widgetThemeMode = ThemeMode.LIGHT }
                    LightModeCircleItem(stringResource(id = R.string.theme_mode_night_short), DesignEngineController.widgetThemeMode == ThemeMode.DARK, false, fixedDarkColor, fixedDarkColor, eonsv, ep) { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); DesignEngineController.widgetThemeMode = ThemeMode.DARK }
                }
            }
        }

        if (isWidgetDark) {
            Spacer(modifier = Modifier.height(3.dp))
            Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, botShape).clip(botShape).background(esv).padding(horizontal = 20.dp, vertical = 12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
                        Text(stringResource(id = R.string.theme_amoled_title), color = eonbg, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                        Text(stringResource(id = R.string.theme_amoled_subtitle), color = eonsv, fontSize = 13.sp, fontWeight = FontWeight.Normal)
                    }
                    Switch(
                        checked = DesignEngineController.widgetIsAmoled,
                        onCheckedChange = { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); DesignEngineController.widgetIsAmoled = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = esv, checkedTrackColor = ep,
                            uncheckedThumbColor = eonsv, uncheckedTrackColor = eonbg.copy(alpha = 0.1f),
                            uncheckedBorderColor = Color.Transparent
                        )
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, singleShape).clip(singleShape).background(esv).padding(horizontal = 20.dp, vertical = 12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
                    Text(stringResource(id = R.string.theme_new_design_title), color = eonbg, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                    Text(stringResource(id = R.string.theme_new_design_subtitle), color = eonsv, fontSize = 13.sp, fontWeight = FontWeight.Normal)
                }
                Switch(
                    checked = isNewDesign,
                    onCheckedChange = { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); scope.launch { GlobalWidgetPrefs.saveMusicEnabled(context, it) } },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = esv, checkedTrackColor = ep,
                        uncheckedThumbColor = eonsv, uncheckedTrackColor = eonbg.copy(alpha = 0.1f),
                        uncheckedBorderColor = Color.Transparent
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, topShape).clip(topShape).background(esv).padding(horizontal = 20.dp, vertical = 12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
                    Text(stringResource(id = R.string.theme_no_background_title), color = eonbg, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                    Text(stringResource(id = R.string.theme_no_background_subtitle), color = eonsv, fontSize = 13.sp, fontWeight = FontWeight.Normal)
                }
                Switch(
                    checked = isNoBackground,
                    onCheckedChange = { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); scope.launch { GlobalWidgetPrefs.saveNoBackgroundEnabled(context, it) } },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = esv, checkedTrackColor = ep,
                        uncheckedThumbColor = eonsv, uncheckedTrackColor = eonbg.copy(alpha = 0.1f),
                        uncheckedBorderColor = Color.Transparent
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(3.dp))

        Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, midShape).clip(midShape).background(esv).padding(horizontal = 20.dp, vertical = 14.dp)) {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(stringResource(id = R.string.theme_transparency_title), color = eonbg, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                    Text(String.format("%.2f", tintAlpha), color = eonsv, fontSize = 13.sp, fontWeight = FontWeight.Normal)
                }
                Spacer(modifier = Modifier.height(4.dp))
                Slider(
                    value = tintAlpha,
                    onValueChange = { scope.launch { GlobalWidgetPrefs.saveTintAlpha(context, it) } },
                    valueRange = -0.10f..1.00f,
                    colors = SliderDefaults.colors(
                        thumbColor = ep,
                        activeTrackColor = ep,
                        inactiveTrackColor = eonbg.copy(alpha = 0.1f)
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(3.dp))

        val eerror = MaterialTheme.colorScheme.error
        val cornerSliderColor = if (cornerRadius < 20) eerror else ep
        val cornerInactiveTrackColor = if (cornerRadius < 20) eerror.copy(alpha = 0.1f) else eonbg.copy(alpha = 0.1f)
        val infoIconColor = if (cornerRadius < 20) eerror else eonsv

        Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, botShape).clip(botShape).background(esv).padding(horizontal = 20.dp, vertical = 14.dp)) {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(stringResource(id = R.string.theme_corner_radius_title), color = eonbg, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("$cornerRadius", color = eonsv, fontSize = 13.sp, fontWeight = FontWeight.Normal)
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            imageVector = Icons.Outlined.Info,
                            contentDescription = stringResource(id = R.string.theme_corner_radius_info_desc),
                            tint = infoIconColor,
                            modifier = Modifier
                                .size(24.dp)
                                .clip(CircleShape)
                                .clickable { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); showCornerRadiusInfo = true }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                Slider(
                    value = cornerRadius.toFloat(),
                    onValueChange = { scope.launch { GlobalWidgetPrefs.saveCornerRadius(context, it.toInt()) } },
                    valueRange = 0f..30f,
                    colors = SliderDefaults.colors(
                        thumbColor = cornerSliderColor,
                        activeTrackColor = cornerSliderColor,
                        inactiveTrackColor = cornerInactiveTrackColor
                    )
                )
            }
        }
    }
}

@Composable
fun ColorCircleItem(
    label: String,
    color: Color,
    isSelected: Boolean,
    textColor: Color,
    selectionColor: Color,
    onTap: () -> Unit
) {
    val innerShape = if (isSelected) RoundedCornerShape(16.dp) else CircleShape
    val outerShape = if (isSelected) RoundedCornerShape(24.dp) else CircleShape

    Box(
        modifier = Modifier.width(80.dp).clickable(onClick = onTap).padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(modifier = Modifier.size(64.dp), contentAlignment = Alignment.Center) {
                if (isSelected) {
                    Box(modifier = Modifier.fillMaxSize().border(3.dp, selectionColor, outerShape))
                }
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(innerShape)
                        .background(color)
                        .border(1.dp, Color.Black.copy(alpha = 0.1f), innerShape)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = label,
                color = textColor,
                fontSize = 12.sp,
                fontWeight = FontWeight.Normal,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun LightModeCircleItem(
    label: String,
    isSelected: Boolean,
    isSplit: Boolean,
    fillColorLight: Color,
    fillColorDark: Color,
    textColor: Color,
    selectionColor: Color,
    onTap: () -> Unit
) {
    val innerShape = if (isSelected) RoundedCornerShape(16.dp) else CircleShape
    val outerShape = if (isSelected) RoundedCornerShape(24.dp) else CircleShape

    Box(
        modifier = Modifier.width(80.dp).clickable(onClick = onTap).padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(modifier = Modifier.size(64.dp), contentAlignment = Alignment.Center) {
                if (isSelected) {
                    Box(modifier = Modifier.fillMaxSize().border(3.dp, selectionColor, outerShape))
                }
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(innerShape)
                        .background(
                            if (isSplit) Brush.horizontalGradient(
                                0.0f to fillColorLight,
                                0.5f to fillColorLight,
                                0.5f to fillColorDark,
                                1.0f to fillColorDark
                            ) else Brush.linearGradient(listOf(fillColorLight, fillColorLight))
                        )
                        .border(1.dp, Color.Black.copy(alpha = 0.1f), innerShape)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = label,
                color = textColor,
                fontSize = 12.sp,
                fontWeight = FontWeight.Normal,
                textAlign = TextAlign.Center
            )
        }
    }
}
