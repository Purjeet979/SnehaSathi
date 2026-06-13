package com.example.snehsaathi.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.snehsaathi.ui.theme.SnehSaathiColors

@Composable
fun DadiChatBubble(
    message: String,
    isAI: Boolean,
    onReplay: () -> Unit  // Tap to hear again
) {
    Row(
        horizontalArrangement = if (isAI) Arrangement.Start else Arrangement.End,
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
    ) {
        if (isAI) {
            // AI bubble — prominent replay button
            Column {
                Box(
                    modifier = Modifier
                        .background(
                            Color(0xFFFFF3E0),
                            RoundedCornerShape(16.dp, 16.dp, 16.dp, 4.dp)
                        )
                        .padding(16.dp)
                        .widthIn(max = 280.dp)
                ) {
                    Text(
                        message,
                        fontSize = 20.sp,
                        lineHeight = 30.sp,
                        color = SnehSaathiColors.textPrimary
                    )
                }
                // "फिर सुनाओ" button — always visible under AI message
                TextButton(onClick = onReplay) {
                    Icon(Icons.Filled.Replay, null, tint = SnehSaathiColors.actionSecondary)
                    Spacer(Modifier.width(4.dp))
                    Text("फिर सुनाओ", fontSize = 16.sp, color = SnehSaathiColors.actionSecondary)
                }
            }
        } else {
            // User bubble — simple, no extra controls
            Box(
                modifier = Modifier
                    .background(
                        SnehSaathiColors.actionPrimary,
                        RoundedCornerShape(16.dp, 16.dp, 4.dp, 16.dp)
                    )
                    .padding(16.dp)
                    .widthIn(max = 280.dp)
            ) {
                Text(message, fontSize = 20.sp, lineHeight = 30.sp, color = Color.White)
            }
        }
    }
}
