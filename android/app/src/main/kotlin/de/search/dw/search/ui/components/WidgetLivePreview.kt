package de.search.dw.search.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import de.search.dw.search.R
import de.search.dw.search.data.GlobalWidgetPrefs
import de.search.dw.search.ui.getVordergrundAlpha
import de.search.dw.search.ui.getHintergrundAlpha

import com.example.design_engine.layer3_logic.DesignEngineController
import com.example.design_engine.layer3_logic.ThemeMode
import com.example.design_engine.layer4_ui.DesignEngineUI

@Composable
fun WidgetLivePreview(
    voiceEnabledOverride: Boolean? = null,
    lensEnabledOverride: Boolean? = null,
    geminiEnabledOverride: Boolean? = null,
    musicEnabledOverride: Boolean? = null,
    circlePillModeOverride: String? = null
) {
    val context = LocalContext.current

    val isNewDesignDs by GlobalWidgetPrefs.getNewDesignEnabled(context).collectAsState(initial = false)
    val isGeminiEnabledDs by GlobalWidgetPrefs.getGeminiEnabled(context).collectAsState(initial = false)
    val isLensEnabledDs by GlobalWidgetPrefs.getLensEnabled(context).collectAsState(initial = true)
    val isMicEnabledDs by GlobalWidgetPrefs.getVoiceSearchEnabled(context).collectAsState(initial = true)
    val isMusicEnabledDs by GlobalWidgetPrefs.getMusicEnabled(context).collectAsState(initial = true)
    val circlePillModeDs by GlobalWidgetPrefs.getCirclePillMode(context).collectAsState(initial = "music")

    val isNewDesign = isNewDesignDs
    val isGeminiEnabled = geminiEnabledOverride ?: isGeminiEnabledDs
    val isLensEnabled = lensEnabledOverride ?: isLensEnabledDs
    val isMicEnabled = voiceEnabledOverride ?: isMicEnabledDs
    val isMusicEnabled = musicEnabledOverride ?: isMusicEnabledDs
    val circlePillMode = circlePillModeOverride ?: circlePillModeDs

    val cornerRadiusDp by GlobalWidgetPrefs.getCornerRadius(context).collectAsState(initial = 100)
    val tintAlpha by GlobalWidgetPrefs.getTintAlpha(context).collectAsState(initial = 0.6f)
    val isNoBackground by GlobalWidgetPrefs.getNoBackgroundEnabled(context).collectAsState(initial = false)

    val baseBgOuter = if (DesignEngineController.widgetIsAmoled) {
        Color.Black
    } else {
        DesignEngineUI.ewonprimary(context)
    }
    val baseBgInner = DesignEngineUI.ewsurfacecontainer(context)
    val accentColor = DesignEngineUI.ewonprimarycontainer(context)

    val vAlpha = getVordergrundAlpha(tintAlpha)
    val hAlpha = if (isNoBackground) 0.0f else getHintergrundAlpha(tintAlpha)
    val bgColorOuter = baseBgOuter.copy(alpha = hAlpha)
    val bgColorInner = baseBgInner.copy(alpha = vAlpha)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(56.dp)
            .clip(RoundedCornerShape(cornerRadiusDp.dp))
            .background(bgColorOuter)
            .padding(6.dp)
    ) {
        Row(modifier = Modifier.fillMaxSize()) {
            // Main pill
            Row(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape((cornerRadiusDp - 4).coerceAtLeast(0).dp))
                    .background(bgColorInner)
                    .padding(horizontal = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.search_48dp_ffffff_fill0_wght700_grad0_opsz48),
                    contentDescription = null,
                    tint = accentColor,
                    modifier = Modifier.size(26.dp)
                )

                Spacer(modifier = Modifier.weight(1f))

                if (isMicEnabled) {
                    val micIconRes = if (isGeminiEnabled) {
                        R.drawable.google_gemini_no_color
                    } else {
                        R.drawable.mic_48dp_ffffff_fill1_wght700_grad0_opsz48
                    }
                    Icon(
                        painter = painterResource(id = micIconRes),
                        contentDescription = null,
                        tint = accentColor,
                        modifier = Modifier.size(25.dp)
                    )
                }

                if (isMicEnabled && isLensEnabled) {
                    Spacer(modifier = Modifier.width(12.dp))
                }

                if (isLensEnabled) {
                    Icon(
                        painter = painterResource(id = R.drawable.ic_lens_white),
                        contentDescription = null,
                        tint = accentColor,
                        modifier = Modifier.size(30.dp)
                    )
                }
            }

            if (isMusicEnabled) {
                Spacer(modifier = Modifier.width(8.dp))

                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .aspectRatio(1f)
                        .clip(RoundedCornerShape((cornerRadiusDp - 4).coerceAtLeast(0).dp))
                        .background(bgColorInner),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        painter = painterResource(
                            id = if (circlePillMode == "maps")
                                R.drawable.google_maps_icon_2020_white
                            else
                                R.drawable.music_note_48dp_ffffff_fill0_wght700_grad0_opsz48
                        ),
                        contentDescription = null,
                        tint = accentColor,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    }
}
