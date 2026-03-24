import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Instagram-style mixed explore grid layout.
/// Pattern repeats: 3 small squares in a row, then 1 large (2x2) + 2 small stacked.
class ExploreGrid extends StatefulWidget {
  final ApiService apiService;

  const ExploreGrid({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ExploreGrid> createState() => _ExploreGridState();
}

class _ExploreGridState extends State<ExploreGrid>
    with SingleTickerProviderStateMixin {
  List<Status> _posts = [];
  Set<String> _trendingIds = {};
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadPosts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        widget.apiService
            .discoverPosts(limit: 40)
            .catchError((_) => <Status>[]),
        widget.apiService
            .getTrendingPosts(limit: 20)
            .catchError((_) => <Status>[]),
      ]);

      final discover = results[0] as List<Status>;
      final trending = results[1] as List<Status>;

      // Merge, trending first, then discover (deduplicated)
      final trendingIds = trending.map((s) => s.id).toSet();
      final allPosts = <Status>[];
      final seenIds = <String>{};

      for (final s in trending) {
        if (seenIds.add(s.id)) allPosts.add(s);
      }
      for (final s in discover) {
        if (seenIds.add(s.id)) allPosts.add(s);
      }

      if (mounted) {
        setState(() {
          _posts = allPosts;
          _trendingIds = trendingIds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
      );
    }

    if (_hasError || _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_rounded,
                size: 48, color: CyberpunkTheme.textTertiary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              _hasError ? 'Failed to load' : 'No posts yet',
              style: const TextStyle(
                  color: CyberpunkTheme.textSecondary, fontSize: 15),
            ),
            if (_hasError)
              TextButton(
                onPressed: _loadPosts,
                child: const Text('Retry',
                    style: TextStyle(color: CyberpunkTheme.neonCyan)),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: CyberpunkTheme.neonCyan,
      backgroundColor: CyberpunkTheme.cardDark,
      onRefresh: _loadPosts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, sectionIndex) {
                  return _buildSection(sectionIndex);
                },
                childCount: _sectionCount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Number of "sections" in the grid.
  /// Each section consumes 6 posts: row of 3 small + (1 large + 2 small stacked).
  int get _sectionCount => (_posts.length / 6).ceil();

  Widget _buildSection(int sectionIndex) {
    final startIndex = sectionIndex * 6;
    final remaining = _posts.length - startIndex;
    if (remaining <= 0) return const SizedBox.shrink();

    // Alternate: even sections have large on left, odd on right
    final largeOnLeft = sectionIndex.isEven;

    return Column(
      children: [
        // Row 1: 3 small squares
        if (remaining >= 1) _buildSmallRow(startIndex, min(3, remaining)),
        // Row 2: 1 large (2x2) + 2 small stacked
        if (remaining > 3)
          _buildMixedRow(startIndex + 3, min(3, remaining - 3), largeOnLeft),
      ],
    );
  }

  Widget _buildSmallRow(int startIndex, int count) {
    return Row(
      children: List.generate(3, (i) {
        if (i < count) {
          return Expanded(
              child: _buildGridCell(_posts[startIndex + i], isSmall: true));
        }
        return const Expanded(child: SizedBox.shrink());
      }),
    );
  }

  Widget _buildMixedRow(int startIndex, int count, bool largeOnLeft) {
    if (count <= 0) return const SizedBox.shrink();

    final largePost = _posts[startIndex];
    final smallPosts = <Status>[];
    for (int i = 1; i < count; i++) {
      smallPosts.add(_posts[startIndex + i]);
    }

    final largeWidget = Expanded(
      flex: 2,
      child: _buildGridCell(largePost, isLarge: true),
    );

    final smallColumn = Expanded(
      flex: 1,
      child: Column(
        children: [
          if (smallPosts.isNotEmpty)
            _buildGridCell(smallPosts[0], isSmall: true),
          if (smallPosts.length > 1)
            _buildGridCell(smallPosts[1], isSmall: true),
          if (smallPosts.isEmpty)
            const AspectRatio(aspectRatio: 1, child: SizedBox.shrink()),
          if (smallPosts.length == 1)
            const AspectRatio(aspectRatio: 1, child: SizedBox.shrink()),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          largeOnLeft ? [largeWidget, smallColumn] : [smallColumn, largeWidget],
    );
  }

  Widget _buildGridCell(Status post,
      {bool isSmall = false, bool isLarge = false}) {
    final mediaUrl = _getPostMediaUrl(post);
    final isTrending = _trendingIds.contains(post.id);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/PostDetail', arguments: {'post': post});
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: isTrending
                  ? Border.all(
                      color: CyberpunkTheme.neonCyan
                          .withOpacity(0.3 + _pulseController.value * 0.3),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isTrending
                  ? [
                      BoxShadow(
                        color: CyberpunkTheme.neonCyan
                            .withOpacity(0.1 + _pulseController.value * 0.1),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: AspectRatio(
          aspectRatio: isLarge ? 1.0 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (mediaUrl != null)
                  CachedNetworkImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: CyberpunkTheme.cardDark,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: CyberpunkTheme.cardDark,
                      child: const Icon(Icons.broken_image,
                          color: CyberpunkTheme.textTertiary),
                    ),
                  )
                else
                  Container(
                    color: CyberpunkTheme.cardDark,
                    child: const Icon(Icons.image,
                        color: CyberpunkTheme.textTertiary),
                  ),

                // Multi-image indicator
                if (_hasMultipleMedia(post))
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.collections_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),

                // Trending badge
                if (isTrending)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CyberpunkTheme.neonCyan.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded,
                              color: Colors.black, size: 10),
                          SizedBox(width: 2),
                          Text(
                            'Trending',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getPostMediaUrl(Status post) {
    if (post.hasMediaAttachments) {
      final attachment = post.getFirstMedia();
      return attachment?["preview_url"] ?? attachment?["url"];
    }
    return null;
  }

  bool _hasMultipleMedia(Status post) {
    return post.attachement.length > 1;
  }
}
