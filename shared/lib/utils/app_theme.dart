import 'package:flutter/material.dart';

// ─── Brand colours ──────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const guruPrimary = Color(0xFF1769E0);
  static const trainerPrimary = Color(0xFFE50914);

  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFF79009);
  static const error = Color(0xFFD92D20);

  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey600 = Color(0xFF757575);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  static const memberBubble = Color(0xFFE3F0FF);
  static const trainerBubble = Color(0xFFFFEBEB);
}

// ─── Text styles ─────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}

// ─── Spacing ─────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─── Theme builders ──────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData guru() => _buildTheme(AppColors.guruPrimary);
  static ThemeData trainer() => _buildTheme(AppColors.trainerPrimary);

  static ThemeData _buildTheme(Color primary) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(primary: primary),
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.grey900),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.grey200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.label,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.h1,
          titleLarge: AppTextStyles.h2,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
          labelLarge: AppTextStyles.label,
        ),
      );
}
