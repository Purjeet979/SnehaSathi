package com.example.snehsaathi.features.scamshield

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ScamWarningDialog(triggerReason: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Color(0xFFFFE4E1),  // Soft red — alarming but not harsh
        icon = { Icon(Icons.Filled.Warning, contentDescription = null, tint = Color.Red, modifier = Modifier.size(48.dp)) },
        title = {
            Text(
                text = "⚠️ सावधान! Scam हो सकता है!",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
        },
        text = {
            Text(
                text = "कोई आपसे OTP, पैसे, या बैंक जानकारी मांग रहा है।\nकिसी को कुछ मत बताइए।\nअपने बेटे/बेटी को अभी फ़ोन करें।\n($triggerReason)",
                fontSize = 18.sp,
                lineHeight = 26.sp,
                textAlign = TextAlign.Center
            )
        },
        confirmButton = {
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFD32F2F)),
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("समझ गई, सुरक्षित हूँ", fontSize = 18.sp, color = Color.White)
            }
        }
    )
}
