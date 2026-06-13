package com.example.snehsaathi.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

// Force light theme with Sneh Saathi colors.
// "Dark mode: Low contrast is dangerous for cataracts — never offer this"
private val LightColorScheme = lightColorScheme(
    primary = SnehSaathiColors.actionPrimary,
    onPrimary = SnehSaathiColors.actionPrimaryText,
    secondary = SnehSaathiColors.actionSecondary,
    onSecondary = SnehSaathiColors.actionSecondaryText,
    background = SnehSaathiColors.backgroundPrimary,
    onBackground = SnehSaathiColors.textPrimary,
    surface = SnehSaathiColors.backgroundCard,
    onSurface = SnehSaathiColors.textPrimary,
    error = SnehSaathiColors.sosRed,
    onError = SnehSaathiColors.actionPrimaryText
)

@Composable
fun SnehSaathiTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        typography = SnehSaathiTypography,
        content = content
    )
}