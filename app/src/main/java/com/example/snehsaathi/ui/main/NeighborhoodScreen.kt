package com.example.snehsaathi.ui.main

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import coil.compose.AsyncImage
import com.example.snehsaathi.core.TextToSpeechManager
import com.example.snehsaathi.features.neighborhood.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NeighborhoodScreen(
    ttsManager: TextToSpeechManager,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var selectedTab by remember { mutableStateOf(0) }
    var neighbors by remember { mutableStateOf<List<NeighborProfile>>(emptyList()) }
    var messages by remember { mutableStateOf<List<NeighborMessage>>(emptyList()) }
    var moments by remember { mutableStateOf<List<PalMoment>>(emptyList()) }
    var receivedBhajans by remember { mutableStateOf<List<BhajanShare>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    
    // Dialog states
    var showMessageDialog by remember { mutableStateOf<String?>(null) }
    var messageText by remember { mutableStateOf("") }
    var showMomentDialog by remember { mutableStateOf(false) }
    var momentCaption by remember { mutableStateOf("") }
    var momentImageUri by remember { mutableStateOf<Uri?>(null) }
    var showBhajanDialog by remember { mutableStateOf<String?>(null) } // neighborId
    var showBhajanLibrary by remember { mutableStateOf(false) }
    var bhajanVoiceNote by remember { mutableStateOf("") }
    var selectedBhajan by remember { mutableStateOf<Bhajan?>(null) }
    var showCameraOption by remember { mutableStateOf(false) }

    // Camera/Gallery launchers
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            momentImageUri = it
            showMomentDialog = true
        }
    }
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicturePreview()
    ) { bitmap ->
        bitmap?.let {
            // Convert bitmap to URI and use it
            val path = android.content.ContentValues().apply {
                put(android.provider.MediaStore.Images.Media.TITLE, "moment_${System.nanoTime()}")
            }
            val uri = context.contentResolver.insert(
                android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, path
            )
            uri?.let {
                context.contentResolver.openOutputStream(it)?.use { out ->
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
                }
                momentImageUri = it
                showMomentDialog = true
            }
        }
    }

    // Permission launcher for camera
    val cameraPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) cameraLauncher.launch(null)
    }

    LaunchedEffect(Unit) {
        isLoading = true
        NeighborhoodManager.registerUser(context)
        neighbors = NeighborhoodManager.getNearbyNeighbors(context)
        messages = NeighborhoodManager.getMessagesForUser(context)
        moments = NeighborhoodManager.getActiveMoments(context)
        receivedBhajans = NeighborhoodManager.getReceivedBhajans(context)
        isLoading = false
    }

    // Periodic refresh
    LaunchedEffect(selectedTab) {
        while (true) {
            kotlinx.coroutines.delay(20000)
            when (selectedTab) {
                0 -> moments = NeighborhoodManager.getActiveMoments(context)
                1 -> neighbors = NeighborhoodManager.getNearbyNeighbors(context)
                3 -> messages = NeighborhoodManager.getMessagesForUser(context)
            }
            NeighborhoodManager.updateLastActive(context)
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
            }
            Spacer(Modifier.width(8.dp))
            Text("पड़ोसी संग", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color(0xFF5D4037))
        }

        Spacer(Modifier.height(8.dp))

        // Tabs
        TabRow(
            selectedTabIndex = selectedTab,
            containerColor = Color(0xFFFFF3E0),
            contentColor = Color(0xFF5D4037),
            divider = { HorizontalDivider(color = Color(0xFFD7CCC8)) }
        ) {
            Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("📸 पल", fontWeight = FontWeight.Bold) })
            Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("👥 पड़ोसी", fontWeight = FontWeight.Bold) })
            Tab(selected = selectedTab == 2, onClick = { selectedTab = 2 }, text = { Text("📿 भजन", fontWeight = FontWeight.Bold) })
            Tab(selected = selectedTab == 3, onClick = { selectedTab = 3 }, text = { Text("💬 (${messages.size})", fontWeight = FontWeight.Bold) })
        }

        Spacer(Modifier.height(12.dp))

        if (isLoading) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Color(0xFF4CAF50))
            }
            return@Column
        }

        when (selectedTab) {
            0 -> MomentsTab(
                moments = moments,
                onAddClick = { showCameraOption = true },
                onReact = { momentId, emoji ->
                    scope.launch { NeighborhoodManager.reactToMoment(context, momentId, emoji) }
                },
                ttsManager = ttsManager
            )
            1 -> NeighborsTab(
                neighbors = neighbors,
                onSendMessage = { neighborId ->
                    showMessageDialog = neighborId
                },
                onSayHello = { neighbor ->
                    scope.launch {
                        ttsManager.speak("नमस्ते ${neighbor.name}! ${neighbor.greeting}")
                    }
                },
                onShareBhajan = { neighborId ->
                    showBhajanDialog = neighborId
                    showBhajanLibrary = true
                }
            )
            2 -> BhajansTab(
                bhajans = receivedBhajans,
                onOpenLibrary = { showBhajanLibrary = true },
                ttsManager = ttsManager
            )
            3 -> MessagesTab(
                messages = messages,
                onRead = { msg -> ttsManager.speak("${msg.fromName} ने कहा: ${msg.text}") }
            )
        }
    }

    // --- DIALOGS ---

    // Camera/Gallery options
    if (showCameraOption) {
        AlertDialog(
            onDismissRequest = { showCameraOption = false },
            title = { Text("📸 पल जोड़ें", fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    TextButton(
                        onClick = { showCameraOption = false; imagePickerLauncher.launch("image/*") },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Filled.PhotoLibrary, null)
                        Spacer(Modifier.width(8.dp))
                        Text("गैलरी से चुनें", fontSize = 18.sp)
                    }
                    TextButton(
                        onClick = {
                            showCameraOption = false
                            if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                                cameraLauncher.launch(null)
                            } else {
                                cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Filled.CameraAlt, null)
                        Spacer(Modifier.width(8.dp))
                        Text("कैमरा से लें", fontSize = 18.sp)
                    }
                }
            },
            confirmButton = {},
            dismissButton = { OutlinedButton(onClick = { showCameraOption = false }) { Text("रद्द करें") } }
        )
    }

    // Moment caption dialog
    if (showMomentDialog && momentImageUri != null) {
        AlertDialog(
            onDismissRequest = { showMomentDialog = false; momentImageUri = null },
            title = { Text("पल का विवरण", fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    AsyncImage(
                        model = momentImageUri,
                        contentDescription = "Selected",
                        modifier = Modifier.fillMaxWidth().height(200.dp).clip(RoundedCornerShape(12.dp)),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = momentCaption,
                        onValueChange = { momentCaption = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("कैप्शन (जैसे: आज का नाश्ता)") },
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            momentImageUri?.let { uri ->
                                NeighborhoodManager.uploadMoment(context, uri, momentCaption)
                                ttsManager.speak("आपका पल साझा कर दिया गया!")
                                moments = NeighborhoodManager.getActiveMoments(context)
                            }
                        }
                        showMomentDialog = false
                        momentImageUri = null
                        momentCaption = ""
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                ) { Text("साझा करें") }
            },
            dismissButton = { OutlinedButton(onClick = { showMomentDialog = false; momentImageUri = null }) { Text("रद्द करें") } }
        )
    }

    // Message dialog
    if (showMessageDialog != null) {
        val target = neighbors.find { it.id == showMessageDialog }
        AlertDialog(
            onDismissRequest = { showMessageDialog = null; messageText = "" },
            title = { Text("${target?.name ?: ""} को संदेश", fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    OutlinedTextField(
                        value = messageText,
                        onValueChange = { messageText = it },
                        modifier = Modifier.fillMaxWidth().height(120.dp),
                        placeholder = { Text("Hinglish में लिखें...") },
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (messageText.isNotBlank() && showMessageDialog != null) {
                            scope.launch {
                                NeighborhoodManager.sendMessage(context, showMessageDialog!!, messageText)
                                ttsManager.speak("संदेश भेज दिया!")
                            }
                            messageText = ""; showMessageDialog = null
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                ) { Text("भेजें") }
            },
            dismissButton = { OutlinedButton(onClick = { showMessageDialog = null; messageText = "" }) { Text("रद्द करें") } }
        )
    }

    // Bhajan share dialog
    if (showBhajanDialog != null && showBhajanLibrary) {
        val target = neighbors.find { it.id == showBhajanDialog }
        AlertDialog(
            onDismissRequest = {
                showBhajanLibrary = false
                showBhajanDialog = null
                selectedBhajan = null
                bhajanVoiceNote = ""
            },
            title = { Text("📿 ${target?.name ?: ""} को भजन भेजें") },
            text = {
                Column {
                    LazyColumn(Modifier.height(300.dp)) {
                        items(NeighborhoodManager.getBhajanLibrary()) { bhajan ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp)
                                    .clickable {
                                        selectedBhajan = bhajan
                                        bhajanVoiceNote = ""
                                    },
                                shape = RoundedCornerShape(8.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = if (selectedBhajan?.id == bhajan.id) Color(0xFFDCF8C6) else Color(0xFFFFFFFF)
                                )
                            ) {
                                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Text("🎵", fontSize = 24.sp)
                                    Spacer(Modifier.width(12.dp))
                                    Column(Modifier.weight(1f)) {
                                        Text(bhajan.title, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                        Text("${bhajan.category} • ${bhajan.duration}", fontSize = 12.sp, color = Color.Gray)
                                    }
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = bhajanVoiceNote,
                        onValueChange = { bhajanVoiceNote = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("एक छोटा संदेश (वैकल्पिक)") },
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val bhajan = selectedBhajan
                        if (bhajan != null && showBhajanDialog != null) {
                            scope.launch {
                                NeighborhoodManager.shareBhajan(context, showBhajanDialog!!, bhajan.id, bhajan.title, bhajanVoiceNote)
                                ttsManager.speak("${bhajan.title} ${target?.name ?: ""} को भेज दिया!")
                            }
                        }
                        showBhajanLibrary = false
                        showBhajanDialog = null
                        selectedBhajan = null
                        bhajanVoiceNote = ""
                    },
                    enabled = selectedBhajan != null,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                ) { Text("भेजें") }
            },
            dismissButton = {
                OutlinedButton(onClick = {
                    showBhajanLibrary = false
                    showBhajanDialog = null
                    selectedBhajan = null
                    bhajanVoiceNote = ""
                }) { Text("रद्द करें") }
            }
        )
    }
}

@Composable
fun MomentsTab(moments: List<PalMoment>, onAddClick: () -> Unit, onReact: (String, String) -> Unit, ttsManager: TextToSpeechManager) {
    Column {
        // Add Moment Button
        Button(
            onClick = onAddClick,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF81C784))
        ) {
            Icon(Icons.Filled.AddAPhoto, null, tint = Color.White)
            Spacer(Modifier.width(8.dp))
            Text("📸 नया पल साझा करें", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)
        }

        Spacer(Modifier.height(12.dp))

        if (moments.isEmpty()) {
            EmptyState("📷", "आज अभी कोई पल नहीं", "पहला पल साझा करने के लिए ऊपर बटन दबाएं। फोटो 24 घंटे के लिए दिखेगी।")
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                items(moments) { moment ->
                    MomentCard(moment = moment, onReact = onReact, ttsManager = ttsManager)
                }
            }
        }
    }
}

