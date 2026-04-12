package de.search.dw.search

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import android.view.HapticFeedbackConstants
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.view.WindowCompat
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.launch

import de.search.dw.search.R
import de.search.dw.search.data.GlobalWidgetPrefs
import de.search.dw.search.data.WidgetUpdateManager
import de.search.dw.search.ui.ThemeActivity
import de.search.dw.search.ui.components.WidgetLivePreview

import com.example.design_engine.layer4_ui.DesignEngineUI

class SearchbarSettingsActivity : ComponentActivity() {

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.wrap(newBase))
    }

    private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
    private var isWidgetConfigureContext: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(android.graphics.Color.TRANSPARENT))
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WALLPAPER)

        enableEdgeToEdge()

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        isWidgetConfigureContext = appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID

        if (isWidgetConfigureContext) {
            setResult(RESULT_CANCELED)
        }

        setContent {
            SearchbarSettingsRoot(
                isWidgetConfigureContext = isWidgetConfigureContext,
                onApplyClick = { handleActivityFinish(userConfirmed = true) },
                onBackClick = { handleActivityFinish(userConfirmed = false) }
            )
        }
    }

    private fun handleActivityFinish(userConfirmed: Boolean) {
        if (isWidgetConfigureContext && userConfirmed) {
            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
        } else {
            setResult(RESULT_CANCELED)
        }
        finish()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchbarSettingsRoot(
    isWidgetConfigureContext: Boolean,
    onApplyClick: () -> Unit,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val view = LocalView.current
    val scope = rememberCoroutineScope()

    val cBackground = DesignEngineUI.efbackground
    val cSurface = DesignEngineUI.efsurfacevariant
    val cText = DesignEngineUI.efonbackground
    val cTextSub = DesignEngineUI.efonsurfacevariant
    val cAccent = DesignEngineUI.efprimary

    val isLightBackground = cBackground.red * 0.299f + cBackground.green * 0.587f + cBackground.blue * 0.114f > 0.5f
    SideEffect {
        WindowCompat.getInsetsController((view.context as Activity).window, view)
            .isAppearanceLightStatusBars = isLightBackground
    }

    var tempVoiceEnabled by remember { mutableStateOf(false) }
    var tempLensEnabled by remember { mutableStateOf(true) }
    var tempGeminiEnabled by remember { mutableStateOf(false) }
    var tempMusicEnabled by remember { mutableStateOf(true) }
    var tempCirclePillMode by remember { mutableStateOf("music") }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        GlobalWidgetPrefs.getVoiceSearchEnabled(context).take(1).collect { tempVoiceEnabled = it }
        GlobalWidgetPrefs.getLensEnabled(context).take(1).collect { tempLensEnabled = it }
        GlobalWidgetPrefs.getGeminiEnabled(context).take(1).collect { tempGeminiEnabled = it }
        GlobalWidgetPrefs.getMusicEnabled(context).take(1).collect { tempMusicEnabled = it }
        GlobalWidgetPrefs.getCirclePillMode(context).take(1).collect { tempCirclePillMode = it }
        isLoading = false
    }

    Scaffold(
        containerColor = Color.Transparent,
        modifier = Modifier
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawBehind { drawRect(cBackground) },
        topBar = {
            TopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    scrolledContainerColor = Color.Transparent,
                    titleContentColor = cText,
                    navigationIconContentColor = cText
                ),
                title = {
                    Text(
                        stringResource(id = R.string.searchbar_detail_screen_title),
                        fontWeight = FontWeight.SemiBold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(id = R.string.navigate_back_description)
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            if (!isLoading) {
                ExtendedFloatingActionButton(
                    onClick = {
                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        scope.launch {
                            GlobalWidgetPrefs.saveVoiceSearchEnabled(context, tempVoiceEnabled)
                            GlobalWidgetPrefs.saveLensEnabled(context, tempLensEnabled)
                            GlobalWidgetPrefs.saveGeminiEnabled(context, tempGeminiEnabled)
                            GlobalWidgetPrefs.saveMusicEnabled(context, tempMusicEnabled)
                            GlobalWidgetPrefs.saveCirclePillMode(context, tempCirclePillMode)

                            WidgetUpdateManager.updateGlobal(context, showToast = true)

                            onApplyClick()
                        }
                    },
                    containerColor = cAccent,
                    contentColor = cSurface,
                    icon = { Icon(Icons.Default.Check, null) },
                    text = { Text(stringResource(id = R.string.button_apply), fontWeight = FontWeight.SemiBold) }
                )
            }
        }
    ) { innerPadding ->
        if (isLoading) {
            Box(Modifier.fillMaxSize().padding(innerPadding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = cAccent)
            }
        } else {
            SearchbarSettingsPageContent(
                modifier = Modifier.padding(innerPadding),
                isWidgetConfigureContext = isWidgetConfigureContext,
                cSurface = cSurface,
                cText = cText,
                cTextSub = cTextSub,
                cAccent = cAccent,
                cBackground = cBackground,
                voiceEnabled = tempVoiceEnabled,
                onVoiceChange = { tempVoiceEnabled = it },
                lensEnabled = tempLensEnabled,
                onLensChange = { tempLensEnabled = it },
                geminiEnabled = tempGeminiEnabled,
                onGeminiChange = { tempGeminiEnabled = it },
                musicEnabled = tempMusicEnabled,
                onMusicChange = { tempMusicEnabled = it },
                circlePillMode = tempCirclePillMode,
                onCirclePillModeChange = { tempCirclePillMode = it }
            )
        }
    }
}

@Composable
fun SearchbarSettingsPageContent(
    modifier: Modifier = Modifier,
    isWidgetConfigureContext: Boolean,
    cSurface: Color,
    cText: Color,
    cTextSub: Color,
    cAccent: Color,
    cBackground: Color,
    voiceEnabled: Boolean,
    onVoiceChange: (Boolean) -> Unit,
    lensEnabled: Boolean,
    onLensChange: (Boolean) -> Unit,
    geminiEnabled: Boolean,
    onGeminiChange: (Boolean) -> Unit,
    musicEnabled: Boolean,
    onMusicChange: (Boolean) -> Unit,
    circlePillMode: String,
    onCirclePillModeChange: (String) -> Unit
) {
    val context = LocalContext.current
    val view = LocalView.current
    val customIconSize = 40.dp

    val topShape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp, bottomStart = 4.dp, bottomEnd = 4.dp)
    val midShape = RoundedCornerShape(4.dp)
    val botShape = RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp, bottomStart = 28.dp, bottomEnd = 28.dp)
    val singleShape = RoundedCornerShape(28.dp)

    var showCirclePillDialog by remember { mutableStateOf(false) }

    if (showCirclePillDialog) {
        Dialog(onDismissRequest = { showCirclePillDialog = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(28.dp))
                    .background(cSurface)
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    stringResource(id = R.string.settings_new_design_icon_dialog_title),
                    fontWeight = FontWeight.SemiBold,
                    color = cText,
                    style = MaterialTheme.typography.titleLarge
                )
                Spacer(Modifier.height(20.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    listOf(
                        Triple("music", stringResource(id = R.string.settings_new_design_icon_music), null as Int?),
                        Triple("maps", stringResource(id = R.string.settings_new_design_icon_maps), R.drawable.google_maps_icon_2020_white)
                    ).forEach { (mode, label, iconRes) ->
                        val isSelected = circlePillMode == mode
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(20.dp))
                                .background(if (isSelected) cAccent.copy(alpha = 0.15f) else cText.copy(alpha = 0.06f))
                                .then(
                                    if (isSelected) Modifier
                                        .shadow(0.dp, RoundedCornerShape(20.dp))
                                    else Modifier
                                )
                                .clickable {
                                    view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                                    onCirclePillModeChange(mode)
                                    showCirclePillDialog = false
                                }
                                .padding(2.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            // Accent border when selected
                            if (isSelected) {
                                Box(
                                    modifier = Modifier
                                        .matchParentSize()
                                        .clip(RoundedCornerShape(19.dp))
                                        .background(Color.Transparent)
                                        .then(
                                            Modifier.shadow(0.dp)
                                        )
                                )
                            }
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center,
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Icon(
                                    painter = painterResource(
                                        id = iconRes ?: R.drawable.music_note_48dp_ffffff_fill0_wght700_grad0_opsz48
                                    ),
                                    contentDescription = null,
                                    tint = if (isSelected) cAccent else cText.copy(alpha = 0.7f),
                                    modifier = Modifier.size(48.dp)
                                )
                                Spacer(Modifier.height(12.dp))
                                Text(
                                    label,
                                    color = if (isSelected) cAccent else cText.copy(alpha = 0.7f),
                                    style = MaterialTheme.typography.labelLarge,
                                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(top = 10.dp)
    ) {

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .height(160.dp)
                .clip(RoundedCornerShape(16.dp))
                .drawBehind {
                    drawRect(color = Color.Transparent, blendMode = BlendMode.Clear)
                    drawRect(color = Color.Black.copy(alpha = 0.15f))
                },
            contentAlignment = Alignment.Center
        ) {
            WidgetLivePreview(
                voiceEnabledOverride = voiceEnabled,
                lensEnabledOverride = lensEnabled,
                geminiEnabledOverride = geminiEnabled,
                musicEnabledOverride = musicEnabled,
                circlePillModeOverride = circlePillMode
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
        ) {

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, singleShape)
                    .clip(singleShape)
                    .background(cSurface)
                    .clickable {
                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        val intent = Intent(context, ThemeActivity::class.java)
                        context.startActivity(intent)
                        if (context is Activity) {
                            if (android.os.Build.VERSION.SDK_INT >= 34) {
                                context.overrideActivityTransition(
                                    Activity.OVERRIDE_TRANSITION_OPEN,
                                    android.R.anim.fade_in,
                                    R.anim.stay
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                context.overridePendingTransition(android.R.anim.fade_in, R.anim.stay)
                            }
                        }
                    }
            ) {
                SettingsTile(
                    iconPainter = painterResource(R.drawable.ic_palette),
                    title = stringResource(id = R.string.settings_widget_design_title),
                    subtitle = stringResource(id = R.string.settings_widget_design_subtitle),
                    showChevron = true,
                    textColor = cText
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
            SectionHeader(stringResource(id = R.string.settings_section_icons), textColor = cText)

            Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, singleShape).clip(singleShape).background(cSurface)) {
                SettingsTile(
                    iconPainter = painterResource(id = R.drawable.ic_lens_white),
                    title = stringResource(id = R.string.settings_google_lens_title),
                    subtitle = stringResource(id = R.string.settings_google_lens_subtitle),
                    textColor = cText,
                    iconTint = cText,
                    iconSize = 32.dp,
                    trailingContent = {
                        Switch(
                            checked = lensEnabled,
                            onCheckedChange = { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); onLensChange(it) },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = cBackground,
                                checkedTrackColor = cAccent,
                                uncheckedTrackColor = cText.copy(alpha = 0.1f),
                                uncheckedThumbColor = cText.copy(alpha = 0.6f),
                                uncheckedBorderColor = Color.Transparent
                            )
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
            SectionHeader(stringResource(id = R.string.theme_new_design_title), textColor = cText)

            Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, topShape).clip(topShape).background(cSurface)) {
                SettingsTile(
                    iconPainter = painterResource(R.drawable.ic_android_robot),
                    title = stringResource(id = R.string.theme_new_design_title),
                    subtitle = stringResource(id = R.string.theme_new_design_subtitle),
                    textColor = cText,
                    iconTint = cText,
                    iconSize = 32.dp,
                    trailingContent = {
                        Switch(
                            checked = musicEnabled,
                            onCheckedChange = { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); onMusicChange(it) },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = cBackground,
                                checkedTrackColor = cAccent,
                                uncheckedTrackColor = cText.copy(alpha = 0.1f),
                                uncheckedThumbColor = cText.copy(alpha = 0.6f),
                                uncheckedBorderColor = Color.Transparent
                            )
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(3.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, botShape)
                    .clip(botShape)
                    .background(cSurface)
                    .then(if (!musicEnabled) Modifier.alpha(0.4f) else Modifier)
                    .clickable(enabled = musicEnabled) { view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY); showCirclePillDialog = true }
            ) {
                SettingsTile(
                    iconPainter = painterResource(
                        id = if (circlePillMode == "maps")
                            R.drawable.google_maps_icon_2020_white
                        else
                            R.drawable.music_note_48dp_ffffff_fill0_wght700_grad0_opsz48
                    ),
                    iconVector = null,
                    title = if (circlePillMode == "maps")
                        stringResource(id = R.string.settings_new_design_icon_maps)
                    else
                        stringResource(id = R.string.settings_new_design_icon_music),
                    subtitle = stringResource(id = R.string.settings_new_design_icon_subtitle),
                    textColor = cText,
                    iconTint = cText,
                    iconSize = 32.dp,
                    showChevron = true
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
            SectionHeader(stringResource(id = R.string.voice_search_title), textColor = cText)

            Box(modifier = Modifier.fillMaxWidth().shadow(1.dp, topShape).clip(topShape).background(cSurface)) {
                SettingsTile(
                    iconPainter = painterResource(id = R.drawable.ic_mic_foreground),
                    title = stringResource(id = R.string.voice_search_title),
                    subtitle = stringResource(id = R.string.settings_voice_search_subtitle),
                    textColor = cText,
                    iconTint = cText,
                    iconSize = customIconSize,
                    trailingContent = {
                        Switch(
                            checked = voiceEnabled,
                            onCheckedChange = { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); onVoiceChange(it) },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = cBackground,
                                checkedTrackColor = cAccent,
                                uncheckedTrackColor = cText.copy(alpha = 0.1f),
                                uncheckedThumbColor = cText.copy(alpha = 0.6f),
                                uncheckedBorderColor = Color.Transparent
                            )
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(3.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, botShape)
                    .clip(botShape)
                    .background(cSurface)
                    .then(if (!voiceEnabled) Modifier.alpha(0.4f) else Modifier)
            ) {
                SettingsTile(
                    iconPainter = painterResource(id = R.drawable.google_gemini_no_color),
                    title = stringResource(id = R.string.settings_gemini_title),
                    subtitle = stringResource(id = R.string.settings_gemini_subtitle),
                    textColor = cText,
                    iconTint = cText,
                    iconSize = 32.dp,
                    trailingContent = {
                        Switch(
                            checked = geminiEnabled && voiceEnabled,
                            onCheckedChange = if (voiceEnabled) { { view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK); onGeminiChange(it) } } else null,
                            enabled = voiceEnabled,
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = cBackground,
                                checkedTrackColor = cAccent,
                                uncheckedTrackColor = cText.copy(alpha = 0.1f),
                                uncheckedThumbColor = cText.copy(alpha = 0.6f),
                                uncheckedBorderColor = Color.Transparent,
                                disabledCheckedThumbColor = cBackground,
                                disabledCheckedTrackColor = cAccent,
                                disabledUncheckedThumbColor = cText.copy(alpha = 0.6f),
                                disabledUncheckedTrackColor = cText.copy(alpha = 0.1f),
                                disabledUncheckedBorderColor = Color.Transparent
                            )
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(100.dp))
        }
    }
}

@Composable
fun SectionHeader(text: String, textColor: Color) {
    Text(
        text = text.uppercase(),
        style = MaterialTheme.typography.labelMedium.copy(
            letterSpacing = 1.0.sp,
            fontWeight = FontWeight.Bold
        ),
        color = textColor.copy(alpha = 0.6f),
        modifier = Modifier.padding(start = 16.dp, bottom = 8.dp)
    )
}

@Composable
fun SettingsTile(
    title: String,
    textColor: Color,
    subtitle: String? = null,
    iconVector: ImageVector? = null,
    iconPainter: Painter? = null,
    customLeadingIcon: (@Composable () -> Unit)? = null,
    showChevron: Boolean = false,
    trailingContent: (@Composable () -> Unit)? = null,
    iconTint: Color = textColor,
    iconSize: Dp = 24.dp
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier.size(36.dp),
            contentAlignment = Alignment.Center
        ) {
            if (customLeadingIcon != null) {
                customLeadingIcon()
            } else if (iconPainter != null) {
                Icon(
                    painter = iconPainter,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(iconSize)
                )
            } else if (iconVector != null) {
                Icon(
                    imageVector = iconVector,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(iconSize)
                )
            }
        }

        Spacer(modifier = Modifier.width(16.dp))

        Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge.copy(
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                ),
                color = textColor
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium.copy(fontSize = 13.sp),
                    color = textColor.copy(alpha = 0.7f)
                )
            }
        }

        if (trailingContent != null) {
            trailingContent()
        } else if (showChevron) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = textColor.copy(alpha = 0.5f)
            )
        }
    }
}
