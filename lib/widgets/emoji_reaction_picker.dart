import 'package:flutter/material.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Emoji reaction picker for DM messages.
/// Shows 6 quick reactions on long-press of a message.
class EmojiReactionPicker extends StatelessWidget {
  final void Function(String emoji)? onReactionSelected;

  const EmojiReactionPicker({Key? key, this.onReactionSelected})
      : super(key: key);

  static const List<String> defaultReactions = [
    '\u2764\uFE0F', // red heart
    '\uD83D\uDE02', // face with tears of joy
    '\uD83D\uDE2E', // face with open mouth
    '\uD83D\uDE22', // crying face
    '\uD83D\uDD25', // fire
    '\uD83D\uDC4D', // thumbs up
  ];

  /// Show the reaction picker as an overlay near the given position.
  static Future<String?> show(BuildContext context, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 100,
        position.dy - 60,
        position.dx + 100,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: CyberpunkTheme.cardDark,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: defaultReactions.map((emoji) {
              return InkWell(
                onTap: () => Navigator.pop(context, emoji),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: CyberpunkTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: CyberpunkTheme.neonCyan.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: defaultReactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReactionSelected?.call(emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A small reaction badge that appears below a message.
class ReactionBadge extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const ReactionBadge({
    Key? key,
    required this.emoji,
    this.count = 1,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? CyberpunkTheme.neonCyan.withOpacity(0.15)
              : CyberpunkTheme.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CyberpunkTheme.neonCyan
                : CyberpunkTheme.glassBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected
                      ? CyberpunkTheme.neonCyan
                      : CyberpunkTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
