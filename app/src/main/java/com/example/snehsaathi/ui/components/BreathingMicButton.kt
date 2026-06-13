package com.example.snehsaathi.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.snehsaathi.core.tts.OfflineTtsManager
import com.example.snehsaathi.ui.theme.SnehSaathiColors

enum class MicState { IDLE, LISTENING, THINKING, SPEAKING }

@Composable
fun BreathingMicButton(
    state: MicState,
    offlineTts: OfflineTtsManager,
    onClick: () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "micPulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (state == MicState.LISTENING) 1.15f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(120.dp) // Never smaller than 120dp for elderly
            .scale(scale)
            .clip(CircleShape)
            .background(
                when (state) {
                    MicState.IDLE -> SnehSaathiColors.micIdle
                    MicState.LISTENING -> SnehSaathiColors.micListening
                    MicState.THINKING -> SnehSaathiColors.micProcessing
                    MicState.SPEAKING -> SnehSaathiColors.actionPrimary
                }
            )
            .clickable(onClick = onClick)
    ) {
        Icon(
            imageVector = when (state) {
                MicState.LISTENING -> Icons.Filled.Mic
                MicState.THINKING -> Icons.Filled.HourglassTop
                MicState.SPEAKING -> Icons.Filled.VolumeUp
                else -> Icons.Filled.Mic
            },
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(52.dp)
        )
    }

    // Speak the state change — Dadi doesn't read state labels
    LaunchedEffect(state) {
        when (state) {
            MicState.LISTENING -> offlineTts.speak("हाँ बोलिए")
            MicState.THINKING -> offlineTts.speak("सोच रही हूँ...")
            else -> {}
        }
    }
}
