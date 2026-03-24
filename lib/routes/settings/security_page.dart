import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/security_api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Account Security Dashboard with cyberpunk styling.
class SecurityPage extends StatefulWidget {
  final ApiService apiService;
  const SecurityPage({Key? key, required this.apiService}) : super(key: key);
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  late final SecurityApi _securityApi;
  bool _isLoading = true;
  List<Map<String, dynamic>> _loginActivity = [];
  Map<String, dynamic> _twoFactorStatus = {};
  List<Map<String, dynamic>> _authorizedApps = [];
  Map<String, dynamic> _emailPrefs = {};
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPasswords = false;

  @override
  void initState() {
    super.initState();
    _securityApi = SecurityApi(apiService: widget.apiService);
    _loadData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _securityApi.getLoginActivity(),
        _securityApi.getTwoFactorStatus(),
        _securityApi.getAuthorizedApps(),
        _securityApi.getEmailPreferences(),
      ]);
      if (mounted) {
        setState(() {
          _loginActivity = results[0] as List<Map<String, dynamic>>;
          _twoFactorStatus = results[1] as Map<String, dynamic>;
          _authorizedApps = results[2] as List<Map<String, dynamic>>;
          _emailPrefs = results[3] as Map<String, dynamic>;
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
        title: const Text('Security'),
        backgroundColor: CyberpunkTheme.backgroundBlack,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan))
          : RefreshIndicator(
              color: CyberpunkTheme.neonCyan,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader('Two-Factor Authentication', Icons.security_rounded),
                  _twoFactorCard(),
                  const SizedBox(height: 24),
                  _sectionHeader('Recent Login Activity', Icons.history_rounded),
                  _loginActivityList(),
                  const SizedBox(height: 24),
                  _sectionHeader('Authorized Apps', Icons.apps_rounded),
                  _authorizedAppsList(),
                  const SizedBox(height: 24),
                  _sectionHeader('Change Password', Icons.lock_rounded),
                  _changePasswordForm(),
                  const SizedBox(height: 24),
                  _sectionHeader('Email Notifications', Icons.email_rounded),
                  _emailPreferencesWidget(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: CyberpunkTheme.neonCyan, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          color: CyberpunkTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.w600,
          shadows: [Shadow(color: CyberpunkTheme.neonCyan, blurRadius: 8)],
        )),
      ]),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: CyberpunkTheme.glassWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _twoFactorCard() {
    final enabled = _twoFactorStatus['enabled'] == true;
    return _glassCard(
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? CyberpunkTheme.neonCyan.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          ),
          child: Icon(enabled ? Icons.shield_rounded : Icons.shield_outlined,
            color: enabled ? CyberpunkTheme.neonCyan : Colors.redAccent),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(enabled ? '2FA Enabled' : '2FA Disabled',
              style: TextStyle(color: enabled ? CyberpunkTheme.neonCyan : Colors.redAccent,
                fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(enabled
                ? 'Your account is protected with two-factor authentication.'
                : 'Enable 2FA to add an extra layer of security.',
              style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13)),
          ],
        )),
        ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA setup requires your instance web UI'))),
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? CyberpunkTheme.cardDark : CyberpunkTheme.neonCyan,
            foregroundColor: enabled ? CyberpunkTheme.textWhite : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(enabled ? 'Manage' : 'Setup'),
        ),
      ]),
    );
  }

  Widget _loginActivityList() {
    if (_loginActivity.isEmpty) {
      return _glassCard(child: const Center(child: Text(
        'No login activity data available',
        style: TextStyle(color: CyberpunkTheme.textSecondary))));
    }
    return _glassCard(child: Column(
      children: _loginActivity.take(10).map((s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Icon(Icons.devices_rounded, color: CyberpunkTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['device']?.toString() ?? s['user_agent']?.toString() ?? 'Unknown device',
              style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${s['ip'] ?? 'Unknown IP'} - ${s['created_at'] ?? ''}',
              style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 11)),
          ])),
        ]),
      )).toList(),
    ));
  }

  Widget _authorizedAppsList() {
    if (_authorizedApps.isEmpty) {
      return _glassCard(child: const Center(child: Text(
        'No authorized apps found',
        style: TextStyle(color: CyberpunkTheme.textSecondary))));
    }
    return _glassCard(child: Column(
      children: _authorizedApps.map((app) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Icon(Icons.apps_rounded, color: CyberpunkTheme.neonCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(app['name']?.toString() ?? 'Unknown app',
            style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14))),
          TextButton(
            onPressed: () async {
              final id = app['id']?.toString();
              if (id != null) {
                final ok = await _securityApi.revokeApp(id);
                if (ok && mounted) _loadData();
              }
            },
            child: const Text('Revoke', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ]),
      )).toList(),
    ));
  }

  Widget _changePasswordForm() {
    return _glassCard(child: Column(children: [
      TextField(controller: _currentPasswordController, obscureText: !_showPasswords,
        decoration: const InputDecoration(labelText: 'Current password', prefixIcon: Icon(Icons.lock_outline_rounded))),
      const SizedBox(height: 12),
      TextField(controller: _newPasswordController, obscureText: !_showPasswords,
        decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.lock_rounded))),
      const SizedBox(height: 12),
      TextField(controller: _confirmPasswordController, obscureText: !_showPasswords,
        decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.lock_rounded))),
      const SizedBox(height: 8),
      Row(children: [
        Switch(value: _showPasswords, onChanged: (v) => setState(() => _showPasswords = v)),
        const Text('Show passwords', style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        ElevatedButton(
          onPressed: _handleChangePassword,
          style: ElevatedButton.styleFrom(backgroundColor: CyberpunkTheme.neonCyan, foregroundColor: Colors.black),
          child: const Text('Update'),
        ),
      ]),
    ]));
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (current.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all password fields')));
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }
    if (newPass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters')));
      return;
    }
    final success = await _securityApi.changePassword(current, newPass);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Password updated' : 'Failed to update password')));
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    }
  }

  Widget _emailPreferencesWidget() {
    final items = <String, String>{
      'on_follow': 'New followers',
      'on_mention': 'Mentions',
      'on_favourite': 'Likes',
      'on_reblog': 'Boosts',
    };
    return _glassCard(child: Column(
      children: items.entries.map((e) => SwitchListTile(
        title: Text(e.value, style: const TextStyle(fontSize: 14)),
        value: _emailPrefs[e.key] == true,
        onChanged: (v) async {
          setState(() => _emailPrefs[e.key] = v);
          final prefs = <String, bool>{};
          for (final k in items.keys) { prefs[k] = _emailPrefs[k] == true; }
          await _securityApi.updateEmailPreferences(prefs);
        },
        contentPadding: EdgeInsets.zero, dense: true,
      )).toList(),
    ));
  }
}
