import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, Color(0xFF4ED6C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.secondary, Color(0xFFFFA566)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient header = LinearGradient(
    colors: [Color(0xFF1A2E35), Color(0xFF2EC4B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient royal = LinearGradient(
    colors: [Color(0xFF2EC4B6), Color(0xFF1A2E35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient error = LinearGradient(
    colors: [AppColors.error, Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient card = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statYellow = LinearGradient(
    colors: [Color(0xFFFFB917), Color(0xFFFFB917)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statOrange = LinearGradient(
    colors: [Color(0xFFF5BC90), Color(0xFFFCC9A2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
