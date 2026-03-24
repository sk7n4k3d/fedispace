import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pure AMOLED black theme for maximum battery savings on OLED screens.
/// Uses #000000 backgrounds with minimal borders and same accent colors.
class AmoledTheme {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF000000);
  static const Color cardColor = Color(0xFF0A0A0A);
  static const Color borderColor = Color(0xFF1A1A1A);
  static const Color accentCyan = Color(0xFF00F3FF);
  static const Color accentPink = Color(0xFFFF00FF);
  static const Color textWhite = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textTertiary = Color(0xFF555555);

  static ThemeData get theme {
    final inter = GoogleFonts.inter();

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentCyan,
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      canvasColor: background,

      textTheme: TextTheme(
        displayLarge: inter.copyWith(color: textWhite, fontWeight: FontWeight.w700, fontSize: 28),
        displayMedium: inter.copyWith(color: textWhite, fontWeight: FontWeight.w700, fontSize: 24),
        displaySmall: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 20),
        headlineLarge: inter.copyWith(color: textWhite, fontWeight: FontWeight.w700, fontSize: 22),
        headlineMedium: inter.copyWith(color: accentCyan, fontWeight: FontWeight.w600, fontSize: 18),
        headlineSmall: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 16),
        titleLarge: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: inter.copyWith(color: textWhite, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: inter.copyWith(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: inter.copyWith(color: textWhite, fontSize: 15),
        bodyMedium: inter.copyWith(color: textWhite, fontSize: 14),
        bodySmall: inter.copyWith(color: textSecondary, fontSize: 12),
        labelLarge: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: inter.copyWith(color: textSecondary, fontSize: 12),
        labelSmall: inter.copyWith(color: textTertiary, fontSize: 11),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: inter.copyWith(color: textWhite, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: textWhite, size: 24),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: accentCyan,
        unselectedItemColor: textTertiary,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 24),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderColor, width: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D0D0D),
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

      iconTheme: const IconThemeData(color: textWhite, size: 24),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 0.3,
        space: 0,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentCyan,
        selectionColor: accentCyan.withOpacity(0.2),
        selectionHandleColor: accentCyan,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentCyan,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentPink,
        surface: surface,
        error: Color(0xFFFF4757),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textWhite,
        onError: Colors.white,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: inter.copyWith(color: textWhite, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 18),
        contentTextStyle: inter.copyWith(color: textSecondary, fontSize: 14),
      ),

      listTileTheme: ListTileThemeData(
        textColor: textWhite,
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
