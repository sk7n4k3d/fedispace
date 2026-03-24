import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:fedispace/widgets/skeleton_loading.dart';
import 'package:fedispace/widgets/cyberpunk_empty_state.dart';
import 'package:fedispace/utils/social_actions.dart';

/// Cyberpunk-themed bookmarks page
class BookmarksPage extends StatefulWidget {
  final ApiService apiService;

  const BookmarksPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Status> _bookmarks = [];
  bool _isLoading = true;
  String? _nextPageId;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks({String? maxId}) async {
    setState(() {
      _isLoading = maxId == null;
    });

    try {
      appLogger.debug('Loading bookmarks');
      final bookmarks = await widget.apiService.getBookmarks(
        maxId: maxId,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        if (maxId == null) {
          _bookmarks = bookmarks;
        } else {
          _bookmarks.addAll(bookmarks);
        }
        _nextPageId = bookmarks.isNotEmpty ? bookmarks.last.id : null;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading bookmarks', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLike(Status status) {
    widget.apiService.favoriteStatus(status.id);
  }

  void _handleComment(Status status) {
    Navigator.pushNamed(
      context,
      '/statusDetail',
      arguments: {
        'statusId': status.id,
        'apiService': widget.apiService,
      },
    );
  }

  void _handleShare(Status status) {
    SocialActions.shareStatus(status);
  }

  void _handleBookmark(Status status) async {
    setState(() {
      _bookmarks.removeWhere((b) => b.id == status.id);
    });
    try {
      await widget.apiService.undoBookmarkStatus(status.id);
    } catch (e) {
      appLogger.error('Failed to remove bookmark', e);
      setState(() {
        _bookmarks.add(status);
      });
    }
  }

  void _handleProfileTap(Status status) {
    Navigator.pushNamed(
      context,
      '/UserProfile',
      arguments: {'userId': status.account.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.of(context).bookmarks,
          style: GoogleFonts.inter(
            color: CyberpunkTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: List.generate(
          3,
          (_) => const TimelineSkeleton(),
        ),
      );
    }

    if (_bookmarks.isEmpty) {
      return CyberpunkEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: S.of(context).bookmarks,
        subtitle: 'Save photos and videos that you want to see again. No one is notified, and only you can see what you\'ve saved.',
        accentColor: CyberpunkTheme.neonCyan,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookmarks(),
      color: CyberpunkTheme.neonCyan,
      backgroundColor: CyberpunkTheme.cardDark,
      child: ListView.builder(
        itemCount: _bookmarks.length + (_nextPageId != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookmarks.length) {
            return Padding(
              padding: const EdgeInsets.all(CyberpunkTheme.spacingL),
              child: Center(
                child: TextButton(
                  onPressed: () => _loadBookmarks(maxId: _nextPageId),
                  child: Text(
                    S.of(context).loading,
                    style: GoogleFonts.inter(color: CyberpunkTheme.neonCyan),
                  ),
                ),
              ),
            );
          }

          final bookmark = _bookmarks[index];
          return InstagramPostCard(
            status: bookmark,
            onLike: () => _handleLike(bookmark),
            onComment: () => _handleComment(bookmark),
            onShare: () => _handleShare(bookmark),
            onBookmark: () => _handleBookmark(bookmark),
            onProfileTap: () => _handleProfileTap(bookmark),
          );
        },
      ),
    );
  }
}
