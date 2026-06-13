package com.example.snehsaathi.ui.theme

import androidx.compose.ui.graphics.Color

object SnehSaathiColors {
    // Backgrounds — layered warmth
    val backgroundPrimary   = Color(0xFFFFF8F0)  // Warm cream — keep as is
    val backgroundCard      = Color(0xFFFFF3E0)  // Slightly deeper card
    val backgroundSafe      = Color(0xFFE8F5E9)  // Soft green for "safe/connected" states
    val backgroundWarning   = Color(0xFFFFEBEE)  // Soft red for Scam Shield

    // Primary actions
    val actionPrimary       = Color(0xFFE65100)  // Deep marigold orange — auspicious
    val actionPrimaryText   = Color(0xFFFFFFFF)
    val actionSecondary     = Color(0xFF6D4C41)  // Warm brown
    val actionSecondaryText = Color(0xFFFFFFFF)

    // SOS — must be unmistakable
    val sosRed              = Color(0xFFB71C1C)  // Deep red, not neon
    val sosBackground       = Color(0xFFFFCDD2)

    // Mic button states
    val micIdle             = Color(0xFF795548)  // Brown — calm
    val micListening        = Color(0xFFE65100)  // Orange pulse — active
    val micProcessing       = Color(0xFFBCAAA4)  // Greyed — wait state

    // Text
    val textPrimary         = Color(0xFF2C1810)  // Warm dark brown
    val textSecondary       = Color(0xFF6D4C41)  // Medium brown
    val textHint            = Color(0xFF9E9E9E)  // Only for placeholder
}
