import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/groups_api.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Group detail page showing group feed, members, and info.
class GroupDetailPage extends StatefulWidget {
  final ApiService apiService;
  final String groupId;
  final String groupName;

  const GroupDetailPage({
    Key? key,
    required this.apiService,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late final GroupsApi _groupsApi;
  late final TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _groupInfo;
  List<Status> _feed = [];
  List<Map<String, dynamic>> _members = [];
  bool _isMember = false;
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _groupsApi = GroupsApi(apiService: widget.apiService);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _groupsApi.getGroup(widget.groupId),
        _groupsApi.getGroupFeed(widget.groupId),
        _groupsApi.getGroupMembers(widget.groupId),
      ]);
      if (mounted) {
        setState(() {
          _groupInfo = results[0] as Map<String, dynamic>?;
          _feed = results[1] as List<Status>;
          _members = results[2] as List<Map<String, dynamic>>;
          _isMember = _groupInfo?['is_member'] == true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMembership() async {
    if (_isMember) {
      final ok = await _groupsApi.leaveGroup(widget.groupId);
      if (ok && mounted) setState(() => _isMember = false);
    } else {
      final ok = await _groupsApi.joinGroup(widget.groupId);
      if (ok && mounted) setState(() => _isMember = true);
    }
  }

  Future<void> _postToGroup() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    final ok = await _groupsApi.postToGroup(widget.groupId, text);
    if (ok && mounted) {
      _postController.clear();
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: CyberpunkTheme.backgroundBlack,
        actions: [
          TextButton(
            onPressed: _toggleMembership,
            child: Text(
              _isMember ? 'Leave' : 'Join',
              style: TextStyle(
                color: _isMember ? Colors.redAccent : CyberpunkTheme.neonCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CyberpunkTheme.neonCyan,
          labelColor: CyberpunkTheme.neonCyan,
          unselectedLabelColor: CyberpunkTheme.textTertiary,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Members'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedTab(),
                _buildMembersTab(),
                _buildInfoTab(),
              ],
            ),
    );
  }

  Widget _buildFeedTab() {
    return Column(
      children: [
        // Post composer
        if (_isMember)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: CyberpunkTheme.borderDark, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'Write something...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: _postToGroup,
                  icon: const Icon(Icons.send_rounded,
                      color: CyberpunkTheme.neonCyan),
                ),
              ],
            ),
          ),

        // Feed list
        Expanded(
          child: _feed.isEmpty
              ? const Center(
                  child: Text('No posts yet',
                      style: TextStyle(color: CyberpunkTheme.textSecondary)))
              : RefreshIndicator(
                  color: CyberpunkTheme.neonCyan,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _feed.length,
                    itemBuilder: (context, index) {
                      final status = _feed[index];
                      return _buildFeedItem(status);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFeedItem(Status status) {
    final content = status.content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberpunkTheme.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Text(status.acct,
                  style: const TextStyle(
                      color: CyberpunkTheme.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const Spacer(),
              Text(
                  status.created_at.length > 10
                      ? status.created_at.substring(0, 10)
                      : status.created_at,
                  style: const TextStyle(
                      color: CyberpunkTheme.textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(
                  color: CyberpunkTheme.textWhite, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_border,
                  size: 16, color: CyberpunkTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${status.favourites_count}',
                  style: const TextStyle(
                      color: CyberpunkTheme.textTertiary, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined,
                  size: 16, color: CyberpunkTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${status.replies_count}',
                  style: const TextStyle(
                      color: CyberpunkTheme.textTertiary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(
          child: Text('No members data',
              style: TextStyle(color: CyberpunkTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final username = member['username']?.toString() ??
            member['acct']?.toString() ??
            'Unknown';
        final avatar = member['avatar']?.toString() ?? '';
        final displayName = member['display_name']?.toString() ?? username;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            backgroundColor: CyberpunkTheme.surfaceDark,
          ),
          title: Text(displayName, style: const TextStyle(fontSize: 14)),
          subtitle: Text('@$username',
              style: const TextStyle(
                  color: CyberpunkTheme.textTertiary, fontSize: 12)),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    final description =
        _groupInfo?['description']?.toString() ?? 'No description';
    final category = _groupInfo?['category']?.toString() ?? '';
    final privacy = _groupInfo?['privacy']?.toString() ?? 'public';
    final memberCount = _groupInfo?['member_count'] ?? _members.length;
    final createdAt = _groupInfo?['created_at']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CyberpunkTheme.glassWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About',
                  style: TextStyle(
                      color: CyberpunkTheme.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(description,
                  style: const TextStyle(
                      color: CyberpunkTheme.textWhite, fontSize: 14)),
              const SizedBox(height: 16),
              _infoRow(Icons.people_outline, 'Members', '$memberCount'),
              _infoRow(Icons.lock_outline, 'Privacy', privacy),
              if (category.isNotEmpty)
                _infoRow(Icons.category_outlined, 'Category', category),
              if (createdAt.isNotEmpty)
                _infoRow(
                    Icons.calendar_today_outlined,
                    'Created',
                    createdAt.length > 10
                        ? createdAt.substring(0, 10)
                        : createdAt),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CyberpunkTheme.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: CyberpunkTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: CyberpunkTheme.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
