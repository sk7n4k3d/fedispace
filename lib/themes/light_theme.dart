import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean light theme with Material 3 style.
/// Keeps cyan and pink accent colors for consistency.
class LightTheme {
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color accentCyan = Color(0xFF00B8C4);
  static const Color accentPink = Color(0xFFE91E8C);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);

  static ThemeData get theme {
    final inter = GoogleFonts.inter();

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentCyan,
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      canvasColor: background,

      textTheme: TextTheme(
        displayLarge: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 28),
        displayMedium: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 24),
        displaySmall: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        headlineLarge: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        headlineMedium: inter.copyWith(color: accentCyan, fontWeight: FontWeight.w600, fontSize: 18),
        headlineSmall: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleLarge: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: inter.copyWith(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: inter.copyWith(color: textPrimary, fontSize: 15),
        bodyMedium: inter.copyWith(color: textPrimary, fontSize: 14),
        bodySmall: inter.copyWith(color: textSecondary, fontSize: 12),
        labelLarge: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: inter.copyWith(color: textSecondary, fontSize: 12),
        labelSmall: inter.copyWith(color: textTertiary, fontSize: 11),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: inter.copyWith(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentCyan,
        unselectedItemColor: textTertiary,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 24),
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderColor, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 1.5),
        ),
        hintStyle: inter.copyWith(color: textTertiary, fontSize: 14),
        labelStyle: inter.copyWith(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      iconTheme: const IconThemeData(color: textPrimary, size: 24),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 0.5,
        space: 0,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentCyan,
        selectionColor: accentCyan.withOpacity(0.2),
        selectionHandleColor: accentCyan,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentCyan,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      colorScheme: const ColorScheme.light(
        primary: accentCyan,
        secondary: accentPink,
        surface: surface,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: inter.copyWith(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: inter.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        contentTextStyle: inter.copyWith(color: textSecondary, fontSize: 14),
      ),

      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: textSecondary,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentCyan;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentCyan.withOpacity(0.3);
          return borderColor;
        }),
      ),
    );
  }
}
