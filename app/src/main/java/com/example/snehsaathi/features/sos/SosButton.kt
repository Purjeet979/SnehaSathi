package com.example.snehsaathi.features.sos

import android.Manifest
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun SosButton(onSosTriggered: () -> Unit) {
    val callPermission = rememberPermissionState(Manifest.permission.CALL_PHONE)
    val smsPermission = rememberPermissionState(Manifest.permission.SEND_SMS)
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
                        if (callPermission.status.isGranted && smsPermission.status.isGranted) {
                            onSosTriggered()
                        } else {
                            callPermission.launchPermissionRequest()
                            smsPermission.launchPermissionRequest()
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
