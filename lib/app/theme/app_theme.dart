import 'package:flutter/material.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Calibri',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryRed),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      appBarTheme: const AppBarTheme(centerTitle: false),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 16.69,
          fontWeight: FontWeight.w400,
          color: AppColors.textBody,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textBody,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textBody,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 26,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: AppColors.textBody,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          fontFamily: 'Calibri',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

