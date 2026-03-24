import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberpunkTheme {
  // Core palette
  static const Color backgroundBlack = Color(0xFF050505);
  static const Color surfaceDark = Color(0xFF101014);
  static const Color cardDark = Color(0xFF14141A);
  static const Color borderDark = Color(0xFF1E1E1E);
  
  // Accent colors
  static const Color neonCyan = Color(0xFF00F3FF);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonYellow = Color(0xFFFAFF00);
  
  // Derived accents (softer)
  static const Color cyanMuted = Color(0xFF00B8C4);
  static const Color pinkMuted = Color(0xFFCC00CC);

  // Additional semantic colors
  static const Color neonGreen = Color(0xFF00FF9F);
  static const Color neonAmber = Color(0xFFF39C12);
  static const Color infoBlue = Color(0xFF00B8FF);
  static const Color errorRed = Color(0xFFFF4757);
  
  // Text
  static const Color textWhite = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textTertiary = Color(0xFF555555);
  
  // Glassmorphism
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // ── Spacing constants ──
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 20;
  static const double spacingXXL = 24;
  static const double spacingSection = 32;

  // ── Border radius constants ──
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 14;
  static const double radiusXL = 16;
  static const double radiusRound = 20;
  static const double radiusPill = 100;

  // ── Avatar size constants ──
  static const double avatarXS = 32;
  static const double avatarS = 40;
  static const double avatarM = 48;
  static const double avatarL = 72;
  static const double avatarXL = 80;

  static ThemeData get theme {
    final inter = GoogleFonts.inter();

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: neonCyan,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: cardDark,
      canvasColor: backgroundBlack,
      
      // Typography — Inter everywhere, clean and modern
      textTheme: TextTheme(
        displayLarge: inter.copyWith(color: textWhite, fontWeight: FontWeight.w700, fontSize: 28),
        displayMedium: inter.copyWith(color: textWhite, fontWeight: FontWeight.w700, fontSize: 24),
        displaySmall: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 20),
        headlineLarge: inter.copyWith(color: textWhite, fontWeight: FontWeight.w700, fontSize: 22),
        headlineMedium: inter.copyWith(color: neonCyan, fontWeight: FontWeight.w600, fontSize: 18),
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

      // App Bar — clean dark, no glow
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: inter.copyWith(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textWhite, size: 24),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: neonCyan,
        unselectedItemColor: textTertiary,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Card Theme — glassmorphic
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: glassBorder, width: 0.5),
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),

      // Input Decoration — clean rounded
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: neonCyan, width: 1.5),
        ),
        hintStyle: inter.copyWith(color: textTertiary, fontSize: 14),
        labelStyle: inter.copyWith(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textWhite,
        size: 24,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 0.5,
        space: 0,
      ),

      // Text Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: neonCyan,
        selectionColor: neonCyan.withOpacity(0.2),
        selectionHandleColor: neonCyan,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonCyan,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: surfaceDark,
        error: errorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textWhite,
        onError: Colors.white,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: inter.copyWith(color: textWhite, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXL)),
        titleTextStyle: inter.copyWith(color: textWhite, fontWeight: FontWeight.w600, fontSize: 18),
        contentTextStyle: inter.copyWith(color: textSecondary, fontSize: 14),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        textColor: textWhite,
        iconColor: textSecondary,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonCyan;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonCyan.withOpacity(0.3);
          return borderDark;
        }),
      ),
    );
  }
}
