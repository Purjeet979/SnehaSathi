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

@Composable
fun SecurityScreen(ttsManager: TextToSpeechManager, onBack: () -> Unit) {
    val context = LocalContext.current
    var voiceHelper by remember { mutableStateOf<VoiceInputHelper?>(null) }
    
    var activeState by remember { mutableIntStateOf(0) }
    var doorsLocked by remember { mutableStateOf(false) }
    var gasOff by remember { mutableStateOf(false) }
    var windowsClosed by remember { mutableStateOf(false) }
    var isListening by remember { mutableStateOf(false) }

    DisposableEffect(Unit) {
        voiceHelper = VoiceInputHelper(
            context = context,
            onResult = { text ->
                val lowerText = text.lowercase()
                val isAffirmative = lowerText.contains("haan") || lowerText.contains("yes") || 
                                  lowerText.contains("kardiya") || lowerText.contains("ji") || 
                                  lowerText.contains("ho") || lowerText.contains("bilkul") ||
                                  lowerText.contains("हाँ") || lowerText.contains("हा") || 
                                  lowerText.contains("जी") || lowerText.contains("कर")
                
                if (isAffirmative) {
                    when (activeState) {
                        1 -> { doorsLocked = true; activeState = 2 }
                        2 -> { gasOff = true; activeState = 3 }
                        3 -> { windowsClosed = true; activeState = 4 }
                    }
                } else {
                    // Try asking again if not affirmative
                    when (activeState) {
                        1 -> ttsManager.speak("Kya aapne darwaza lock kar diya?", onComplete = { voiceHelper?.startListening() })
                        2 -> ttsManager.speak("Kya gas band hai?", onComplete = { voiceHelper?.startListening() })
                        3 -> ttsManager.speak("Kya khidkiyan band hain?", onComplete = { voiceHelper?.startListening() })
                    }
                }
            },
            onListeningStart = { isListening = true },
            onListeningStop = { isListening = false }
        )
        activeState = 1

        onDispose {
            voiceHelper?.destroy()
        }
    }

    LaunchedEffect(activeState) {
        when(activeState) {
            1 -> ttsManager.speak("Kya aapne darwaza lock kar diya?", onComplete = { voiceHelper?.startListening() })
            2 -> ttsManager.speak("Kya gas band hai?", onComplete = { voiceHelper?.startListening() })
            3 -> ttsManager.speak("Kya khidkiyan band hain?", onComplete = { voiceHelper?.startListening() })
            4 -> ttsManager.speak("Bahut badhiya, sab kuch surakshit hai.")
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
            Text("वापस जाएँ (Back)", fontSize = 20.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
        }

        Text(
            text = "सुरक्षा जाँच (Security)",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF5D4037)
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (isListening) {
            Text(
                text = "सुन रहे हैं... (Listening...)",
                color = Color(0xFFD84315),
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFFE3F2FD)),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (activeState == 4) {
                    Icon(
                        Icons.Filled.CheckCircle,
                        contentDescription = "Secure",
                        tint = Color(0xFF4CAF50),
                        modifier = Modifier.size(80.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("सब कुछ सुरक्षित है!", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1565C0))
                } else {
                    Text("जाँच चल रही है...", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1565C0))
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                SecurityCheckItem(label = "Darwaza (Doors)", isChecked = doorsLocked, isActive = activeState == 1)
                SecurityCheckItem(label = "Gas (Stove)", isChecked = gasOff, isActive = activeState == 2)
                SecurityCheckItem(label = "Khidkiyan (Windows)", isChecked = windowsClosed, isActive = activeState == 3)
            }
        }
    }
}

@Composable
fun SecurityCheckItem(label: String, isChecked: Boolean, isActive: Boolean) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .let { if (isActive) it.padding(start = 16.dp) else it }
    ) {
        val color = if (isChecked) Color(0xFF4CAF50) else if (isActive) Color(0xFFF57C00) else Color.Gray
        val icon = if (isChecked) Icons.Filled.CheckCircle else null
        
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
        } else {
            Box(modifier = Modifier.size(24.dp))
        }
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = label, 
            fontSize = if (isActive) 22.sp else 18.sp, 
            fontWeight = if (isActive) FontWeight.Bold else FontWeight.Normal,
            color = color
        )
    }
}
