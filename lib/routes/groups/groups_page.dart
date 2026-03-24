import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/groups_api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/groups/group_detail_page.dart';
import 'package:fedispace/routes/groups/create_group_page.dart';

/// Groups listing page showing popular and joined groups.
class GroupsPage extends StatefulWidget {
  final ApiService apiService;

  const GroupsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  late final GroupsApi _groupsApi;
  late final TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _popularGroups = [];
  List<Map<String, dynamic>> _joinedGroups = [];

  @override
  void initState() {
    super.initState();
    _groupsApi = GroupsApi(apiService: widget.apiService);
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _groupsApi.listGroups(),
        _groupsApi.listJoinedGroups(),
      ]);
      if (mounted) {
        setState(() {
          _popularGroups = results[0];
          _joinedGroups = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: CyberpunkTheme.backgroundBlack,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CyberpunkTheme.neonCyan,
          labelColor: CyberpunkTheme.neonCyan,
          unselectedLabelColor: CyberpunkTheme.textTertiary,
          tabs: const [
            Tab(text: 'Popular'),
            Tab(text: 'Joined'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateGroupPage(apiService: widget.apiService),
          ),
        ).then((_) => _loadGroups()),
        backgroundColor: CyberpunkTheme.neonCyan,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupList(_popularGroups, emptyText: 'No groups found'),
                _buildGroupList(_joinedGroups,
                    emptyText: 'You haven\'t joined any groups'),
              ],
            ),
    );
  }

  Widget _buildGroupList(List<Map<String, dynamic>> groups,
      {required String emptyText}) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined,
                color: CyberpunkTheme.textTertiary, size: 64),
            const SizedBox(height: 16),
            Text(emptyText,
                style: const TextStyle(
                    color: CyberpunkTheme.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: CyberpunkTheme.neonCyan,
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name']?.toString() ?? 'Unnamed Group';
    final description = group['description']?.toString() ?? '';
    final memberCount = group['member_count'] ?? 0;
    final category = group['category']?.toString() ?? '';
    final groupId = group['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailPage(
            apiService: widget.apiService,
            groupId: groupId,
            groupName: name,
          ),
        ),
      ).then((_) => _loadGroups()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberpunkTheme.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CyberpunkTheme.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_rounded,
                  color: CyberpunkTheme.neonCyan),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: CyberpunkTheme.textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: CyberpunkTheme.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (category.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: CyberpunkTheme.neonPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category,
                              style: const TextStyle(
                                  color: CyberpunkTheme.neonPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.people_outline,
                          size: 14, color: CyberpunkTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text('$memberCount members',
                          style: const TextStyle(
                              color: CyberpunkTheme.textTertiary,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: CyberpunkTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
