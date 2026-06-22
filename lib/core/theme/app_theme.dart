import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD84315), // Warm, high-contrast orange/red
        surface: const Color(0xFFFFF8E1), // Warm cream background (was background)
        onSurface: const Color(0xFF212121), // Dark contrast text (was onBackground)
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF212121)),
        titleLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF212121)),
        bodyLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.normal, color: const Color(0xFF212121)),
        bodyMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.normal, color: const Color(0xFF424242)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