@Composable
fun MomentCard(moment: PalMoment, onReact: (String, String) -> Unit, ttsManager: TextToSpeechManager) {
    val relationLabel = if (moment.userRelation == "Dada") "दादा जी" else "दादी जी"
    val timeAgo = getTimeAgo(moment.timestamp)
    val emojiList = listOf("❤️", "🙏", "👌", "😊", "👍")
    var showEmojiPicker by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column {
            // User info row
            Row(
                modifier = Modifier.fillMaxWidth().padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = CircleShape,
                    color = Color(0xFFFFF3E0)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(if (moment.userRelation == "Dada") "👴" else "👵", fontSize = 20.sp)
                    }
                }
                Spacer(Modifier.width(8.dp))
                Column(Modifier.weight(1f)) {
                    Text("${moment.userName} $relationLabel", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    Text("$timeAgo • ${24 - ((System.currentTimeMillis() - moment.timestamp) / 3600000).toInt()}hr बाकी", fontSize = 12.sp, color = Color.Gray)
                }
            }

            // Image
            AsyncImage(
                model = moment.imageUrl,
                contentDescription = moment.caption,
                modifier = Modifier.fillMaxWidth().height(300.dp).clickable {
                    ttsManager.speak("${moment.userName} का पल: ${moment.caption.ifEmpty { "कोई कैप्शन नहीं" }}")
                },
                contentScale = ContentScale.Crop
            )

            // Caption
            if (moment.caption.isNotBlank()) {
                Text(
                    text = moment.caption,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    fontSize = 18.sp,
                    color = Color(0xFF5D4037)
                )
            }

            // Reactions
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Show existing reactions
                moment.reactions.forEach { (emoji, users) ->
                    if (users.isNotEmpty()) {
                        Surface(
                            modifier = Modifier.padding(end = 4.dp),
                            shape = RoundedCornerShape(16.dp),
                            color = Color(0xFFF5F5F5)
                        ) {
                            Row(Modifier.padding(horizontal = 8.dp, vertical = 2.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text(emoji, fontSize = 16.sp)
                                Text("${users.size}", fontSize = 12.sp, color = Color.Gray)
                            }
                        }
                    }
                }

                Spacer(Modifier.weight(1f))

                // React button
                IconButton(onClick = { showEmojiPicker = !showEmojiPicker }, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Filled.EmojiEmotions, "React", tint = Color(0xFFFFA000), modifier = Modifier.size(20.dp))
                }
            }

            // Emoji picker
            if (showEmojiPicker) {
                LazyRow(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(emojiList) { emoji ->
                        Surface(
                            modifier = Modifier.clickable {
                                onReact(moment.id, emoji)
                                showEmojiPicker = false
                            },
                            shape = CircleShape,
                            color = Color(0xFFF5F5F5)
                        ) {
                            Text(emoji, modifier = Modifier.padding(8.dp), fontSize = 24.sp)
                        }
                    }
                }
            }

            Spacer(Modifier.height(4.dp))
        }
    }
}

