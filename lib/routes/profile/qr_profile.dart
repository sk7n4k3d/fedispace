import 'package:flutter/material.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

/// QR Code Profile page.
/// Generates a QR code from the profile URL with neon styling and avatar overlay.
class QrProfilePage extends StatelessWidget {
  final String profileUrl;
  final String username;
  final String avatarUrl;

  const QrProfilePage({
    Key? key,
    required this.profileUrl,
    required this.username,
    required this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('QR Profile'),
        backgroundColor: CyberpunkTheme.backgroundBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => Share.share(profileUrl),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile info
            CircleAvatar(
              radius: 40,
              backgroundImage: avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              backgroundColor: CyberpunkTheme.surfaceDark,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person,
                      size: 40, color: CyberpunkTheme.textTertiary)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              '@$username',
              style: const TextStyle(
                color: CyberpunkTheme.neonCyan,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: CyberpunkTheme.neonCyan, blurRadius: 8)
                ],
              ),
            ),
            const SizedBox(height: 32),

            // QR Code container with neon border
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CyberpunkTheme.neonCyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: CyberpunkTheme.neonPink.withOpacity(0.15),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // QR Code placeholder -- uses a simple grid pattern
                    // In production, use qr_flutter package: QrImageView(data: profileUrl)
                    _buildQrPlaceholder(),

                    // Avatar overlay in center
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        backgroundColor: CyberpunkTheme.surfaceDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // URL display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: CyberpunkTheme.glassWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CyberpunkTheme.glassBorder),
              ),
              child: Text(
                profileUrl,
                style: const TextStyle(
                    color: CyberpunkTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Scan QR button
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('QR Scanner requires camera permission')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CyberpunkTheme.neonCyan,
                side: const BorderSide(color: CyberpunkTheme.neonCyan),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Simple QR-like grid pattern as placeholder.
  /// Replace with actual QR generation using qr_flutter package.
  Widget _buildQrPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 15,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 225,
        itemBuilder: (context, index) {
          // Generate a pseudo-random pattern based on profile URL hash
          final hash = profileUrl.hashCode;
          final isBlack = (hash * (index + 1) * 7) % 3 != 0;
          // Fixed corner patterns for QR code look
          final row = index ~/ 15;
          final col = index % 15;
          final isCorner = (row < 3 && col < 3) ||
              (row < 3 && col > 11) ||
              (row > 11 && col < 3);
          final isCenterArea = row > 5 && row < 9 && col > 5 && col < 9;

          return Container(
            decoration: BoxDecoration(
              color: isCenterArea
                  ? Colors.transparent
                  : isCorner
                      ? const Color(0xFF00B8C4)
                      : isBlack
                          ? Colors.black87
                          : Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        },
      ),
    );
  }
}
