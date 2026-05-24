import 'package:flutter/material.dart';

/// iOS / Apple HIG inspired palette. Values come from Apple's published
/// systemColors for the Light appearance, so the look is recognisable to any
/// Mac/iOS user without us having to hand-tune contrast.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFFF2F2F7); // systemGroupedBackground
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF9F9FB);
  static const Color border = Color(0xFFE5E5EA); // systemGray5
  static const Color accent = Color(0xFF007AFF); // systemBlue
  static const Color textPrimary = Color(0xFF1C1C1E); // label
  static const Color textSecondary = Color(0xFF6C6C70); // secondaryLabel
  static const Color error = Color(0xFFFF3B30); // systemRed
  static const Color success = Color(0xFF34C759); // systemGreen

  /// Subtle drop shadow color used on cards / dialogs. Black with low alpha
  /// matches macOS Sonoma elevation hint.
  static const Color shadow = Color(0x14000000); // 8% black
}
