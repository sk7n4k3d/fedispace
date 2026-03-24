import 'package:shared_preferences/shared_preferences.dart';

/// Global accessibility configuration.
/// Controls reduced motion and high contrast modes.
class AccessibilityConfig {
  static bool reducedMotion = false;
  static bool highContrast = false;
  static double textScaleFactor = 1.0;

  static const String _keyReducedMotion = 'accessibility_reduced_motion';
  static const String _keyHighContrast = 'accessibility_high_contrast';
  static const String _keyTextScale = 'accessibility_text_scale';

  /// Load accessibility preferences from SharedPreferences.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    reducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
    highContrast = prefs.getBool(_keyHighContrast) ?? false;
    textScaleFactor = prefs.getDouble(_keyTextScale) ?? 1.0;
  }

  /// Save accessibility preferences to SharedPreferences.
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedMotion, reducedMotion);
    await prefs.setBool(_keyHighContrast, highContrast);
    await prefs.setDouble(_keyTextScale, textScaleFactor);
  }

  /// Get animation duration, respecting reduced motion preference.
  static Duration animationDuration(Duration normal) {
    return reducedMotion ? Duration.zero : normal;
  }

  /// Get animation curve, respecting reduced motion preference.
  static bool get shouldAnimate => !reducedMotion;
}
