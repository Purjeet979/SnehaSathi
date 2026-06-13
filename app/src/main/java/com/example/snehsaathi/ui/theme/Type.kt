package com.example.snehsaathi.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val SnehSaathiTypography = Typography(
    // Primary conversation text — what AI says
    bodyLarge = TextStyle(
        fontFamily = FontFamily.Default, // Using system default as fallback
        fontSize = 22.sp,          // Minimum. Not 18sp.
        lineHeight = 34.sp,        // 1.5x line height — critical for cataracts
        letterSpacing = 0.3.sp     // Slight spacing helps aging eyes track lines
    ),
    // Button labels
    labelLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 20.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.5.sp
    ),
    // Section headers (sparingly used)
    titleMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontSize = 24.sp,
        fontWeight = FontWeight.Bold,
        color = Color(0xFF5D4037)   // Warm brown — not harsh black
    )
)
