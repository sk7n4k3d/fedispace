import 'package:flutter/material.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Shimmer skeleton loading effect with cyberpunk neon aesthetic
class SkeletonLoading extends StatefulWidget {
  final Widget child;
  const SkeletonLoading({Key? key, required this.child}) : super(key: key);

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
            end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
            colors: const [
              Color(0xFF0E0E0E),
              Color(0xFF1A1A2E),
              Color(0xFF0E0E0E),
            ],
          ).createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton placeholder box with rounded corners
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CyberpunkTheme.cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for a timeline post card
class TimelineSkeleton extends StatelessWidget {
  const TimelineSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Container(
        color: CyberpunkTheme.backgroundBlack,
        margin: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + username
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CyberpunkTheme.cardDark,
                      border: Border.all(
                        color: CyberpunkTheme.neonCyan.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonBox(width: 120, height: 12),
                      SizedBox(height: 4),
                      _SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ],
              ),
            ),
            // Image placeholder
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(color: CyberpunkTheme.cardDark),
            ),
            // Action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: const [
                  _SkeletonBox(width: 24, height: 24, borderRadius: 4),
                  SizedBox(width: 14),
                  _SkeletonBox(width: 24, height: 24, borderRadius: 4),
                  SizedBox(width: 14),
                  _SkeletonBox(width: 24, height: 24, borderRadius: 4),
                ],
              ),
            ),
            // Likes count
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: _SkeletonBox(width: 80, height: 12),
            ),
            // Caption lines
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: _SkeletonBox(width: double.infinity, height: 12),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: _SkeletonBox(width: 200, height: 12),
            ),
            const SizedBox(height: 12),
            Container(height: 0.5, color: CyberpunkTheme.borderDark),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a profile page
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + stats row
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberpunkTheme.cardDark,
                    border: Border.all(
                      color: CyberpunkTheme.neonCyan.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (_) => Column(
                      children: const [
                        _SkeletonBox(width: 40, height: 16),
                        SizedBox(height: 4),
                        _SkeletonBox(width: 50, height: 10),
                      ],
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Name
            const _SkeletonBox(width: 140, height: 14),
            const SizedBox(height: 6),
            // Username
            const _SkeletonBox(width: 100, height: 12),
            const SizedBox(height: 10),
            // Bio lines
            const _SkeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 4),
            const _SkeletonBox(width: 250, height: 12),
            const SizedBox(height: 16),
            // Action button
            const _SkeletonBox(width: double.infinity, height: 36, borderRadius: 10),
            const SizedBox(height: 16),
            Container(height: 0.5, color: CyberpunkTheme.borderDark),
            const SizedBox(height: 2),
            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
              ),
              itemCount: 9,
              itemBuilder: (_, __) => Container(color: CyberpunkTheme.cardDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for search/discover page
class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar placeholder
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: CyberpunkTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            // Trending tags
            const _SkeletonBox(width: 100, height: 14),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (i) => _SkeletonBox(
                width: 60.0 + (i * 15 % 40),
                height: 28,
                borderRadius: 14,
              )),
            ),
            const SizedBox(height: 20),
            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
              ),
              itemCount: 9,
              itemBuilder: (_, __) => Container(color: CyberpunkTheme.cardDark),
            ),
          ],
        ),
      ),
    );
  }
}
