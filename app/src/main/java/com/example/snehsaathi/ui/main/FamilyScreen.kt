package com.example.snehsaathi.ui.main

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Message
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.core.ContactsManager

@Composable
fun FamilyScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val contacts = remember { ContactsManager.getContacts(context) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Button(
            onClick = onBack, 
            modifier = Modifier
                .padding(bottom = 16.dp)
                .fillMaxWidth()
                .height(60.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF5D4037))
        ) {
            Text("वापस जाएँ (Back)", fontSize = 20.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
        }

        Text(
            text = "परिवार (Family Contacts)",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF5D4037)
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (contacts.isEmpty()) {
            Text("No contacts saved. Please restart the app to add.", fontSize = 18.sp)
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                items(contacts) { contact ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF3E0)),
                        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column {
                                Text(text = contact.name, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                                Text(text = contact.number, fontSize = 16.sp, color = Color.Gray)
                            }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                IconButton(
                                    onClick = {
                                        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:\${contact.number}"))
                                        context.startActivity(intent)
                                    },
                                    modifier = Modifier.background(Color(0xFF4CAF50), RoundedCornerShape(50))
                                ) {
                                    Icon(Icons.Filled.Call, contentDescription = "Call", tint = Color.White)
                                }
                                IconButton(
                                    onClick = {
                                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:\${contact.number}"))
                                        context.startActivity(intent)
                                    },
                                    modifier = Modifier.background(Color(0xFF2196F3), RoundedCornerShape(50))
                                ) {
                                    Icon(Icons.Filled.Message, contentDescription = "Message", tint = Color.White)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
