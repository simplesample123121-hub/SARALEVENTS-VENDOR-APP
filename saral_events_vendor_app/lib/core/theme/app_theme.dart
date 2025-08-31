import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFFDBB42);
  static const Color secondary = Color(0xFF9C100E); // Dark red/burgundy accent
  static const Color accent = Color(0xFFFFE8D6); // Soft peach bg accents
  static const Color surface = Color(0xFFFAFAFA); // Light gray background
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      brightness: Brightness.light,
    );

    final baseInter = GoogleFonts.interTextTheme();

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.black87,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w400),
        hintStyle: const TextStyle(fontWeight: FontWeight.w400),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        color: WidgetStatePropertyAll(Colors.grey.shade200),
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: Colors.transparent),
        shape: StadiumBorder(side: BorderSide.none),
      ),
      textTheme: baseInter.copyWith(
        displayLarge: baseInter.displayLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 48, height: 56 / 48),
        displayMedium: baseInter.displayMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 40, height: 1.2),
        displaySmall: baseInter.displaySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 32, height: 1.25),
        headlineLarge: baseInter.headlineLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 28, height: 1.29),
        headlineMedium: baseInter.headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 24, height: 1.33),
        headlineSmall: baseInter.headlineSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 20, height: 1.4),
        titleLarge: baseInter.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: baseInter.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: baseInter.titleSmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: baseInter.bodyLarge?.copyWith(fontWeight: FontWeight.w400, fontSize: 16),
        bodyMedium: baseInter.bodyMedium?.copyWith(fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: baseInter.bodySmall?.copyWith(fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: baseInter.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: baseInter.labelMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: baseInter.labelSmall?.copyWith(fontWeight: FontWeight.w400, fontSize: 10),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}


