package com.example.snehsaathi.ui.main

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.core.TextToSpeechManager
import com.example.snehsaathi.core.VoiceInputHelper

import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit
import com.example.snehsaathi.features.security.SecurityReminderWorker
import androidx.compose.material.icons.filled.Mic

@Composable
fun SecurityScreen(
    ttsManager: TextToSpeechManager, 
    isFromReminder: Boolean,
    userLanguage: String,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    var voiceHelper by remember { mutableStateOf<VoiceInputHelper?>(null) }
    
    var activeState by remember { mutableIntStateOf(1) }
    var doorsLocked by remember { mutableStateOf(false) }
    var gasOff by remember { mutableStateOf(false) }
    var windowsClosed by remember { mutableStateOf(false) }
    var isListening by remember { mutableStateOf(false) }
    var isManualChecking by remember { mutableStateOf(isFromReminder) }

    DisposableEffect(Unit) {
        voiceHelper = VoiceInputHelper(
            context = context,
            onResult = { text ->
                val lowerText = text.lowercase()
                val isAffirmative = lowerText.contains("haan") || lowerText.contains("yes") || lowerText.contains("ya") || lowerText.contains("yep") || lowerText.contains("yeah") || lowerText.contains("yup") ||
                                  lowerText.contains("kardiya") || lowerText.contains("ji") || 
                                  lowerText.contains("ho") || lowerText.contains("bilkul") ||
                                  lowerText.contains("हाँ") || lowerText.contains("हा") || 
                                  lowerText.contains("जी") || lowerText.contains("कर")
                                  
                val isNegative = lowerText.contains("nahi") || lowerText.contains("no") || lowerText.contains("nope") || lowerText.contains("not") ||
                                 lowerText.contains("नहीं") || lowerText.contains("ना") || lowerText.contains("baad mein")
                
                if (isAffirmative) {
                    when (activeState) {
                        1 -> { doorsLocked = true; activeState = 2 }
                        2 -> { gasOff = true; activeState = 3 }
                        3 -> { windowsClosed = true; activeState = 4 }
                    }
                } else if (isNegative) {
                    ttsManager.speakFast("Theek hai, main paanch minute baad yaad dilaungi.")
                    
                    val snoozeRequest = OneTimeWorkRequestBuilder<SecurityReminderWorker>()
                        .setInitialDelay(5, TimeUnit.MINUTES)
                        .build()
                    WorkManager.getInstance(context).enqueue(snoozeRequest)
                    
                    voiceHelper?.stopListening()
                    onBack()
                } else {
                    // Try asking again if not affirmative
                    when (activeState) {
                        1 -> ttsManager.speakFast(if (userLanguage == "hi") "Kya aapne darwaza lock kar diya?" else "Have you locked the doors?", language = userLanguage, onComplete = { voiceHelper?.startListening() })
                        2 -> ttsManager.speakFast(if (userLanguage == "hi") "Kya gas band hai?" else "Is the stove off?", language = userLanguage, onComplete = { voiceHelper?.startListening() })
                        3 -> ttsManager.speakFast(if (userLanguage == "hi") "Kya khidkiyan band hain?" else "Are the windows closed?", language = userLanguage, onComplete = { voiceHelper?.startListening() })
                    }
                }
            },
            onListeningStart = { isListening = true },
            onListeningStop = { isListening = false }
        )

        onDispose {
            voiceHelper?.destroy()
        }
    }

    LaunchedEffect(activeState, isManualChecking) {
        if (isManualChecking) {
            when(activeState) {
                1 -> ttsManager.speakFast(if (userLanguage == "hi") "Kya aapne darwaza lock kar diya?" else "Have you locked the doors?", language = userLanguage, onComplete = { voiceHelper?.startListening() })
                2 -> ttsManager.speakFast(if (userLanguage == "hi") "Kya gas band hai?" else "Is the stove off?", language = userLanguage, onComplete = { voiceHelper?.startListening() })
                3 -> ttsManager.speakFast(if (userLanguage == "hi") "Kya khidkiyan band hain?" else "Are the windows closed?", language = userLanguage, onComplete = { voiceHelper?.startListening() })
                4 -> ttsManager.speakFast(if (userLanguage == "hi") "Bahut badhiya, sab kuch surakshit hai." else "Very good, everything is secure.", language = userLanguage)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Button(
            onClick = {
                voiceHelper?.stopListening()
                onBack()
            }, 
            modifier = Modifier
                .padding(bottom = 16.dp)
                .fillMaxWidth()
                .height(60.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF5D4037))
        ) {
            Text(if (userLanguage == "hi") "वापस जाएँ" else "Back", fontSize = 20.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
        }

        Text(
            text = if (userLanguage == "hi") "सुरक्षा जाँच" else "Security Check",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF5D4037)
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (!isManualChecking && activeState < 4) {
            Button(
                onClick = { isManualChecking = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp)
                    .padding(vertical = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800)),
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(Icons.Filled.Mic, contentDescription = "Start Voice Check", modifier = Modifier.size(32.dp), tint = Color.White)
                Spacer(modifier = Modifier.width(16.dp))
                Text(if (userLanguage == "hi") "आवाज़ से चेक करें" else "Start Voice Check", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.White)
            }
            Spacer(modifier = Modifier.height(8.dp))
        }

        if (isListening) {
            Text(
                text = if (userLanguage == "hi") "सुन रहे हैं..." else "Listening...",
                color = Color(0xFFD84315),
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        val items = listOf(
            Pair(if (userLanguage == "hi") "दरवाज़ा (Doors)" else "Doors", doorsLocked),
            Pair(if (userLanguage == "hi") "गैस (Stove)" else "Stove", gasOff),
            Pair(if (userLanguage == "hi") "खिड़कियाँ (Windows)" else "Windows", windowsClosed)
        )

        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items.forEachIndexed { index, pair ->
                val isActive = (index + 1) == activeState
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = if (isActive) Color(0xFFFFF3E0) else Color(0xFFE8F5E9)),
                    elevation = CardDefaults.cardElevation(defaultElevation = if (isActive) 8.dp else 2.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = pair.first, 
                            fontSize = if (isActive) 24.sp else 22.sp, 
                            fontWeight = if (isActive) FontWeight.Bold else FontWeight.Normal,
                            color = if (isActive) Color(0xFFE65100) else Color.Black
                        )
                        Checkbox(
                            checked = pair.second,
                            onCheckedChange = { isChecked ->
                                if (index == 0) { doorsLocked = isChecked; if(isChecked && activeState == 1) { voiceHelper?.stopListening(); activeState = 2 } }
                                if (index == 1) { gasOff = isChecked; if(isChecked && activeState == 2) { voiceHelper?.stopListening(); activeState = 3 } }
                                if (index == 2) { windowsClosed = isChecked; if(isChecked && activeState == 3) { voiceHelper?.stopListening(); activeState = 4 } }
                            },
                            colors = CheckboxDefaults.colors(checkedColor = Color(0xFF4CAF50))
                        )
                    }
                }
            }
        }
        
        if (activeState == 4) {
            Spacer(modifier = Modifier.height(24.dp))
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                Icon(
                    Icons.Filled.CheckCircle,
                    contentDescription = "Secure",
                    tint = Color(0xFF4CAF50),
                    modifier = Modifier.size(80.dp)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(if (userLanguage == "hi") "सब कुछ सुरक्षित है!" else "Everything is Secure!", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1565C0))
            }
        }
    }
}
