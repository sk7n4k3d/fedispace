import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/themes/light_theme.dart';
import 'package:fedispace/themes/amoled_theme.dart';

/// Available app themes.
enum AppTheme { cyberpunkDark, light, amoledBlack, system }

/// Manages theme selection and persistence.
class ThemeManager {
  static const String _key = 'app_theme';

  /// Get the currently saved theme preference.
  static Future<AppTheme> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'cyberpunkDark';
    return AppTheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppTheme.cyberpunkDark,
    );
  }

  /// Save theme preference.
  static Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }

  /// Get the ThemeData for a given theme, respecting system brightness.
  static ThemeData getThemeData(AppTheme theme, Brightness systemBrightness) {
    switch (theme) {
      case AppTheme.cyberpunkDark:
        return CyberpunkTheme.theme;
      case AppTheme.light:
        return LightTheme.theme;
      case AppTheme.amoledBlack:
        return AmoledTheme.theme;
      case AppTheme.system:
        return systemBrightness == Brightness.dark
            ? CyberpunkTheme.theme
            : LightTheme.theme;
    }
  }

  /// Human-readable theme name.
  static String themeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.cyberpunkDark:
        return 'Cyberpunk Dark';
      case AppTheme.light:
        return 'Light';
      case AppTheme.amoledBlack:
        return 'AMOLED Black';
      case AppTheme.system:
        return 'System';
    }
  }

  /// Icon for theme.
  static IconData themeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.cyberpunkDark:
        return Icons.nightlight_round;
      case AppTheme.light:
        return Icons.light_mode_rounded;
      case AppTheme.amoledBlack:
        return Icons.brightness_1;
      case AppTheme.system:
        return Icons.settings_brightness_rounded;
    }
  }
}
