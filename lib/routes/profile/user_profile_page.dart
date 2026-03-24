import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:fedispace/widgets/skeleton_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:fedispace/routes/messages/conversation_detail_page.dart';
import 'package:fedispace/routes/profile/collections_page.dart';

/// Cyberpunk-themed user profile page for viewing other users
class UserProfilePage extends StatefulWidget {
  final ApiService apiService;
  final String userId;

  const UserProfilePage({
    Key? key,
    required this.apiService,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  AccountUsers? _account;
  List<Status> _posts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  bool _isFollowing = false;
  bool _isPinned = false;
  
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      appLogger.debug('Loading user profile: ${widget.userId}');
      final account = await widget.apiService.getUserAccount(widget.userId);
      
      bool following = account.following ?? false;
      try {
        final rels = await widget.apiService.getRelationships([widget.userId]);
        if (rels.isNotEmpty) {
          following = rels[0]['following'] == true;
          _isPinned = rels[0]['endorsed'] == true;
        }
      } catch (e) {
        appLogger.error('Error loading relationships', e);
      }

      if (!mounted) return;
      setState(() {
        _account = account;
        _isFollowing = following;
        _isLoading = false;
      });
      _loadPosts();
    } catch (error, stackTrace) {
      appLogger.error('Error loading profile', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final response =
          await widget.apiService.getUserStatus(widget.userId, 1, null);
      final List<dynamic> postsData = response as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _posts = postsData
            .map((data) => Status.fromJson(data as Map<String, dynamic>))
            .toList();
        _isLoadingPosts = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading posts', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await widget.apiService.unFollow(widget.userId);
      } else {
        await widget.apiService.followStatus(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error toggling follow', error, stackTrace);
    }
  }

  void _navigateToFollowers() {
    Navigator.pushNamed(
      context,
      '/FollowersList',
      arguments: {'userId': widget.userId, 'isFollowers': true},
    );
  }

  void _navigateToFollowing() {
    Navigator.pushNamed(
      context,
      '/FollowersList',
      arguments: {'userId': widget.userId, 'isFollowers': false},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        appBar: AppBar(backgroundColor: CyberpunkTheme.backgroundBlack),
        body: const SingleChildScrollView(child: ProfileSkeleton()),
      );
    }

    if (_account == null) {
      return Scaffold(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        appBar: AppBar(backgroundColor: CyberpunkTheme.backgroundBlack),
        body: Center(child: Text(S.of(context).error, style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        title: Text(
          _account!.username,
          style: GoogleFonts.inter(
            color: CyberpunkTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: CyberpunkTheme.textWhite),
            onSelected: (value) async {
              if (value == 'block') {
                 await widget.apiService.blockUser(widget.userId);
                 if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).block)));
              } else if (value == 'mute') {
                 await widget.apiService.muteUser(widget.userId);
                 if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).mute)));
              } else if (value == 'report') {
                 _showReportDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'mute',
                child: Text(S.of(context).mute),
              ),
              PopupMenuItem<String>(
                value: 'block',
                child: Text(S.of(context).block),
              ),
              PopupMenuItem<String>(
                value: 'report',
                child: Text(S.of(context).report),
              ),
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  _buildBio(),
                  _buildActionButtons(),
                  const SizedBox(height: CyberpunkTheme.spacingL),
                  Container(height: 0.5, color: CyberpunkTheme.borderDark),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  onTap: (index) => setState(() => _currentTab = index),
                  indicatorColor: CyberpunkTheme.neonCyan,
                  labelColor: CyberpunkTheme.textWhite,
                  unselectedLabelColor: CyberpunkTheme.textTertiary,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.person_pin_outlined)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            _buildTaggedGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(CyberpunkTheme.spacingL),
      child: Row(
        children: [
          // Avatar with neon cyan ring + glow (matching profile.dart)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: CyberpunkTheme.neonCyan.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CyberpunkTheme.neonCyan.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: CyberpunkTheme.cardDark,
                backgroundImage: _account!.avatar.isNotEmpty
                    ? CachedNetworkImageProvider(_account!.avatar)
                    : null,
                child: _account!.avatar.isEmpty
                    ? const Icon(Icons.person, size: 36, color: CyberpunkTheme.textTertiary)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                    _account!.statuses_count?.toString() ?? '0', S.of(context).posts),
                GestureDetector(
                  onTap: _navigateToFollowers,
                  child: _buildStatColumn(
                      _account!.followers_count?.toString() ?? '0',
                      S.of(context).followers),
                ),
                GestureDetector(
                  onTap: _navigateToFollowing,
                  child: _buildStatColumn(
                      _account!.following_count?.toString() ?? '0',
                      S.of(context).following),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CyberpunkTheme.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CyberpunkTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBio() {
    if (_account!.display_name.isEmpty && _account!.note.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CyberpunkTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_account!.display_name.isNotEmpty)
            Text(
              _account!.display_name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CyberpunkTheme.textWhite,
              ),
            ),
          if (_account!.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _account!.note.replaceAll(RegExp(r'<[^>]*>'), ''),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CyberpunkTheme.textWhite.withOpacity(0.9),
              ),
            ),
          ],
          const SizedBox(height: CyberpunkTheme.spacingL),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CyberpunkTheme.spacingL),
      child: Row(
        children: [
          // Follow Button
          Expanded(
            child: SizedBox(
               height: 35,
               child: InstagramFollowButton(
                isFollowing: _isFollowing,
                onPressed: _toggleFollow,
              ),
            ),
          ),
          const SizedBox(width: CyberpunkTheme.spacingS),
          
          // Message Button
          SizedBox(
            width: 45,
            height: 35,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: CyberpunkTheme.borderDark),
                borderRadius: BorderRadius.circular(CyberpunkTheme.radiusS),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.mail_outline, size: 20, color: CyberpunkTheme.textWhite),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationDetailPage(
                        apiService: widget.apiService,
                        conversationId: _account!.username,
                        recipientName: _account!.display_name.isNotEmpty ? _account!.display_name : _account!.username,
                        recipientUsername: _account!.username,
                        recipientAvatar: _account!.avatar.isNotEmpty ? _account!.avatar : null,
                        recipientId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: CyberpunkTheme.spacingS),

          // More Options Button
          SizedBox(
            width: 45,
            height: 35,
             child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: CyberpunkTheme.borderDark),
                borderRadius: BorderRadius.circular(CyberpunkTheme.radiusS),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz, size: 20, color: CyberpunkTheme.textWhite),
                onPressed: _showMoreOptions,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CyberpunkTheme.radiusRound)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: CyberpunkTheme.textWhite),
              title: Text(_isPinned ? 'Unpin account' : 'Pin account', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = _isPinned
                    ? await widget.apiService.unpinAccount(widget.userId)
                    : await widget.apiService.pinAccount(widget.userId);
                if (mounted) {
                  if (ok) setState(() => _isPinned = !_isPinned);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? S.of(context).success : S.of(context).error, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
                    backgroundColor: ok ? CyberpunkTheme.neonCyan.withOpacity(0.8) : CyberpunkTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline, color: CyberpunkTheme.textWhite),
              title: Text('Endorsements', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
              onTap: () async {
                Navigator.pop(ctx);
                _showEndorsements();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_outlined, color: CyberpunkTheme.textWhite),
              title: Text('Lists', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
              onTap: () async {
                Navigator.pop(ctx);
                _showAccountLists();
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined, color: CyberpunkTheme.textWhite),
              title: Text(S.of(context).collections, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CollectionsPage(apiService: widget.apiService, accountId: widget.userId),
                ));
              },
            ),
            const Divider(color: CyberpunkTheme.borderDark),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred, color: CyberpunkTheme.errorRed),
              title: Text(S.of(context).report, style: GoogleFonts.inter(color: CyberpunkTheme.errorRed)),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: CyberpunkTheme.errorRed),
              title: Text(S.of(context).block, style: GoogleFonts.inter(color: CyberpunkTheme.errorRed)),
              onTap: () async {
                Navigator.pop(ctx);
                await widget.apiService.blockUser(widget.userId);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).block)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off, color: CyberpunkTheme.textWhite),
              title: Text(S.of(context).mute, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
              onTap: () async {
                Navigator.pop(ctx);
                await widget.apiService.muteUser(widget.userId);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).mute)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: CyberpunkTheme.textWhite),
              title: Text(S.of(context).unfollow, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await widget.apiService.removeFromFollowers(widget.userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? S.of(context).success : S.of(context).error, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEndorsements() async {
    try {
      final endorsements = await widget.apiService.getEndorsements(limit: 40);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(CyberpunkTheme.radiusRound))),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, borderRadius: BorderRadius.circular(2))),
              Padding(padding: const EdgeInsets.all(12), child: Text('Endorsements', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700))),
              if (endorsements.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('No endorsements', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary)))
              else
                ...endorsements.take(20).map((a) => ListTile(
                  leading: CircleAvatar(backgroundImage: a.avatar != null && a.avatar!.isNotEmpty ? NetworkImage(a.avatar!) : null, child: a.avatar == null || a.avatar!.isEmpty ? const Icon(Icons.person) : null),
                  title: Text(a.display_name ?? a.username ?? '', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
                  subtitle: Text('@${a.username ?? ''}', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary)),
                  onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': a.id}); },
                )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).error)));
    }
  }

  void _showAccountLists() async {
    try {
      final lists = await widget.apiService.getAccountLists(widget.userId);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(CyberpunkTheme.radiusRound))),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, borderRadius: BorderRadius.circular(2))),
              Padding(padding: const EdgeInsets.all(12), child: Text('Lists', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700))),
              if (lists.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text('Not in any lists', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary)))
              else
                ...lists.take(20).map((l) => ListTile(
                  leading: const Icon(Icons.list, color: CyberpunkTheme.neonCyan),
                  title: Text(l['title'] ?? 'Untitled', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
                )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).error)));
    }
  }

  void _showReportDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.cardDark,
        title: Text(S.of(context).report, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite)),
        content: TextField(
          controller: reasonController,
          style: GoogleFonts.inter(color: CyberpunkTheme.textWhite),
          decoration: InputDecoration(
            hintText: S.of(context).report,
            hintStyle: GoogleFonts.inter(color: CyberpunkTheme.textTertiary),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel, style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.apiService.reportUser(widget.userId, comment: reasonController.text);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).success)));
            },
            child: Text(S.of(context).report, style: GoogleFonts.inter(color: CyberpunkTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_isLoadingPosts) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.5,
          mainAxisSpacing: 1.5,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => SkeletonLoading(
          child: Container(color: CyberpunkTheme.cardDark),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 64, color: CyberpunkTheme.textTertiary),
            const SizedBox(height: CyberpunkTheme.spacingL),
            Text(
              S.of(context).noPosts,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        
        final firstMedia = post.getFirstMedia();
        final isVideoType = firstMedia != null && (firstMedia['type'] == 'video' || firstMedia['type'] == 'gifv');
        final isVideoExtension = post.attach.toLowerCase().contains('.mp4') || post.attach.toLowerCase().contains('.mov');
        final isVideo = isVideoType || isVideoExtension;

        String imageUrl = post.preview_url;
        if (imageUrl.isEmpty && !isVideo) {
          imageUrl = post.attach;
        }

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/statusDetail',
              arguments: {
                'statusId': post.id,
                'apiService': widget.apiService,
              },
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProfileVideoItem(url: post.attach, previewUrl: post.preview_url),
                      const Center(
                        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                      ),
                    ],
                  ),
                )
              else if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: CyberpunkTheme.cardDark),
                  errorWidget: (context, url, error) => Container(
                    color: CyberpunkTheme.cardDark,
                    child: const Icon(Icons.error, color: CyberpunkTheme.textTertiary),
                  ),
                )
              else if (post.blurhash.isNotEmpty)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    BlurHash(hash: post.blurhash),
                    Container(color: Colors.black26),
                  ],
                )
              else
                Container(
                  color: CyberpunkTheme.cardDark,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: CyberpunkTheme.textTertiary, size: 32),
                  ),
                ),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                ),
              if (post.attachement.length > 1)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: CyberpunkTheme.backgroundBlack.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.collections_rounded, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaggedGrid() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin_outlined, size: 64, color: CyberpunkTheme.textTertiary),
          const SizedBox(height: CyberpunkTheme.spacingL),
          Text(
            S.of(context).noPosts,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: CyberpunkTheme.backgroundBlack,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

/// Lightweight video thumbnail
class _ProfileVideoItem extends StatelessWidget {
  final String url;
  final String? previewUrl;
  const _ProfileVideoItem({Key? key, required this.url, this.previewUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (previewUrl != null && previewUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: CyberpunkTheme.cardDark,
          child: const Center(child: InstagramLoadingIndicator(size: 16)),
        ),
        errorWidget: (context, url, error) => Container(
          color: CyberpunkTheme.cardDark,
          child: const Icon(Icons.videocam_outlined, color: CyberpunkTheme.textTertiary, size: 24),
        ),
      );
    }
    return Container(
      color: CyberpunkTheme.cardDark,
      child: const Icon(Icons.videocam_outlined, color: CyberpunkTheme.textTertiary, size: 24),
    );
  }
}
