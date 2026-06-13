package com.example.snehsaathi.ui.main

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.core.Contact
import com.example.snehsaathi.core.ContactsManager
import com.example.snehsaathi.core.UserProfile
import com.example.snehsaathi.core.UserProfileManager
import androidx.compose.ui.platform.LocalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OnboardingScreen(onFinish: () -> Unit) {
    val context = LocalContext.current
    
    // Step 1 state
    var userName by remember { mutableStateOf("") }
    var userRelation by remember { mutableStateOf("") }
    
    // Step 2 state
    var contactName by remember { mutableStateOf("") }
    var contactNumber by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf("") }
    
    var currentStep by remember { mutableStateOf(1) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (currentStep == 1) {
            Text(
                text = "Welcome to Sneh Saathi",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF5D4037)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "आप कौन हैं? (Who are you?)",
                fontSize = 20.sp,
                color = Color.DarkGray
            )
            Spacer(modifier = Modifier.height(24.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ProfileOption(
                    title = "👴 दादा जी (Dada ji)",
                    isSelected = userRelation == "Dada",
                    onClick = { userRelation = "Dada" }
                )
                ProfileOption(
                    title = "👵 दादी जी (Dadi ji)",
                    isSelected = userRelation == "Dadi",
                    onClick = { userRelation = "Dadi" }
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            OutlinedTextField(
                value = userName,
                onValueChange = { userName = it },
                label = { Text("आपका नाम (Your Name)") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            if (errorMessage.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(errorMessage, color = Color.Red)
            }

            Spacer(modifier = Modifier.height(32.dp))
            Button(
                onClick = {
                    if (userName.isNotBlank() && userRelation.isNotBlank()) {
                        errorMessage = ""
                        currentStep = 2
                    } else {
                        errorMessage = "कृपया अपना नाम और पहचान चुनें।"
                    }
                },
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) {
                Text("आगे बढ़ें (Next)", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            }

        } else if (currentStep == 2) {
            Text(
                text = "Emergency Contact",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF5D4037)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Please add at least one important contact for emergencies (SOS).",
                fontSize = 18.sp,
                color = Color.Gray,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            Spacer(modifier = Modifier.height(32.dp))

            OutlinedTextField(
                value = contactName,
                onValueChange = { contactName = it },
                label = { Text("Contact Name (e.g., Son, Daughter)") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            OutlinedTextField(
                value = contactNumber,
                onValueChange = { contactNumber = it },
                label = { Text("Phone Number") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                    keyboardType = androidx.compose.ui.text.input.KeyboardType.Phone
                )
            )

            if (errorMessage.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(errorMessage, color = Color.Red)
            }

            Spacer(modifier = Modifier.height(32.dp))

            Button(
                onClick = {
                    if (contactName.isNotBlank() && contactNumber.isNotBlank()) {
                        UserProfileManager.saveProfile(context, UserProfile(userName, userRelation))
                        ContactsManager.saveContact(context, Contact(contactName, contactNumber))
                        onFinish()
                    } else {
                        errorMessage = "Please enter both name and number."
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) {
                Text("Save & Finish", fontSize = 20.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun ProfileOption(title: String, isSelected: Boolean, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(8.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) Color(0xFFDCF8C6) else Color(0xFFF5F5F5)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isSelected) 8.dp else 2.dp)
    ) {
        Box(
            modifier = Modifier.padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = title,
                fontSize = 18.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = if (isSelected) Color(0xFF2E7D32) else Color.Black
            )
        }
    }
}
