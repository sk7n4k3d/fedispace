import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'conversation_detail_page.dart';

/// New Direct Message - Select recipient page
class NewMessagePage extends StatefulWidget {
  final ApiService apiService;

  const NewMessagePage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  List<_UserSearchResult> _mutuals = [];
  bool _isLoadingMutuals = true;

  @override
  void initState() {
    super.initState();
    _loadMutuals();
  }

  Future<void> _loadMutuals() async {
    try {
      final mutuals = await widget.apiService.getDmMutuals();
      if (mounted) {
        setState(() {
          _mutuals = mutuals.map((a) => _UserSearchResult(
            id: a.id ?? '',
            username: a.username ?? '',
            displayName: a.display_name ?? a.username ?? '',
            avatarUrl: a.avatar,
          )).toList();
          _isLoadingMutuals = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMutuals = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      appLogger.debug('Searching DM users: $query');
      // Use lookupDmUser for DM-optimized search, fall back to searchAccounts
      List<Account> results = [];
      try {
        results = await widget.apiService.lookupDmUser(query);
      } catch (_) {}
      if (results.isEmpty) {
        final acctResults = await widget.apiService.searchAccounts(query);
        setState(() {
          _isSearching = false;
          _searchResults.clear();
          for (var account in acctResults) {
            _searchResults.add(_UserSearchResult(
              id: account.id,
              username: account.username,
              displayName: account.display_name,
              avatarUrl: account.avatar.isNotEmpty ? account.avatar : null,
            ));
          }
        });
      } else {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
          for (var account in results) {
            _searchResults.add(_UserSearchResult(
              id: account.id ?? '',
              username: account.username ?? '',
              displayName: account.display_name ?? account.username ?? '',
              avatarUrl: (account.avatar != null && account.avatar!.isNotEmpty) ? account.avatar : null,
            ));
          }
        });
      }
    } catch (error, stackTrace) {
      appLogger.error('Error searching users', error, stackTrace);
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _startConversation(_UserSearchResult user) {
    // Navigate to conversation page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationDetailPage(
          apiService: widget.apiService,
          conversationId: 'new_${user.id}', // Temp ID
          recipientName: user.displayName,
          recipientUsername: user.username,
          recipientAvatar: user.avatarUrl,
          recipientId: user.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).newMessage),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? S.of(context).searchPeople
                              : S.of(context).noResults,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.username}'),
                            onTap: () => _startConversation(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualsSection(bool isDark) {
    if (_isLoadingMutuals) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mutuals.isEmpty) {
      return Center(
        child: Text(S.of(context).searchPeople, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Mutual followers', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _mutuals.length,
            itemBuilder: (context, index) {
              final user = _mutuals[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.displayName),
                subtitle: Text('@${user.username}'),
                onTap: () => _startConversation(user),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Placeholder user search result model
class _UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  _UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });
}
