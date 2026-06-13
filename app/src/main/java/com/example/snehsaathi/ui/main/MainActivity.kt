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

    private val appDatabase by lazy {
        androidx.room.Room.databaseBuilder(
            applicationContext,
            com.example.snehsaathi.data.local.AppDatabase::class.java, "snehsaathi-main.db"
        ).fallbackToDestructiveMigration().build()
    }

    private val memoryRepository by lazy {
        com.example.snehsaathi.data.repository.MemoryRepository(
            appDatabase.memoryDao(),
            com.example.snehsaathi.data.repository.LocalEmbeddingEngine(applicationContext)
        )
    }

    private val aiService: AIService by lazy {
        object : AIService {
            override suspend fun reply(userText: String): String {
                return try {
                    val profile = com.example.snehsaathi.core.UserProfileManager.getProfile(applicationContext)
                    val userName = profile?.name ?: "Dadi"
                    val relation = profile?.relation ?: "Dadi"
                    val language = profile?.language ?: "hi"

                    val relevantMemories = memoryRepository.retrieveRelevantMemories(userText)
                    val memoryContext = if (relevantMemories.isNotEmpty()) {
                        "Previous context to remember: " + relevantMemories.joinToString("; ") + ".\n\n"
                    } else {
                        ""
                    }
                    
                    val systemPrompt = com.example.snehsaathi.core.Constants.getSystemPrompt(userName, relation, language) + "\n\n" + memoryContext

                    val response = com.example.snehsaathi.core.SarvamClient.chat(
                        listOf(
                            mapOf("role" to "system", "content" to systemPrompt),
                            mapOf("role" to "user", "content" to userText)
                        )
                    )
                    
                    memoryRepository.saveMemory("$relation ($userName) said: $userText. I replied: $response")

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

            // Schedule Security Check at 10 PM
            val securityDelay = calculateInitialDelay(22, 0)
            val securityWork = PeriodicWorkRequestBuilder<com.example.snehsaathi.features.security.SecurityReminderWorker>(24, TimeUnit.HOURS)
                .setInitialDelay(securityDelay, TimeUnit.MILLISECONDS)
                .build()

            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "SECURITY_REMINDER",
                ExistingPeriodicWorkPolicy.KEEP,
                securityWork
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
    val contacts = remember { com.example.snehsaathi.core.ContactsManager.getContacts(context) }
    val userProfileState = remember { mutableStateOf(com.example.snehsaathi.core.UserProfileManager.getProfile(context)) }
    val userProfile = userProfileState.value

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { isGranted ->
            if (!isGranted) {
                Log.e("PERMISSIONS", "Microphone permission denied. Voice features will be disabled.")
            }
        }
    )

    LaunchedEffect(Unit) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            ttsManager.destroy()
        }
    }

    val initialScreen = (context as? android.app.Activity)?.intent?.getStringExtra("target_screen")
        ?: if (userProfile == null || contacts.isEmpty()) "ONBOARDING" else "HOME"

    // State for which screen is active
    var currentScreen by remember { mutableStateOf(initialScreen) }
    var hasGreeted by remember { mutableStateOf(false) }
    
    val navigateTo: (String) -> Unit = { screen ->
        ttsManager.stop()
        currentScreen = screen
    }

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
        when (currentScreen) {
            "ONBOARDING" -> OnboardingScreen(onFinish = { 
                userProfileState.value = com.example.snehsaathi.core.UserProfileManager.getProfile(context)
                navigateTo("HOME") 
            })
            "HOME" -> HomeScreen(
                userName = userProfile?.name ?: "",
                userRelation = userProfile?.relation ?: "Dadi",
                userLanguage = userProfile?.language ?: "hi",
                ttsManager = ttsManager,
                hasGreeted = hasGreeted,
                onGreeted = { hasGreeted = true },
                onLanguageChange = { newLang ->
                    com.example.snehsaathi.core.UserProfileManager.updateLanguage(context, newLang)
                    userProfileState.value = com.example.snehsaathi.core.UserProfileManager.getProfile(context)
                },
                onTalkClick = { navigateTo("CHAT") },
                onMedsClick = { navigateTo("MEDS") },
                onFamilyClick = { navigateTo("FAMILY") },
                onSecurityClick = { navigateTo("SECURITY") }
            )
            "CHAT" -> ChatScreen(
                aiService = aiService,
                userRelation = userProfile?.relation ?: "Dadi",
                userLanguage = userProfile?.language ?: "hi",
                ttsManager = ttsManager,
                onBack = { navigateTo("HOME") }
            )
            "MEDS" -> MedsScreen(
                ttsManager = ttsManager,
                onBack = { navigateTo("HOME") }
            )
            "FAMILY" -> FamilyScreen(onBack = { navigateTo("HOME") })
            "SECURITY" -> SecurityScreen(
                ttsManager = ttsManager,
                onBack = { navigateTo("HOME") }
            )
        }
    }
}

@Composable
fun HomeScreen(
    userName: String,
    userRelation: String,
    userLanguage: String,
    ttsManager: com.example.snehsaathi.core.TextToSpeechManager,
    hasGreeted: Boolean,
    onGreeted: () -> Unit,
    onLanguageChange: (String) -> Unit,
    onTalkClick: () -> Unit,
    onMedsClick: () -> Unit,
    onFamilyClick: () -> Unit,
    onSecurityClick: () -> Unit
) {
    val greetingRelation = if (userRelation == "Dada") "दादा जी" else "दादी जी"
    val greetingText = if (userLanguage == "hi") {
        "नमस्ते $userName $greetingRelation, कैसे हैं? आप क्या करना चाहेंगे?"
    } else {
        "Namaste $userName $greetingRelation, kaise hain? Aap kya karna chahenge?"
    }
    
    LaunchedEffect(hasGreeted) {
        if (!hasGreeted) {
            ttsManager.speak(greetingText)
            onGreeted()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Top Bar with Language Toggle
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            Button(
                onClick = { onLanguageChange(if (userLanguage == "hi") "en" else "hi") },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFFD54F)),
                shape = RoundedCornerShape(20.dp)
            ) {
                Text(
                    text = if (userLanguage == "hi") "हिंदी (hi)" else "English (en)",
                    color = Color.Black,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Image(
                painter = painterResource(id = R.drawable.sneh_saathi_logo),
                contentDescription = "Sneh Saathi Logo",
                modifier = Modifier.size(160.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            
            val displayGreeting = if (userLanguage == "hi") "नमस्ते $userName $greetingRelation, कैसे हैं?" else "Namaste $userName $greetingRelation, kaise hain?"
            Text(
                text = displayGreeting,
                style = MaterialTheme.typography.titleMedium,
                fontSize = 28.sp,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
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

        com.example.snehsaathi.features.sos.SosButton()
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
