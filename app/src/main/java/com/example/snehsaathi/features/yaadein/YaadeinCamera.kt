package com.example.snehsaathi.features.yaadein

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.ui.theme.SnehSaathiColors

@Composable
fun YaadeinCaptureScreen(
    onCapture: () -> Unit
) {
    // In production, this would wrap CameraX Preview
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.BottomCenter
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(bottom = 32.dp)
        ) {
            Button(
                onClick = onCapture,
                colors = ButtonDefaults.buttonColors(containerColor = SnehSaathiColors.actionPrimary),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
                    .padding(horizontal = 24.dp)
            ) {
                Icon(Icons.Filled.CameraAlt, contentDescription = null, modifier = Modifier.size(48.dp))
                Spacer(Modifier.width(16.dp))
                Text("फोटो लें", fontSize = 28.sp)
            }
        }
    }
}
