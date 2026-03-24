import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/reels/reel_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Full-screen vertical Reels/Video feed page.
/// Filters timeline for video posts and presents them in a TikTok-style viewer.
class ReelsPage extends StatefulWidget {
  final ApiService apiService;

  const ReelsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  final List<Status> _videoPosts = [];
  final Map<int, GlobalKey<ReelItemState>> _reelKeys = {};
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _loadVideoPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVideoPosts() async {
    try {
      // Fetch public timeline and filter for video content
      final allPosts = await widget.apiService.getStatusList(null, 40, 'public');
      final videos = allPosts.where((status) {
        return status.attachement.any((a) {
          final type = (a as Map<String, dynamic>)['type'] ?? '';
          return type == 'video' || type == 'gifv';
        });
      }).toList();

      if (mounted) {
        setState(() {
          _videoPosts.addAll(videos);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getVideoUrl(Status status) {
    for (final a in status.attachement) {
      final map = a as Map<String, dynamic>;
      final type = map['type'] ?? '';
      if (type == 'video' || type == 'gifv') {
        return map['url'] ?? '';
      }
    }
    return status.attach;
  }

  String _getPreviewUrl(Status status) {
    for (final a in status.attachement) {
      final map = a as Map<String, dynamic>;
      final type = map['type'] ?? '';
      if (type == 'video' || type == 'gifv') {
        return map['preview_url'] ?? '';
      }
    }
    return status.preview_url;
  }

  void _onDoubleTap(Status status, int index) {
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
    // Trigger like if not already liked
    if (!status.favorited) {
      widget.apiService.favoriteStatus(status.id);
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
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
        title: const Text(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
            )
          : _videoPosts.isEmpty
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
                      itemCount: _videoPosts.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final status = _videoPosts[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Video player
                            ReelItem(
                              key: _getReelKey(index),
                              videoUrl: _getVideoUrl(status),
                              previewUrl: _getPreviewUrl(status),
                              shouldPlay: index == _currentIndex,
                              onDoubleTap: () => _onDoubleTap(status, index),
                            ),

                            // Right side action buttons
                            Positioned(
                              right: 12,
                              bottom: 120,
                              child: _buildActionButtons(status),
                            ),

                            // Bottom author info + caption
                            Positioned(
                              left: 0,
                              right: 72,
                              bottom: 24,
                              child: _buildCaptionOverlay(status),
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

  Widget _buildActionButtons(Status status) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNeonButton(
          icon: status.favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: status.favourites_count.toString(),
          color: status.favorited ? CyberpunkTheme.neonPink : Colors.white,
          onTap: () => widget.apiService.favoriteStatus(status.id),
        ),
        const SizedBox(height: 20),
        _buildNeonButton(
          icon: Icons.comment_rounded,
          label: status.replies_count.toString(),
          color: Colors.white,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        _buildNeonButton(
          icon: Icons.share_rounded,
          label: '',
          color: Colors.white,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        _buildNeonButton(
          icon: Icons.bookmark_border_rounded,
          label: '',
          color: Colors.white,
          onTap: () {},
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
                      : Colors.transparent,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          if (label.isNotEmpty) ...[
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

  Widget _buildCaptionOverlay(Status status) {
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
                backgroundImage: status.avatar.isNotEmpty
                    ? CachedNetworkImageProvider(status.avatar)
                    : null,
                backgroundColor: CyberpunkTheme.surfaceDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.acct,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Caption
          if (_stripHtml(status.content).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _stripHtml(status.content),
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
