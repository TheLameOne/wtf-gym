import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand colours ──────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const guruPrimary = Color(0xFF1769E0);
  static const trainerPrimary = Color(0xFFE50914);

  // WTF Gym brand accent — Energy Orange (design system)
  static const brand = Color(0xFFF97316);
  static const brandLight = Color(0xFFFB923C);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF79009);
  static const error = Color(0xFFD92D20);

  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey600 = Color(0xFF757575);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // Dark palette (design system — #1F2937 base)
  static const darkBg = Color(0xFF1F2937);
  static const darkSurface = Color(0xFF111827);
  static const darkCard = Color(0xFF374151);
  static const darkBorder = Color(0xFF4B5563);
  static const textOnDark = Color(0xFFF8FAFC);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  static const memberBubble = Color(0xFFE3F0FF);
  static const trainerBubble = Color(0xFFFFEBEB);
}

// ─── Text styles — Barlow Condensed (headings) + Barlow (body) ───────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => GoogleFonts.barlowCondensed(
      fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0.4);
  static TextStyle get h2 => GoogleFonts.barlowCondensed(
      fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.3);
  static TextStyle get h3 => GoogleFonts.barlowCondensed(
      fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static TextStyle get bodyLarge =>
      GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get body =>
      GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get caption =>
      GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get label => GoogleFonts.barlow(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2);
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

  static ThemeData guru({Brightness brightness = Brightness.light}) =>
      _buildTheme(AppColors.guruPrimary, brightness);

  static ThemeData trainer({Brightness brightness = Brightness.light}) =>
      _buildTheme(AppColors.trainerPrimary, brightness);

  static ThemeData guruDark() => guru(brightness: Brightness.dark);
  static ThemeData trainerDark() => trainer(brightness: Brightness.dark);

  static ThemeData _buildTheme(Color primary, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.white;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.white;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.grey200;
    final inputFill = isDark ? AppColors.darkCard : AppColors.grey100;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.white;
    final appBarFg = isDark ? AppColors.textOnDark : AppColors.grey900;

    final textTheme = GoogleFonts.barlowTextTheme().copyWith(
      displayLarge: GoogleFonts.barlowCondensed(
          fontSize: 28, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.barlowCondensed(
          fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.barlowCondensed(
          fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.barlowCondensed(
          fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium:
          GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge:
          GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
      ).copyWith(primary: primary, surface: surfaceColor),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: appBarFg,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
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
          textStyle: GoogleFonts.barlow(
              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: textTheme,
    );
  }
}
