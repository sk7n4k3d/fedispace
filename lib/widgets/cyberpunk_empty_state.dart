import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Reusable cyberpunk-themed empty state with pulsing icon + neon glow
class CyberpunkEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onAction;
  final String? actionLabel;

  const CyberpunkEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor = CyberpunkTheme.neonCyan,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  State<CyberpunkEmptyState> createState() => _CyberpunkEmptyStateState();
}

class _CyberpunkEmptyStateState extends State<CyberpunkEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor
                            .withOpacity(_pulseAnimation.value * 0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48,
                    color: widget.accentColor.withOpacity(0.8),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CyberpunkTheme.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CyberpunkTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.onAction != null && widget.actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: widget.onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.accentColor,
                  side: BorderSide(color: widget.accentColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CyberpunkTheme.radiusM),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  widget.actionLabel!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
