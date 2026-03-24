import 'package:flutter/material.dart';

/// Represents a named image filter preset with a ColorFilter matrix.
class ImageFilterPreset {
  final String name;
  final List<double>? matrix;
  final double defaultIntensity;
  final bool isCyberpunk;

  const ImageFilterPreset({
    required this.name,
    this.matrix,
    this.defaultIntensity = 1.0,
    this.isCyberpunk = false,
  });

  /// Get ColorFilter for this preset at given intensity (0.0 to 1.0).
  /// Returns null for "Normal" (no filter).
  ColorFilter? getColorFilter(double intensity) {
    if (matrix == null) return null;
    if (intensity <= 0.0) return null;

    // Interpolate between identity matrix and filter matrix
    final identity = <double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    final blended = List<double>.generate(20, (i) {
      return identity[i] + (matrix![i] - identity[i]) * intensity;
    });

    return ColorFilter.matrix(blended);
  }
}

/// Built-in filter presets inspired by popular photo apps.
final List<ImageFilterPreset> photoFilters = [
  // Normal — no filter
  const ImageFilterPreset(
    name: 'Normal',
    matrix: null,
    defaultIntensity: 1.0,
  ),

  // Clarendon — boost contrast + saturation, slight warm
  const ImageFilterPreset(
    name: 'Clarendon',
    matrix: [
      1.3, 0.0, 0.0, 0.0, 10,
      0.0, 1.15, 0.0, 0.0, 5,
      0.0, 0.0, 1.1, 0.0, -5,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.8,
  ),

  // Gingham — faded, vintage feel
  const ImageFilterPreset(
    name: 'Gingham',
    matrix: [
      0.9, 0.05, 0.05, 0.0, 15,
      0.05, 0.85, 0.1, 0.0, 15,
      0.05, 0.1, 0.85, 0.0, 20,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.8,
  ),

  // Moon — black & white with blue tint
  const ImageFilterPreset(
    name: 'Moon',
    matrix: [
      0.33, 0.33, 0.33, 0.0, -10,
      0.33, 0.33, 0.33, 0.0, -5,
      0.33, 0.33, 0.33, 0.0, 10,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.8,
  ),

  // Lark — bright, airy, slight desaturation
  const ImageFilterPreset(
    name: 'Lark',
    matrix: [
      1.2, 0.0, 0.0, 0.0, 15,
      0.0, 1.15, 0.0, 0.0, 15,
      0.0, 0.0, 0.9, 0.0, 10,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.8,
  ),

  // Reyes — dusty vintage, low contrast
  const ImageFilterPreset(
    name: 'Reyes',
    matrix: [
      0.85, 0.1, 0.05, 0.0, 25,
      0.05, 0.8, 0.15, 0.0, 20,
      0.05, 0.1, 0.75, 0.0, 25,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.7,
  ),

  // Juno — warm golden tone, higher contrast
  const ImageFilterPreset(
    name: 'Juno',
    matrix: [
      1.25, 0.0, 0.0, 0.0, 15,
      0.0, 1.1, 0.0, 0.0, 10,
      0.0, 0.0, 0.85, 0.0, -5,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.8,
  ),

  // Slumber — cool desaturated, low contrast
  const ImageFilterPreset(
    name: 'Slumber',
    matrix: [
      0.75, 0.1, 0.15, 0.0, 10,
      0.1, 0.75, 0.15, 0.0, 10,
      0.15, 0.1, 0.8, 0.0, 15,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.7,
  ),

  // Crema — warm cream tones
  const ImageFilterPreset(
    name: 'Crema',
    matrix: [
      1.0, 0.05, 0.0, 0.0, 20,
      0.0, 0.95, 0.05, 0.0, 15,
      0.0, 0.0, 0.85, 0.0, 10,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.7,
  ),

  // Ludwig — subtle warm, slight desaturation
  const ImageFilterPreset(
    name: 'Ludwig',
    matrix: [
      1.05, 0.05, 0.0, 0.0, 5,
      0.0, 0.95, 0.05, 0.0, 5,
      0.0, 0.05, 0.9, 0.0, 0,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.8,
  ),

  // Aden — soft pastel, vintage
  const ImageFilterPreset(
    name: 'Aden',
    matrix: [
      0.9, 0.05, 0.05, 0.0, 20,
      0.05, 0.9, 0.05, 0.0, 15,
      0.0, 0.05, 0.85, 0.0, 20,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.7,
  ),

  // Neon — cyberpunk exclusive: high contrast + cyan/magenta
  const ImageFilterPreset(
    name: 'Neon',
    matrix: [
      1.3, 0.0, 0.2, 0.0, -10,
      0.0, 1.1, 0.0, 0.0, 5,
      0.2, 0.0, 1.4, 0.0, -5,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.7,
    isCyberpunk: true,
  ),

  // Glitch — RGB channel shift effect (push red right, blue left)
  const ImageFilterPreset(
    name: 'Glitch',
    matrix: [
      1.2, -0.1, 0.1, 0.0, 5,
      0.1, 0.9, -0.1, 0.0, -3,
      -0.1, 0.1, 1.3, 0.0, 8,
      0.0, 0.0, 0.0, 1.0, 0,
    ],
    defaultIntensity: 0.6,
    isCyberpunk: true,
  ),
];

/// Manual adjustment parameters.
class ImageAdjustments {
  double brightness; // -100 to 100
  double contrast;   // -100 to 100
  double saturation; // -100 to 100
  double warmth;     // -100 to 100

  ImageAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
  });

  bool get hasChanges =>
      brightness != 0 || contrast != 0 || saturation != 0 || warmth != 0;

  /// Build a ColorFilter matrix from the manual adjustments.
  ColorFilter? toColorFilter() {
    if (!hasChanges) return null;

    // Normalize values to -1..1 range
    final b = brightness / 100.0;
    final c = 1.0 + (contrast / 100.0);
    final s = 1.0 + (saturation / 100.0);
    final w = warmth / 200.0; // Subtle warmth effect

    // Saturation matrix (ITU-R BT.601 luma)
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;
    final sr = (1 - s) * lr;
    final sg = (1 - s) * lg;
    final sb = (1 - s) * lb;

    // Combine: saturation * contrast + brightness + warmth
    final matrix = <double>[
      (sr + s) * c, sg * c, sb * c, 0, (b * 255 + w * 30),
      sr * c, (sg + s) * c, sb * c, 0, (b * 255),
      sr * c, sg * c, (sb + s) * c, 0, (b * 255 - w * 20),
      0, 0, 0, 1, 0,
    ];

    return ColorFilter.matrix(matrix);
  }
}
