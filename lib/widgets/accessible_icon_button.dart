import 'package:flutter/material.dart';

/// Wrapper around IconButton that adds proper Semantics for accessibility.
/// Use this instead of IconButton to ensure screen readers can describe all icon buttons.
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final bool isSelected;

  const AccessibleIconButton({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.iconSize,
    this.padding,
    this.tooltip,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      selected: isSelected,
      child: IconButton(
        icon: Icon(icon, color: color, size: iconSize),
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.all(8),
        tooltip: tooltip ?? label,
        splashRadius: 24,
      ),
    );
  }
}

/// Wrapper for any widget that adds semantic description.
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isButton;
  final bool isHeader;
  final bool isImage;
  final VoidCallback? onTap;

  const AccessibleWidget({
    Key? key,
    required this.child,
    required this.label,
    this.isButton = false,
    this.isHeader = false,
    this.isImage = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: isButton,
      header: isHeader,
      image: isImage,
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: child)
          : child,
    );
  }
}
