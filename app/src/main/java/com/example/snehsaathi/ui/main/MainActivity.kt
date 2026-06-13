package com.example.snehsaathi.ui.main

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Hearing
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.example.snehsaathi.R
import com.example.snehsaathi.core.*
import com.example.snehsaathi.features.medication.MedicationReminderWorker
import com.example.snehsaathi.features.memory.*
import com.example.snehsaathi.features.nostalgia.NostalgiaEngine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {

    private val aiService: AIService = object : AIService {
        override suspend fun reply(userText: String): String {
            return try {
                val response = com.example.snehsaathi.core.SarvamClient.chat(
                    listOf(
                        mapOf("role" to "system", "content" to com.example.snehsaathi.core.Constants.DADI_SYSTEM_PROMPT),
                        mapOf("role" to "user", "content" to userText)
                    )
                )
                com.example.snehsaathi.core.OfflineManager.insert(
                    com.example.snehsaathi.core.CachedResponse(userInput = userText, aiResponse = response)
                )
                response
            } catch (e: Exception) {
                Log.e("AI_SERVICE", "Chat failed", e)
                val cached = com.example.snehsaathi.core.OfflineManager.getRecent().firstOrNull()
                cached?.aiResponse ?: "Abhi network nahi hai Dadi, thodi der mein try karein. Aap theek hain?"
            }
        }
    }
    private val featureManager = FeatureManager()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        com.example.snehsaathi.core.OfflineManager.init(this)

        if (FeatureFlags.MEDICATION) {
            val delay = calculateInitialDelay(8, 0)
            val work =
                PeriodicWorkRequestBuilder<MedicationReminderWorker>(24, TimeUnit.HOURS)
                    .setInitialDelay(delay, TimeUnit.MILLISECONDS)
                    .build()

            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "MEDICATION_REMINDER",
                ExistingPeriodicWorkPolicy.KEEP,
                work
            )
        }

        setContent {
            AppUI(
                aiService = aiService,
                featureManager = featureManager,
                onSaveDailySummary = { saveDailySummary(it) }
            )
        }
    }

    private fun calculateInitialDelay(hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
        }
        if (target.before(now)) target.add(Calendar.DAY_OF_YEAR, 1)
        return target.timeInMillis - now.timeInMillis
    }

    private fun saveDailySummary(summary: String) {
        val date = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        com.google.firebase.firestore.FirebaseFirestore.getInstance()
            .collection("daily_summaries")
            .document(date)
            .set(
                mapOf(
                    "text" to summary,
                    "timestamp" to System.currentTimeMillis()
                )
            )
    }
}

@Composable
fun AppUI(
    aiService: AIService,
    featureManager: FeatureManager,
    onSaveDailySummary: (String) -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val ttsManager = remember { TextToSpeechManager(context) }

    // State for which screen is active: HOME, CHAT
    var currentScreen by remember { mutableStateOf("HOME") }
    
    // Background brush from the previous design
    val backgroundBrush = Brush.radialGradient(
        listOf(
            Color(0xFFFFFDD0),
            Color(0xFFFFF9C4),
            Color(0xFFFFECB3)
        ),
        center = Offset(0.5f, 0.4f),
        radius = 1200f
    )

    Box(modifier = Modifier.fillMaxSize().background(backgroundBrush)) {
        if (currentScreen == "HOME") {
            HomeScreen(
                onTalkClick = { currentScreen = "CHAT" },
                onMedsClick = { ttsManager.speak("दवाई का समय अभी नहीं हुआ है दादी।") },
                onFamilyClick = { ttsManager.speak("रोहन को मैसेज भेज दिया है।") },
                onSecurityClick = { ttsManager.speak("सब कुछ सुरक्षित है।") },
                onSosClick = {
                    ttsManager.speak("Ghabrana nahi Dadi, main abhi aapke ghar walon ko inform kar raha hoon.")
                    // SOS logic
                }
            )
        } else if (currentScreen == "CHAT") {
            // We can implement the chat interface here or use the breathing mic overlay
            // For now, a placeholder that lets them go back
            Column(
                modifier = Modifier.fillMaxSize().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text("Chat Screen Placeholder", fontSize = 24.sp)
                Button(onClick = { currentScreen = "HOME" }) {
                    Text("वापस जाएँ")
                }
            }
        }
    }
}

@Composable
fun HomeScreen(
    onTalkClick: () -> Unit,
    onMedsClick: () -> Unit,
    onFamilyClick: () -> Unit,
    onSecurityClick: () -> Unit,
    onSosClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(modifier = Modifier.height(32.dp))
            Image(
                painter = painterResource(id = R.drawable.sneh_saathi_logo),
                contentDescription = "Sneh Saathi Logo",
                modifier = Modifier.size(160.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "नमस्ते Dadi, कैसी हैं?",
                style = MaterialTheme.typography.titleMedium,
                fontSize = 28.sp
            )
        }

        // 4-Button Grid
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                HomeButton(
                    text = "🎤 बात\nकरें",
                    onClick = onTalkClick,
                    modifier = Modifier.weight(1f)
                )
                HomeButton(
                    text = "💊 दवाई\nयाद दिलाएं",
                    onClick = onMedsClick,
                    modifier = Modifier.weight(1f)
                )
            }
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                HomeButton(
                    text = "👨‍👩‍👧‍👦 परिवार\nसे जोड़ें",
                    onClick = onFamilyClick,
                    modifier = Modifier.weight(1f)
                )
                HomeButton(
                    text = "🛡️ सुरक्षा\nजाँच",
                    onClick = onSecurityClick,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        com.example.snehsaathi.features.sos.SosButton(onSosTriggered = onSosClick)
    }
}

@Composable
fun HomeButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFFF3E0)),
        border = BorderStroke(2.dp, Color(0xFFD7CCC8)),
        shape = RoundedCornerShape(24.dp),
        modifier = modifier
            .height(140.dp) // Minimum 100dp, made it 140dp for ease
    ) {
        Text(
            text = text,
            color = Color(0xFF5D4037),
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            lineHeight = 34.sp,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}
