import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color card = Color(0xFF1C1C28);
  static const Color accent = Color(0xFFFF6B35); // orange-fire
  static const Color green = Color(0xFF00D46A);
  static const Color blue = Color(0xFF4D9EFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0AB);

  // Category Colors
  static const Color catDsa = Colors.orange;
  static const Color catDev = Colors.blue;
  static const Color catAptitude = Colors.yellow;
  static const Color catResume = Colors.green;
  static const Color catCore = Colors.purple;
  static const Color catMock = Colors.red;
  static const Color catOther = Colors.grey;
}

Color getCategoryColor(String category) {
  switch (category) {
    case 'DSA':
      return AppColors.catDsa;
    case 'Development':
      return AppColors.catDev;
    case 'Aptitude':
      return AppColors.catAptitude;
    case 'Resume':
      return AppColors.catResume;
    case 'Core CS':
      return AppColors.catCore;
    case 'Mock Interview':
      return AppColors.catMock;
    default:
      return AppColors.catOther;
  }
}
