import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fedispace/core/loops_api.dart';
import 'package:fedispace/core/loops_auth.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/reels/reel_item.dart';
import 'package:fedispace/routes/reels/loops_login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Full-screen vertical Reels/Video feed page with Loops OAuth integration.
/// Ultra-premium TikTok-style UI with immersive video experience.
class ReelsPage extends StatefulWidget {
  const ReelsPage({Key? key}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  LoopsApi? _loopsApi;
  final List<LoopsVideo> _videos = [];
  final Map<int, GlobalKey<ReelItemState>> _reelKeys = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isAuthenticated = false;
  bool _showLoginPage = true;
  int _currentIndex = 0;
  String? _nextCursor;
  int _selectedFeedTab = 0; // 0 = For You, 1 = Following

  // Double-tap heart animation
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  // Like state tracking (local overrides)
  final Map<String, bool> _likeOverrides = {};
  final Map<String, int> _likeCountOverrides = {};

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));
    _checkAuth();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartController.dispose();
    _loopsApi?.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final authenticated = await LoopsAuth.isAuthenticated();
    if (authenticated) {
      _isAuthenticated = true;
      _showLoginPage = false;
      _loopsApi = await LoopsAuth.getAuthenticatedClient();
      _loadVideos();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onAuthenticated() async {
    _isAuthenticated = true;
    _showLoginPage = false;
    _loopsApi?.dispose();
    _loopsApi = await LoopsAuth.getAuthenticatedClient();
    setState(() => _isLoading = true);
    _loadVideos();
  }

  void _onSkipLogin() {
    _showLoginPage = false;
    _loopsApi = LoopsApi(instanceUrl: 'https://loops.video');
    setState(() => _isLoading = true);
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      if (_isAuthenticated && _selectedFeedTab == 1) {
        final response = await _loopsApi!.getFollowingFeed(limit: 15);
        if (mounted) {
          setState(() {
            _videos.clear();
            _videos.addAll(response.data);
            _nextCursor = response.nextCursor;
            _isLoading = false;
          });
        }
      } else if (_isAuthenticated) {
        final response = await _loopsApi!.getForYouFeed(limit: 15);
        if (mounted) {
          setState(() {
            _videos.clear();
            _videos.addAll(response.data);
            _nextCursor = response.nextCursor;
            _isLoading = false;
          });
        }
      } else {
        // Public feed fallback
        final response = await _loopsApi!.getPublicFeed();
        if (mounted) {
          setState(() {
            _videos.clear();
            _videos.addAll(response);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Reels load error: $e');
      // Fallback to public feed
      try {
        final publicApi = LoopsApi(instanceUrl: 'https://loops.video');
        final response = await publicApi.getPublicFeed();
        publicApi.dispose();
        if (mounted) {
          setState(() {
            _videos.clear();
            _videos.addAll(response);
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || _loopsApi == null) return;
    _isLoadingMore = true;
    try {
      if (_isAuthenticated && _selectedFeedTab == 1) {
        final response = await _loopsApi!.getFollowingFeed(
          limit: 10,
          cursor: _nextCursor,
        );
        if (mounted) {
          setState(() {
            _videos.addAll(response.data);
            _nextCursor = response.nextCursor;
          });
        }
      } else if (_isAuthenticated) {
        final response = await _loopsApi!.getForYouFeed(
          limit: 10,
          cursor: _nextCursor,
        );
        if (mounted) {
          setState(() {
            _videos.addAll(response.data);
            _nextCursor = response.nextCursor;
          });
        }
      } else {
        final response = await _loopsApi!.getPublicFeed();
        if (mounted) {
          setState(() => _videos.addAll(response));
        }
      }
    } catch (_) {
      // Silently fail for infinite scroll
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _refreshVideos() async {
    _nextCursor = null;
    _reelKeys.clear();
    await _loadVideos();
    if (_videos.isNotEmpty) {
      _pageController.jumpToPage(0);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (index >= _videos.length - 3) {
      _loadMoreVideos();
    }
  }

  void _onDoubleTap(LoopsVideo video, int index) {
    // Trigger heart animation
    _heartController.forward(from: 0.0);
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showHeart = false);
    });

    if (_isAuthenticated) {
      _toggleLike(video);
    }
  }

  Future<void> _toggleLike(LoopsVideo video) async {
    final currentlyLiked = _likeOverrides[video.id] ?? video.hasLiked;
    final currentCount = _likeCountOverrides[video.id] ?? video.likes;

    setState(() {
      _likeOverrides[video.id] = !currentlyLiked;
      _likeCountOverrides[video.id] =
          currentlyLiked ? currentCount - 1 : currentCount + 1;
    });

    try {
      if (currentlyLiked) {
        await _loopsApi!.unlikeVideo(video.id);
      } else {
        await _loopsApi!.likeVideo(video.id);
      }
    } catch (_) {
      // Revert on error
      if (mounted) {
        setState(() {
          _likeOverrides[video.id] = currentlyLiked;
          _likeCountOverrides[video.id] = currentCount;
        });
      }
    }
  }

  Future<void> _toggleBookmark(LoopsVideo video) async {
    if (!_isAuthenticated) {
      _showAuthSnackbar('bookmark');
      return;
    }
    try {
      if (video.hasBookmarked) {
        await _loopsApi!.unbookmarkVideo(video.id);
      } else {
        await _loopsApi!.bookmarkVideo(video.id);
      }
    } catch (_) {}
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
        action: SnackBarAction(
          label: 'SIGN IN',
          textColor: CyberpunkTheme.neonPink,
          onPressed: () {
            setState(() => _showLoginPage = true);
          },
        ),
      ),
    );
  }

  void _openComments(LoopsVideo video) {
    if (!_isAuthenticated) {
      _showAuthSnackbar('view comments');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        video: video,
        api: _loopsApi!,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  GlobalKey<ReelItemState> _getReelKey(int index) {
    return _reelKeys.putIfAbsent(index, () => GlobalKey<ReelItemState>());
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage && !_isAuthenticated) {
      return LoopsLoginPage(
        onAuthenticated: _onAuthenticated,
        onSkip: _onSkipLogin,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? _buildLoadingSkeleton()
            : _videos.isEmpty
                ? _buildEmptyState()
                : _buildVideoFeed(),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shimmer skeleton
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CyberpunkTheme.surfaceDark,
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: CyberpunkTheme.neonCyan,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading reels...',
              style: TextStyle(
                color: CyberpunkTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadVideos();
            },
            icon: const Icon(Icons.refresh_rounded, color: CyberpunkTheme.neonCyan),
            label: const Text('Try again', style: TextStyle(color: CyberpunkTheme.neonCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoFeed() {
    return RefreshIndicator(
      onRefresh: _refreshVideos,
      color: CyberpunkTheme.neonCyan,
      backgroundColor: CyberpunkTheme.surfaceDark,
      edgeOffset: MediaQuery.of(context).padding.top + 60,
      child: Stack(
        children: [
          // Video PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final video = _videos[index];
              return _buildVideoPage(video, index);
            },
          ),

          // Top bar: Feed tabs (only if authenticated)
          if (_isAuthenticated)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              right: 0,
              child: _buildFeedTabs(),
            ),

          // Double-tap heart animation
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _heartScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScale.value,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: CyberpunkTheme.neonPink,
                      size: 120,
                      shadows: [
                        Shadow(color: CyberpunkTheme.neonPink.withOpacity(0.8), blurRadius: 40),
                        Shadow(color: CyberpunkTheme.neonPink.withOpacity(0.4), blurRadius: 80),
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

  Widget _buildFeedTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (_selectedFeedTab != 0) {
              setState(() {
                _selectedFeedTab = 0;
                _isLoading = true;
              });
              _loadVideos();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For You',
                style: TextStyle(
                  color: _selectedFeedTab == 0 ? Colors.white : Colors.white54,
                  fontWeight: _selectedFeedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 16,
                  shadows: _selectedFeedTab == 0
                      ? [Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _selectedFeedTab == 0 ? 24 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: CyberpunkTheme.neonCyan,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: () {
            if (_selectedFeedTab != 1) {
              setState(() {
                _selectedFeedTab = 1;
                _isLoading = true;
              });
              _loadVideos();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Following',
                style: TextStyle(
                  color: _selectedFeedTab == 1 ? Colors.white : Colors.white54,
                  fontWeight: _selectedFeedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 16,
                  shadows: _selectedFeedTab == 1
                      ? [Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _selectedFeedTab == 1 ? 24 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: CyberpunkTheme.neonCyan,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPage(LoopsVideo video, int index) {
    final isLiked = _likeOverrides[video.id] ?? video.hasLiked;
    final likeCount = _likeCountOverrides[video.id] ?? video.likes;

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

        // Bottom gradient overlay for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Right side action buttons (TikTok-style)
        Positioned(
          right: 12,
          bottom: 100,
          child: _buildActionColumn(video, isLiked, likeCount),
        ),

        // Bottom author info + caption
        Positioned(
          left: 16,
          right: 72,
          bottom: 20,
          child: _buildCaptionOverlay(video),
        ),
      ],
    );
  }

  Widget _buildActionColumn(LoopsVideo video, bool isLiked, int likeCount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _ActionButton(
          icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: _formatCount(likeCount),
          color: isLiked ? CyberpunkTheme.neonPink : Colors.white,
          glowColor: isLiked ? CyberpunkTheme.neonPink : null,
          onTap: () {
            if (_isAuthenticated) {
              _toggleLike(video);
            } else {
              _showAuthSnackbar('like');
            }
          },
        ),
        const SizedBox(height: 20),
        // Comments
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: _formatCount(video.comments),
          color: Colors.white,
          onTap: () => _openComments(video),
        ),
        const SizedBox(height: 20),
        // Bookmark
        _ActionButton(
          icon: video.hasBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: _formatCount(video.bookmarks),
          color: video.hasBookmarked ? CyberpunkTheme.neonCyan : Colors.white,
          glowColor: video.hasBookmarked ? CyberpunkTheme.neonCyan : null,
          onTap: () => _toggleBookmark(video),
        ),
        const SizedBox(height: 20),
        // Share
        _ActionButton(
          icon: Icons.send_rounded,
          label: _formatCount(video.shares),
          color: Colors.white,
          onTap: () {
            if (video.url != null) {
              Share.share(video.url!);
            }
          },
        ),
        const SizedBox(height: 20),
        // Spinning disc (if has audio)
        if (video.hasAudio) _buildSpinningDisc(video),
      ],
    );
  }

  Widget _buildSpinningDisc(LoopsVideo video) {
    final avatar = video.account['avatar'] as String? ?? '';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 360),
      duration: const Duration(seconds: 8),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * pi / 180,
          child: child,
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CyberpunkTheme.borderDark, width: 6),
          color: CyberpunkTheme.surfaceDark,
          image: avatar.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(avatar),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: avatar.isEmpty
            ? const Icon(Icons.music_note_rounded, color: Colors.white54, size: 16)
            : null,
      ),
    );
  }

  Widget _buildCaptionOverlay(LoopsVideo video) {
    final authorName = video.account['username'] as String? ?? 'Unknown';
    final displayName = video.account['name'] as String? ??
        video.account['display_name'] as String? ??
        authorName;
    final authorAvatar = video.account['avatar'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author row
        Row(
          children: [
            // Avatar with neon border
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: authorAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(authorAvatar)
                    : null,
                backgroundColor: CyberpunkTheme.surfaceDark,
                child: authorAvatar.isEmpty
                    ? const Icon(Icons.person, size: 16, color: Colors.white54)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Username
            Flexible(
              child: Text(
                '@$authorName',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            // Follow button (if authenticated and not self)
            if (_isAuthenticated)
              GestureDetector(
                onTap: () {
                  // Follow logic
                  final accountId = video.account['id']?.toString();
                  if (accountId != null) {
                    _loopsApi?.followAccount(accountId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white70, width: 1),
                  ),
                  child: const Text(
                    'Follow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Caption
        if (video.caption != null && video.caption!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ExpandableCaption(text: video.caption!),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable Caption Widget
// ---------------------------------------------------------------------------

class _ExpandableCaption extends StatefulWidget {
  final String text;
  const _ExpandableCaption({required this.text});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: RichText(
        maxLines: _expanded ? 20 : 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          children: [
            TextSpan(text: widget.text),
            if (!_expanded && widget.text.length > 80)
              TextSpan(
                text: ' more',
                style: TextStyle(
                  color: CyberpunkTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Button Widget
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? glowColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: glowColor != null
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor!.withOpacity(0.5),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: Icon(icon, color: color, size: 32),
          ),
          if (label.isNotEmpty && label != '0') ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comments Bottom Sheet
// ---------------------------------------------------------------------------

class _CommentsSheet extends StatefulWidget {
  final LoopsVideo video;
  final LoopsApi api;

  const _CommentsSheet({required this.video, required this.api});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<LoopsComment> _comments = [];
  bool _loading = true;
  final _textController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.api.getVideoComments(widget.video.id);
      if (mounted) setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.postComment(widget.video.id, text);
      _textController.clear();
      await _loadComments();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: CyberpunkTheme.surfaceDark.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: CyberpunkTheme.glassBorder, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CyberpunkTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.video.comments}',
                      style: TextStyle(
                        color: CyberpunkTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: CyberpunkTheme.borderDark, height: 1),
              // Comments list
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: CyberpunkTheme.neonCyan,
                          strokeWidth: 2,
                        ),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet',
                              style: TextStyle(color: CyberpunkTheme.textTertiary),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return _buildCommentTile(comment);
                            },
                          ),
              ),
              // Input area
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 8, 16,
                  MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.cardDark,
                  border: Border(
                    top: BorderSide(color: CyberpunkTheme.borderDark, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: CyberpunkTheme.textTertiary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: CyberpunkTheme.borderDark),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: CyberpunkTheme.borderDark),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: CyberpunkTheme.neonCyan, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor: CyberpunkTheme.surfaceDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendComment,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CyberpunkTheme.neonPink,
                          boxShadow: [
                            BoxShadow(
                              color: CyberpunkTheme.neonPink.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(LoopsComment comment) {
    final username = comment.account?['username'] as String? ?? 'user';
    final avatar = comment.account?['avatar'] as String? ?? '';
    final timeStr = comment.createdAt != null
        ? timeago.format(DateTime.tryParse(comment.createdAt!) ?? DateTime.now())
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            backgroundColor: CyberpunkTheme.cardDark,
            child: avatar.isEmpty
                ? const Icon(Icons.person, size: 14, color: Colors.white54)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: CyberpunkTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
