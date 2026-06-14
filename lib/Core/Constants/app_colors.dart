import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — playful, high-contrast
  static const Color primary = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color accent = Color(0xFFFFE66D);
  static const Color purple = Color(0xFF9B59B6);
  static const Color orange = Color(0xFFFF8C42);
  static const Color green = Color(0xFF2ECC71);

  // Background shades
  static const Color bgLight = Color(0xFFFFF9F0);
  static const Color bgDark = Color(0xFF2C2C54);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color canvasBg = Color(0xFFF0F8FF);

  // Writing canvas
  static const Color strokeColor = Color(0xFF2C3E50);
  static const Color guideColor = Color(0xFFD0E8FF);
  static const Color guideStroke = Color(0xFFB0CCEE);
  static const Color successColor = Color(0xFF27AE60);
  static const Color errorColor = Color(0xFFE74C3C);

  // Language theme colours
  static const Map<String, Color> languageColors = {
    'english': Color(0xFF3498DB),
    'malayalam': Color(0xFF8E44AD),
    'hindi': Color(0xFFE67E22),
    'tamil': Color(0xFF27AE60),
    'numbers': Color(0xFFE74C3C),
  };

  // Text
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF7F8C8D);
  static const Color textWhite = Color(0xFFFFFFFF);
}
