package com.example.snehsaathi.ui.main

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
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

data class Medication(val name: String, val time: String, var taken: Boolean)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MedsScreen(ttsManager: TextToSpeechManager, onBack: () -> Unit) {
    val context = LocalContext.current
    var voiceHelper by remember { mutableStateOf<VoiceInputHelper?>(null) }
    
    val meds = remember {
        mutableStateListOf(
            Medication("Blood Pressure Pill", "08:00 AM", false),
            Medication("Diabetes Medicine", "01:00 PM", false),
            Medication("Vitamins", "08:00 PM", false)
        )
    }

    var activeIndex by remember { mutableIntStateOf(0) }
    var isListening by remember { mutableStateOf(false) }
    var showAddDialog by remember { mutableStateOf(false) }

    DisposableEffect(Unit) {
        voiceHelper = VoiceInputHelper(
            context = context,
            onResult = { text ->
                val lowerText = text.lowercase()
                val isAffirmative = lowerText.contains("haan") || lowerText.contains("yes") || 
                                  lowerText.contains("le li") || lowerText.contains("khaa li") || lowerText.contains("ji") ||
                                  lowerText.contains("हाँ") || lowerText.contains("हा") || 
                                  lowerText.contains("जी") || lowerText.contains("ली") || lowerText.contains("खा")
                
                if (isAffirmative && activeIndex < meds.size) {
                    val currentMed = meds[activeIndex]
                    meds[activeIndex] = currentMed.copy(taken = true)
                    activeIndex++
                } else if (activeIndex < meds.size) {
                    // Try asking again if they didn't say yes or no clearly, or move on
                    val currentMed = meds[activeIndex]
                    ttsManager.speak("Kya aapne ${currentMed.name} le li hai?", onComplete = { voiceHelper?.startListening() })
                }
            },
            onListeningStart = { isListening = true },
            onListeningStop = { isListening = false }
        )

        onDispose {
            voiceHelper?.destroy()
        }
    }

    LaunchedEffect(activeIndex, meds.size) {
        if (activeIndex < meds.size) {
            val currentMed = meds[activeIndex]
            ttsManager.speak("Kya aapne ${currentMed.name} le li hai?", onComplete = { voiceHelper?.startListening() })
        } else if (meds.isNotEmpty() && activeIndex == meds.size) {
            ttsManager.speak("Bahut badhiya, aapne saari dawaiyan le li hain.")
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
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

            IconButton(
                onClick = { showAddDialog = true },
                colors = IconButtonDefaults.iconButtonColors(containerColor = Color(0xFFE8F5E9))
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Add Medication", tint = Color(0xFF2E7D32))
            }
        }

        Text(
            text = "दवाइयाँ (Medications)",
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

        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(meds) { med ->
                val isActive = meds.indexOf(med) == activeIndex
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
                        Column {
                            Text(
                                text = med.name, 
                                fontSize = if (isActive) 24.sp else 22.sp, 
                                fontWeight = if (isActive) FontWeight.Bold else FontWeight.Normal,
                                color = if (isActive) Color(0xFFE65100) else Color.Black
                            )
                            Text(text = med.time, fontSize = 16.sp, color = Color.Gray)
                        }
                        Checkbox(
                            checked = med.taken,
                            onCheckedChange = { isChecked ->
                                val index = meds.indexOf(med)
                                if (index != -1) {
                                    meds[index] = med.copy(taken = isChecked)
                                    // Optionally manual override advances the active index
                                    if (isChecked && index == activeIndex) {
                                        voiceHelper?.stopListening()
                                        activeIndex++
                                    }
                                }
                            },
                            colors = CheckboxDefaults.colors(checkedColor = Color(0xFF4CAF50))
                        )
                    }
                }
            }
        }
    }

    if (showAddDialog) {
        var newMedName by remember { mutableStateOf("") }
        var newMedTime by remember { mutableStateOf("") }
        
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("दवाई जोड़ें (Add Medication)") },
            text = {
                Column {
                    OutlinedTextField(
                        value = newMedName,
                        onValueChange = { newMedName = it },
                        label = { Text("दवाई का नाम (Medicine Name)") }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = newMedTime,
                        onValueChange = { newMedTime = it },
                        label = { Text("समय (Time e.g., 08:00 AM)") }
                    )
                }
            },
            confirmButton = {
                Button(onClick = {
                    if (newMedName.isNotBlank()) {
                        meds.add(Medication(newMedName, if (newMedTime.isBlank()) "08:00 AM" else newMedTime, false))
                    }
                    showAddDialog = false
                }) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
