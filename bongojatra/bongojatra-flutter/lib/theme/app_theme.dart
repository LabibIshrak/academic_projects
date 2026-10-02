import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Bangladesh national flag colors
  static const Color primary = Color(0xFF006A4E); // Bangladesh green
  static const Color secondary = Color(0xFFF42A41); // Bangladesh red

  // Additional theme colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F9FC);
  static const Color textDark = Color(0xFF0D1B2A);
  static const Color textGrey = Color(0xFF6B7C93);
  static const Color textPrimary = textDark;
  static const Color textSecondary = textGrey;
  static const Color divider = Color(0xFFE5E7EB);

  // Transport strip colors
  static const Color busStrip = Color(0xFFF4A22A); // Amber
  static const Color trainStrip = Color(0xFF264653); // Navy
  static const Color launchStrip = Color(0xFF2A9D8F); // Teal
  static const Color launchColor = launchStrip;

  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static Color getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'BUS':
        return busStrip;
      case 'TRAIN':
        return trainStrip;
      case 'LAUNCH':
        return launchStrip;
      default:
        return primary;
    }
  }

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge:
            GoogleFonts.outfit(color: textDark, fontWeight: FontWeight.bold),
        displayMedium:
            GoogleFonts.outfit(color: textDark, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.outfit(color: textDark),
        bodyMedium: GoogleFonts.outfit(color: textDark),
        bodySmall: GoogleFonts.outfit(color: textGrey),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textGrey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: textGrey),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }
}
