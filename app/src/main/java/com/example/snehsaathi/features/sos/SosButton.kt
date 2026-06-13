package com.example.snehsaathi.features.sos

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.telephony.SmsManager
import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.example.snehsaathi.core.ContactsManager
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun SosButton() {
    val context = LocalContext.current
    val permissionsState = rememberMultiplePermissionsState(
        permissions = listOf(
            Manifest.permission.CALL_PHONE,
            Manifest.permission.SEND_SMS,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
    )
    var showConfirm by remember { mutableStateOf(false) }

    Button(
        onClick = { showConfirm = true },
        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFD32F2F)),
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp),
        shape = RoundedCornerShape(16.dp)
    ) {
        Icon(Icons.Filled.Warning, contentDescription = "SOS", modifier = Modifier.size(32.dp))
        Spacer(Modifier.width(12.dp))
        Text("SOS — मदद चाहिए", fontSize = 22.sp, fontWeight = FontWeight.Bold)
    }

    if (showConfirm) {
        AlertDialog(
            onDismissRequest = { showConfirm = false },
            title = { Text("क्या आपको मदद चाहिए?", fontSize = 20.sp) },
            confirmButton = {
                Button(
                    onClick = {
                        showConfirm = false
                        if (permissionsState.allPermissionsGranted) {
                            executeSos(context)
                        } else {
                            permissionsState.launchMultiplePermissionRequest()
                            Toast.makeText(context, "Permissions required for SOS", Toast.LENGTH_SHORT).show()
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                ) { Text("हाँ, मदद भेजो", fontSize = 18.sp) }
            },
            dismissButton = {
                OutlinedButton(onClick = { showConfirm = false }) {
                    Text("नहीं, ठीक हूँ", fontSize = 18.sp)
                }
            }
        )
    }
}

private fun executeSos(context: Context) {
    Toast.makeText(context, "Sending SOS and calling 112...", Toast.LENGTH_LONG).show()
    
    var locationLink = "Location not available"
    if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val location: Location? = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            
        if (location != null) {
            locationLink = "https://maps.google.com/?q=\${location.latitude},\${location.longitude}"
        }
    }

    val contacts = ContactsManager.getContacts(context)
    val message = "SOS! I need help immediately. Location: \$locationLink"

    if (contacts.isNotEmpty()) {
        GlobalScope.launch(Dispatchers.IO) {
            val smsManager = context.getSystemService(SmsManager::class.java)
            for (contact in contacts) {
                try {
                    smsManager.sendTextMessage(contact.number, null, message, null, null)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    // Call 112 (National Emergency Number in India)
    val callIntent = Intent(Intent.ACTION_CALL, Uri.parse("tel:112"))
    callIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    try {
        context.startActivity(callIntent)
    } catch (e: Exception) {
        e.printStackTrace()
    }
}
