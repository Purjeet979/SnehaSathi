package com.example.snehsaathi.features.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.core.tts.OfflineTtsManager
import com.example.snehsaathi.data.local.UserPreferencesRepository
import com.example.snehsaathi.ui.components.BreathingMicButton
import com.example.snehsaathi.ui.components.MicState
import com.example.snehsaathi.ui.theme.SnehSaathiColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun OnboardingFlow(
    ttsManager: OfflineTtsManager,
    userPrefs: UserPreferencesRepository,
    onComplete: () -> Unit
) {
    val scope = rememberCoroutineScope()
    var step by remember { mutableStateOf(1) }
    var micState by remember { mutableStateOf(MicState.IDLE) }
    
    val textToShow = when (step) {
        1 -> "नमस्ते! मैं आपकी नई सहेली हूँ। आपका नाम क्या है?"
        2 -> "आपके घर में कौन हैं? बेटा, बेटी, पोता?"
        3 -> "क्या आप कोई दवाई लेती हैं? मैं याद दिला सकती हूँ।"
        else -> "धन्यवाद!"
    }

    LaunchedEffect(step) {
        micState = MicState.SPEAKING
        ttsManager.speak(textToShow)
        delay(3000) // Simulate speaking duration
        micState = MicState.LISTENING
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SnehSaathiColors.backgroundPrimary)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = textToShow,
            fontSize = 28.sp,
            color = SnehSaathiColors.textPrimary,
            textAlign = TextAlign.Center,
            lineHeight = 40.sp,
            modifier = Modifier.padding(bottom = 60.dp)
        )

        BreathingMicButton(
            state = micState,
            offlineTts = ttsManager,
            onClick = {
                if (micState == MicState.LISTENING) {
                    micState = MicState.THINKING
                    // Simulate voice recognition and processing
                    scope.launch {
                        delay(2000) // pretend we processed speech
                        if (step < 3) {
                            step++
                        } else {
                            onComplete()
                        }
                    }
                }
            }
        )
    }
}
