import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Green Palette
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color darkGreen = Color(0xFF27AE60);
  static const Color lightGreen = Color(0xFF52D98A);

  // Secondary Colors - Soft Blue Palette
  static const Color primaryBlue = Color(0xFF3498DB);
  static const Color darkBlue = Color(0xFF2980B9);
  static const Color lightBlue = Color(0xFF5DADE2);

  // Accent Colors
  static const Color accentOrange = Color(0xFFF39C12);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentYellow = Color(0xFFF1C40F);

  // Neutral Colors
  static const Color backgroundWhite = Color(0xFFF8FAFB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textGrey = Color(0xFF7F8C8D);
  static const Color borderGrey = Color(0xFFECF0F1);

  // Gradient Combinations
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, darkGreen],
    stops: [0.0, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBlue, primaryBlue],
    stops: [0.3, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFB)],
    stops: [0.0, 1.0],
  );

  // Status Colors
  static const Color statusGood = Color(0xFF2ECC71);
  static const Color statusWarning = Color(0xFFF39C12);
  static const Color statusDanger = Color(0xFFE74C3C);
  static const Color statusHarvested = Color(0xFF3498DB);
}
