import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Tech Palette (Professional & Dark)
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue 500
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textWhite = Color(0xFFF8FAFC); // Slate 50
  static const Color textGrey = Color(0xFF94A3B8); // Slate 400

  // Status Colors (Distinct & High Contrast)
  static const Color statusAccepted = Color(0xFFF97316); // Orange 500
  static const Color statusPickup = Color(0xFFEAB308); // Yellow 500
  static const Color statusPickedUp = Color(0xFF0EA5E9); // Sky 500
  static const Color statusOnTheWay = Color(0xFF22C55E); // Green 500
  static const Color statusDelivered = Color(0xFF10B981); // Emerald 500
  static const Color statusCancelled = Color(0xFFEF4444); // Red 500

  // Legacy aliases for compatibility (mapping to new palette)
  static const Color neonLime = statusOnTheWay;
  static const Color electricPurple = primaryBlue;
  static const Color deepSpace = backgroundDark;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
    primaryColor: primaryBlue,
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentAmber,
      surface: Colors.white,
      background: Color(0xFFF1F5F9),
      onBackground: Color(0xFF0F172A),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryBlue,
    cardColor: cardDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentAmber,
      surface: cardDark,
      background: backgroundDark,
      onBackground: textWhite,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
  );

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return statusAccepted;
      case 'pickup':
        return statusPickup;
      case 'picked up':
        return statusPickedUp;
      case 'on the way':
        return statusOnTheWay;
      case 'delivered':
        return statusDelivered;
      case 'cancelled':
        return statusCancelled;
      default:
        return textGrey;
    }
  }
}