@Composable
fun NeighborsTab(neighbors: List<NeighborProfile>, onSendMessage: (String) -> Unit, onSayHello: (NeighborProfile) -> Unit, onShareBhajan: (String) -> Unit) {
    if (neighbors.isEmpty()) {
        EmptyState("🧑‍🤝‍🧑", "अभी कोई पड़ोसी ऑनलाइन नहीं", "जब कोई और बुजुर्ग इस ऐप का उपयोग करेगा तो वे यहाँ दिखाई देंगे।")
    } else {
        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(neighbors) { neighbor ->
                NeighborCard2(
                    neighbor = neighbor,
                    onSendMessage = { onSendMessage(neighbor.id) },
                    onSayHello = { onSayHello(neighbor) },
                    onShareBhajan = { onShareBhajan(neighbor.id) }
                )
            }
        }
    }
}

@Composable
fun NeighborCard2(neighbor: NeighborProfile, onSendMessage: () -> Unit, onSayHello: () -> Unit, onShareBhajan: () -> Unit) {
    val relationLabel = if (neighbor.relation == "Dada") "दादा जी" else "दादी जी"
    val isOnline = System.currentTimeMillis() - neighbor.lastActive < 300000

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = if (isOnline) Color(0xFFE8F5E9) else Color(0xFFF5F5F5))
    ) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            // Avatar
            Box {
                Surface(Modifier.size(48.dp), shape = CircleShape, color = Color(0xFFFFF3E0)) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(if (neighbor.relation == "Dada") "👴" else "👵", fontSize = 24.sp)
                    }
                }
                if (isOnline) {
                    Surface(Modifier.size(14.dp).align(Alignment.BottomEnd), shape = CircleShape, color = Color(0xFF4CAF50)) {}
                }
            }
            Spacer(Modifier.width(12.dp))

            Column(Modifier.weight(1f)) {
                Text("${neighbor.name} $relationLabel", fontWeight = FontWeight.Bold, fontSize = 17.sp)
                Text(
                    text = buildString {
                        append(getTimeAgo(neighbor.lastActive))
                        if (neighbor.city.isNotBlank()) append(" | ${neighbor.city}")
                    },
                    fontSize = 13.sp, color = Color.Gray
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                FilledTonalButton(onClick = onSayHello, modifier = Modifier.height(32.dp), shape = RoundedCornerShape(16.dp)) {
                    Icon(Icons.Filled.VolumeUp, null, modifier = Modifier.size(14.dp))
                }
                FilledTonalButton(onClick = onSendMessage, modifier = Modifier.height(32.dp), shape = RoundedCornerShape(16.dp)) {
                    Icon(Icons.Filled.Send, null, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(2.dp))
                    Text("संदेश", fontSize = 11.sp)
                }
                FilledTonalButton(onClick = onShareBhajan, modifier = Modifier.height(32.dp), shape = RoundedCornerShape(16.dp), colors = ButtonDefaults.filledTonalButtonColors(containerColor = Color(0xFFFFCC80))) {
                    Text("🎵", fontSize = 12.sp)
                }
            }
        }
    }
}

