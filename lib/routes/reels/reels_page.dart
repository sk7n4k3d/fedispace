import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fedispace/core/loops_api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/reels/reel_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Full-screen vertical Reels/Video feed page.
/// Loads videos from the Loops.video public feed API.
class ReelsPage extends StatefulWidget {
  const ReelsPage({Key? key}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  late final LoopsApi _loopsApi;
  final List<LoopsVideo> _videos = [];
  final Map<int, GlobalKey<ReelItemState>> _reelKeys = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _loopsApi = LoopsApi(instanceUrl: 'https://loops.video');
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loopsApi.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    try {
      final response = await _loopsApi.getPublicFeed();
      if (mounted) {
        setState(() {
          _videos.addAll(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final response = await _loopsApi.getPublicFeed();
      if (mounted) {
        setState(() {
          _videos.addAll(response);
        });
      }
    } catch (_) {
      // Silently fail for infinite scroll
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Infinite scroll: load more when reaching last 3 videos
    if (index >= _videos.length - 3) {
      _loadMoreVideos();
    }
  }

  void _onDoubleTap(LoopsVideo video, int index) {
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
    // Auth required for likes
    _showAuthSnackbar('like');
  }

  void _showAuthSnackbar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sign in to Loops to $action',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: CyberpunkTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  GlobalKey<ReelItemState> _getReelKey(int index) {
    return _reelKeys.putIfAbsent(index, () => GlobalKey<ReelItemState>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reels',
              style: TextStyle(
                color: CyberpunkTheme.neonCyan,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                shadows: [
                  Shadow(color: CyberpunkTheme.neonCyan, blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CyberpunkTheme.neonPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CyberpunkTheme.neonPink.withOpacity(0.5), width: 0.5),
              ),
              child: const Text(
                'Loops',
                style: TextStyle(
                  color: CyberpunkTheme.neonPink,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
            )
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_rounded,
                          color: CyberpunkTheme.textTertiary, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No video reels found',
                        style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _videos.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Video player
                            ReelItem(
                              key: _getReelKey(index),
                              videoUrl: video.videoUrl ?? '',
                              previewUrl: video.thumbnailUrl ?? '',
                              shouldPlay: index == _currentIndex,
                              onDoubleTap: () => _onDoubleTap(video, index),
                            ),

                            // Right side action buttons
                            Positioned(
                              right: 12,
                              bottom: 120,
                              child: _buildActionButtons(video),
                            ),

                            // Bottom author info + caption
                            Positioned(
                              left: 0,
                              right: 72,
                              bottom: 24,
                              child: _buildCaptionOverlay(video),
                            ),
                          ],
                        );
                      },
                    ),

                    // Heart animation on double-tap
                    if (_showHeart)
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1.2),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Icon(
                                Icons.favorite_rounded,
                                color: CyberpunkTheme.neonPink,
                                size: 100,
                                shadows: [
                                  Shadow(color: CyberpunkTheme.neonPink, blurRadius: 30),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildActionButtons(LoopsVideo video) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _buildNeonButton(
          icon: video.hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: _formatCount(video.likes),
          color: video.hasLiked ? CyberpunkTheme.neonPink : Colors.white,
          onTap: () => _showAuthSnackbar('like'),
        ),
        const SizedBox(height: 20),
        // Comments
        _buildNeonButton(
          icon: Icons.comment_rounded,
          label: _formatCount(video.comments),
          color: Colors.white,
          onTap: () => _showAuthSnackbar('comment'),
        ),
        const SizedBox(height: 20),
        // Share
        _buildNeonButton(
          icon: Icons.share_rounded,
          label: _formatCount(video.shares),
          color: Colors.white,
          onTap: () {
            // Share could work without auth - open video URL
            if (video.url != null) {
              // TODO: Share intent
            }
          },
        ),
        const SizedBox(height: 20),
        // Bookmark
        _buildNeonButton(
          icon: video.hasBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: _formatCount(video.bookmarks),
          color: video.hasBookmarked ? CyberpunkTheme.neonCyan : Colors.white,
          onTap: () => _showAuthSnackbar('bookmark'),
        ),
      ],
    );
  }

  Widget _buildNeonButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color == CyberpunkTheme.neonPink
                      ? CyberpunkTheme.neonPink.withOpacity(0.4)
                      : color == CyberpunkTheme.neonCyan
                          ? CyberpunkTheme.neonCyan.withOpacity(0.4)
                          : Colors.transparent,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          if (label.isNotEmpty && label != '0') ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaptionOverlay(LoopsVideo video) {
    final authorName = video.account['name'] as String? ??
        video.account['username'] as String? ??
        'Unknown';
    final authorAvatar = video.account['avatar'] as String? ?? '';
    final duration = _formatDuration(video.duration);

    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: authorAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(authorAvatar)
                    : null,
                backgroundColor: CyberpunkTheme.surfaceDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (duration.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: CyberpunkTheme.neonCyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Caption
          if (video.caption != null && video.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              video.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
