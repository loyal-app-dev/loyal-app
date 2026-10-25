import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF1F4E3B);
  static const Color darkCardGreen = Color(0xFF16382B);
  static const Color softGreenBg = Color(0xFFE9F0EC);
  static const Color accentCoral = Color(0xFFE06D53);
  static const Color softCoralBg = Color(0xFFFDF0EC);
  static const Color accentGold = Color(0xFFE2A94B);
  static const Color softGoldBg = Color(0xFFFCF6E8);
  static const Color softPurpleBg = Color(0xFFF2EFF9);
  static const Color accentPurple = Color(0xFF6B5B95);
  static const Color backgroundCream = Color(0xFFF6F7F4);
  static const Color darkText = Color(0xFF141E19);
  static const Color mutedText = Color(0xFF6E7A73);
  static const Color borderLight = Color(0xFFE4E7E4);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentCoral,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
      ),
    );
  }
}