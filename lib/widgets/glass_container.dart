import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Reusable glassmorphism container with backdrop blur + semi-transparent bg + border
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? borderColor;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = CyberpunkTheme.radiusL,
    this.padding = const EdgeInsets.all(CyberpunkTheme.spacingL),
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: CyberpunkTheme.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? CyberpunkTheme.glassBorder,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
