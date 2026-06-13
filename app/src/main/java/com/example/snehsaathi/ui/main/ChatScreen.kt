package com.example.snehsaathi.ui.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.core.AIService
import com.example.snehsaathi.core.TextToSpeechManager
import com.example.snehsaathi.core.VoiceInputHelper
import kotlinx.coroutines.launch

data class Message(val text: String, val isUser: Boolean)

@Composable
fun ChatScreen(
    aiService: AIService,
    userRelation: String,
    userLanguage: String,
    ttsManager: TextToSpeechManager,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val greetingRelation = if (userRelation == "Dada") "दादा जी" else "दादी जी"
    val messages = remember { mutableStateListOf<Message>() }
    
    var isListening by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    var voiceHelper by remember { mutableStateOf<VoiceInputHelper?>(null) }

    DisposableEffect(Unit) {
        val initialMessage = if (userLanguage == "hi") {
            "नमस्ते $greetingRelation! मैं आपका साथी हूँ। आज आप कैसे हैं?"
        } else {
            "Namaste $greetingRelation! Main aapka saathi hoon. Aaj aap kaise hain?"
        }
        messages.add(Message(initialMessage, false))
        ttsManager.speak(initialMessage)
        
        val sttLanguageCode = if (userLanguage == "en") "en-IN" else "hi-IN"
        voiceHelper = VoiceInputHelper(
            context = context,
            languageCode = sttLanguageCode,
            onResult = { userText ->
                messages.add(Message(userText, true))
                isProcessing = true
                scope.launch {
                    val response = aiService.reply(userText)
                    messages.add(Message(response, false))
                    isProcessing = false
                    ttsManager.speak(response)
                }
            },
            onListeningStart = { isListening = true },
            onListeningStop = { isListening = false }
        )

        onDispose {
            voiceHelper?.destroy()
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

        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(bottom = 8.dp)
        ) {
            items(messages) { msg ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = if (msg.isUser) Arrangement.End else Arrangement.Start
                ) {
                    Box(
                        modifier = Modifier
                            .background(
                                color = if (msg.isUser) Color(0xFFDCF8C6) else Color(0xFFFFFFFF),
                                shape = RoundedCornerShape(12.dp)
                            )
                            .padding(12.dp)
                    ) {
                        Text(text = msg.text, fontSize = 18.sp, color = Color.Black)
                    }
                }
            }
        }

        // Voice UI controls at the bottom
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (isProcessing) {
                Text("सोच रहे हैं... (Thinking...)", color = Color.Gray, fontSize = 16.sp)
                Spacer(modifier = Modifier.height(8.dp))
            } else if (isListening) {
                Text("सुन रहे हैं... (Listening...)", color = Color(0xFFD84315), fontSize = 16.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            Button(
                onClick = {
                    ttsManager.stop()
                    voiceHelper?.startListening()
                },
                modifier = Modifier.size(100.dp),
                shape = CircleShape,
                colors = ButtonDefaults.buttonColors(containerColor = if (isListening) Color(0xFFE53935) else Color(0xFF4CAF50))
            ) {
                Icon(
                    imageVector = Icons.Filled.Mic,
                    contentDescription = "Speak",
                    tint = Color.White,
                    modifier = Modifier.size(60.dp)
                )
            }
        }
    }
}
