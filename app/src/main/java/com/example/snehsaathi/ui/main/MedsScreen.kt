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

import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit
import com.example.snehsaathi.features.medication.MedicationReminderWorker
import androidx.compose.material.icons.filled.Mic

data class Medication(val name: String, val time: String, var taken: Boolean)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MedsScreen(
    ttsManager: TextToSpeechManager, 
    isFromReminder: Boolean,
    userLanguage: String,
    onBack: () -> Unit
) {
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
    var isManualChecking by remember { mutableStateOf(isFromReminder) }

    DisposableEffect(Unit) {
        voiceHelper = VoiceInputHelper(
            context = context,
            onResult = { text ->
                val lowerText = text.lowercase()
                val isAffirmative = lowerText.contains("haan") || lowerText.contains("yes") || lowerText.contains("ya") || lowerText.contains("yep") || lowerText.contains("yeah") || lowerText.contains("yup") ||
                                  lowerText.contains("le li") || lowerText.contains("khaa li") || lowerText.contains("ji") ||
                                  lowerText.contains("हाँ") || lowerText.contains("हा") || 
                                  lowerText.contains("जी") || lowerText.contains("ली") || lowerText.contains("खा")
                                  
                val isNegative = lowerText.contains("nahi") || lowerText.contains("no") || lowerText.contains("nope") || lowerText.contains("not") ||
                                 lowerText.contains("नहीं") || lowerText.contains("ना") || lowerText.contains("baad mein")
                
                if (isAffirmative && activeIndex < meds.size) {
                    val currentMed = meds[activeIndex]
                    meds[activeIndex] = currentMed.copy(taken = true)
                    activeIndex++
                } else if (isNegative) {
                    val msg = if (userLanguage == "en") "Okay, I will remind you in five minutes." else "Theek hai, main paanch minute baad yaad dilaungi."
                    ttsManager.speakFast(msg, language = userLanguage)
                    
                    val snoozeRequest = OneTimeWorkRequestBuilder<MedicationReminderWorker>()
                        .setInitialDelay(5, TimeUnit.MINUTES)
                        .build()
                    WorkManager.getInstance(context).enqueue(snoozeRequest)
                    
                    voiceHelper?.stopListening()
                    onBack()
                } else if (activeIndex < meds.size) {
                    // Try asking again if they didn't say yes or no clearly
                    val currentMed = meds[activeIndex]
                    val msg = if (userLanguage == "en") "Have you taken ${currentMed.name}?" else "Kya aapne ${currentMed.name} le li hai?"
                    ttsManager.speakFast(msg, language = userLanguage, onComplete = { voiceHelper?.startListening() })
                }
            },
            onListeningStart = { isListening = true },
            onListeningStop = { isListening = false }
        )

        onDispose {
            voiceHelper?.destroy()
        }
    }

    LaunchedEffect(activeIndex, meds.size, isManualChecking) {
        if (isManualChecking) {
            if (activeIndex < meds.size) {
                val currentMed = meds[activeIndex]
                val msg = if (userLanguage == "en") "Have you taken ${currentMed.name}?" else "Kya aapne ${currentMed.name} le li hai?"
                ttsManager.speakFast(msg, language = userLanguage, onComplete = { voiceHelper?.startListening() })
            } else if (meds.isNotEmpty() && activeIndex == meds.size) {
                val msg = if (userLanguage == "en") "Very good, you have taken all your medications." else "Bahut badhiya, aapne saari dawaiyan le li hain."
                ttsManager.speakFast(msg, language = userLanguage)
            }
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
            Text(if (userLanguage == "hi") "वापस जाएँ" else "Back", fontSize = 20.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
        }

            IconButton(
                onClick = { showAddDialog = true },
                colors = IconButtonDefaults.iconButtonColors(containerColor = Color(0xFFE8F5E9))
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Add Medication", tint = Color(0xFF2E7D32))
            }
        }

        Text(
            text = if (userLanguage == "hi") "दवाइयाँ" else "Medications",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF5D4037)
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (!isManualChecking && activeIndex < meds.size) {
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
            title = { Text(if (userLanguage == "hi") "दवाई जोड़ें" else "Add Medication") },
            text = {
                Column {
                    OutlinedTextField(
                        value = newMedName,
                        onValueChange = { newMedName = it },
                        label = { Text(if (userLanguage == "hi") "दवाई का नाम" else "Medicine Name") }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = newMedTime,
                        onValueChange = { newMedTime = it },
                        label = { Text(if (userLanguage == "hi") "समय (जैसे, 08:00 AM)" else "Time (e.g., 08:00 AM)") }
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
