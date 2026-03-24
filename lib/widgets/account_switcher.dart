import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/account_manager.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Shows a bottom sheet for switching between multiple Pixelfed accounts.
class AccountSwitcher {
  static Future<AccountCredential?> show(
    BuildContext context,
    ApiService apiService,
  ) async {
    return showModalBottomSheet<AccountCredential>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AccountSwitcherSheet(apiService: apiService),
    );
  }
}

class _AccountSwitcherSheet extends StatefulWidget {
  final ApiService apiService;

  const _AccountSwitcherSheet({required this.apiService});

  @override
  State<_AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<_AccountSwitcherSheet> {
  final AccountManager _manager = AccountManager();
  List<AccountCredential> _accounts = [];
  String? _activeKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _manager.getAccounts();
    final active = await _manager.getActiveAccount();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _activeKey = active?.uniqueKey;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchAccount(AccountCredential account) async {
    await _manager.setActiveAccount(account.instanceUrl, account.userId);
    if (mounted) {
      Navigator.of(context).pop(account);
    }
  }

  Future<void> _removeAccount(AccountCredential account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.cardDark,
        title: const Text('Remove Account',
            style: TextStyle(color: CyberpunkTheme.textWhite)),
        content: Text(
          'Remove ${account.displayHandle}?',
          style: const TextStyle(color: CyberpunkTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _manager.removeAccount(account.instanceUrl, account.userId);
      await _loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: CyberpunkTheme.glassBorder, width: 0.5),
          left: BorderSide(color: CyberpunkTheme.glassBorder, width: 0.5),
          right: BorderSide(color: CyberpunkTheme.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CyberpunkTheme.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.switch_account_rounded,
                    color: CyberpunkTheme.neonCyan, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Switch Account',
                  style: TextStyle(
                    color: CyberpunkTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: CyberpunkTheme.borderDark),

          // Account list
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  final isActive = account.uniqueKey == _activeKey;
                  return _AccountTile(
                    account: account,
                    isActive: isActive,
                    onTap: () => _switchAccount(account),
                    onLongPress: () => _removeAccount(account),
                  );
                },
              ),
            ),

          // Add account button
          const Divider(height: 1, color: CyberpunkTheme.borderDark),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/Login');
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                          width: 1.5,
                        ),
                        color: CyberpunkTheme.neonCyan.withOpacity(0.08),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: CyberpunkTheme.neonCyan, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Add Account',
                      style: TextStyle(
                        color: CyberpunkTheme.neonCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountCredential account;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AccountTile({
    required this.account,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: isActive
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: CyberpunkTheme.neonCyan, width: 3),
                  ),
                  color: CyberpunkTheme.neonCyan.withOpacity(0.05),
                )
              : null,
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? CyberpunkTheme.neonCyan
                        : CyberpunkTheme.borderDark,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: account.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: account.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: CyberpunkTheme.cardDark,
                            child: const Icon(Icons.person,
                                color: CyberpunkTheme.textTertiary),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: CyberpunkTheme.cardDark,
                            child: const Icon(Icons.person,
                                color: CyberpunkTheme.textTertiary),
                          ),
                        )
                      : Container(
                          color: CyberpunkTheme.cardDark,
                          child: const Icon(Icons.person,
                              color: CyberpunkTheme.textTertiary),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Name and handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName ?? account.username,
                      style: TextStyle(
                        color: isActive
                            ? CyberpunkTheme.neonCyan
                            : CyberpunkTheme.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.displayHandle,
                      style: const TextStyle(
                        color: CyberpunkTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Active indicator
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: CyberpunkTheme.neonCyan.withOpacity(0.15),
                    border: Border.all(
                      color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: CyberpunkTheme.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
