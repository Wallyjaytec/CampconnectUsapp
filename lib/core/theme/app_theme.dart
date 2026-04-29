import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class AppTheme {
  static String _fontFor(Locale locale) {
    switch (locale.languageCode) {
      case 'bn':
        return AppFonts.banglaFont;
      case 'ur':
        return AppFonts.arabicFont;
      default:
        return AppFonts.mainFont;
    }
  }

  static ThemeData lightFor(Locale locale) {
    final family = _fontFor(locale);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        primary: AppColors.primaryColor,
        seedColor: AppColors.primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.whiteColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparentColor,
        shadowColor: AppColors.transparentColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBottomNavBarColor,
        selectedItemColor: AppColors.primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.primaryColor),
        trackColor: WidgetStateProperty.all(
          AppColors.primaryColor.withValues(red: 0.5, green: 0.5, blue: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      fontFamily: family,
    );
  }

  static ThemeData darkFor(Locale locale) {
    final family = _fontFor(locale);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        primary: AppColors.primaryColor,
        seedColor: AppColors.primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.whiteColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparentColor,
        shadowColor: AppColors.transparentColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBottomNavBarColor,
        selectedItemColor: AppColors.primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.primaryColor),
        trackColor: WidgetStateProperty.all(
          AppColors.primaryColor.withValues(red: 0.5, green: 0.5, blue: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      fontFamily: family,
    );
  }
}