@Composable
fun BhajansTab(bhajans: List<BhajanShare>, onOpenLibrary: () -> Unit, ttsManager: TextToSpeechManager) {
    Column {
        Button(
            onClick = onOpenLibrary,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFFCC80))
        ) {
            Icon(Icons.Filled.LibraryMusic, null, tint = Color(0xFF5D4037))
            Spacer(Modifier.width(8.dp))
            Text("📿 भजन भेजें (Library)", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF5D4037))
        }

        Spacer(Modifier.height(16.dp))
        Text("मिले हुए भजन", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = Color(0xFF5D4037))

        if (bhajans.isEmpty()) {
            EmptyState("🎵", "अभी कोई भजन नहीं मिला", "जब कोई पड़ोसी आपको भजन भेजेगा तो वह यहाँ दिखेगा।")
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(bhajans) { share ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF8E1))
                    ) {
                        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text("${share.fromName} ने भेजा", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color(0xFF5D4037))
                                Text("🎵 ${share.bhajanTitle}", fontSize = 16.sp)
                                if (share.voiceNoteText.isNotBlank()) {
                                    Text("📝 ${share.voiceNoteText}", fontSize = 13.sp, color = Color.Gray)
                                }
                            }
                            IconButton(onClick = { ttsManager.speak("${share.fromName} ने ${share.bhajanTitle} भेजा। ${share.voiceNoteText}") }) {
                                Icon(Icons.Filled.VolumeUp, null, tint = Color(0xFF4CAF50))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MessagesTab(messages: List<NeighborMessage>, onRead: (NeighborMessage) -> Unit) {
    if (messages.isEmpty()) {
        EmptyState("📭", "कोई संदेश नहीं", "जब कोई पड़ोसी आपको संदेश भेजेगा तो वह यहाँ दिखाई देगा।")
    } else {
        LazyColumn(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            items(messages) { msg ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = if (!msg.isRead) Color(0xFFFFF9C4) else Color.White
                    )
                ) {
                    Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text("${msg.fromName} से", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Color(0xFF5D4037))
                            Text(msg.text, fontSize = 15.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
                            Text(formatTimestamp(msg.timestamp), fontSize = 11.sp, color = Color.Gray)
                        }
                        IconButton(onClick = { onRead(msg) }) {
                            Icon(Icons.Filled.VolumeUp, null, tint = Color(0xFF4CAF50))
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun EmptyState(emoji: String, title: String, subtitle: String) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(emoji, fontSize = 64.sp)
            Spacer(Modifier.height(16.dp))
            Text(title, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color(0xFF5D4037), textAlign = TextAlign.Center)
            Spacer(Modifier.height(8.dp))
            Text(subtitle, fontSize = 15.sp, color = Color.Gray, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 32.dp))
        }
    }
}

private fun getTimeAgo(timestamp: Long): String {
    val diff = System.currentTimeMillis() - timestamp
    return when {
        diff < 60000 -> "अभी"
        diff < 3600000 -> "${diff / 60000} मिनट पहले"
        diff < 86400000 -> "${diff / 3600000} घंटे पहले"
        else -> "${diff / 86400000} दिन पहले"
    }
}

private fun formatTimestamp(timestamp: Long): String {
    val sdf = java.text.SimpleDateFormat("dd MMM, h:mm a", java.util.Locale.getDefault())
    return sdf.format(java.util.Date(timestamp))
}
