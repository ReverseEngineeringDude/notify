import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6366F1); // Indigo
  static const secondaryColor = Color(0xFFEC4899); // Pink
  static const scaffoldBackground = Color(0xFFF3F4F6); // Cool Gray

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto', // Using default, but could be swapped for Google Fonts if added
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      background: scaffoldBackground,
    ),
    scaffoldBackgroundColor: scaffoldBackground,
    
    // Modern Typography using standard Flutter hierarchy
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0, // Using manual shadows for glass cards, but default flat for others
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.4),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}
