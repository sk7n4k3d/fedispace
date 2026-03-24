import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Represents a single Pixelfed account credential set.
class AccountCredential {
  final String instanceUrl;
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? displayName;
  final bool isActive;

  const AccountCredential({
    required this.instanceUrl,
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.displayName,
    this.isActive = false,
  });

  AccountCredential copyWith({
    String? instanceUrl,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? username,
    String? avatarUrl,
    String? displayName,
    bool? isActive,
  }) {
    return AccountCredential(
      instanceUrl: instanceUrl ?? this.instanceUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Unique key for this account
  String get uniqueKey => '$userId@$instanceUrl';

  /// Display string like username@instance
  String get displayHandle {
    final uri = Uri.tryParse(instanceUrl);
    final host = uri?.host ?? instanceUrl;
    return '@$username@$host';
  }

  Map<String, dynamic> toJson() => {
    'instanceUrl': instanceUrl,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userId': userId,
    'username': username,
    'avatarUrl': avatarUrl,
    'displayName': displayName,
    'isActive': isActive,
  };

  factory AccountCredential.fromJson(Map<String, dynamic> json) {
    return AccountCredential(
      instanceUrl: json['instanceUrl'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      displayName: json['displayName'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

/// Manages multiple Pixelfed accounts stored in secure storage.
class AccountManager {
  static const _storageKey = 'multi_accounts';
  static const _activeKey = 'active_account_key';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Singleton instance
  static final AccountManager _instance = AccountManager._internal();
  factory AccountManager() => _instance;
  AccountManager._internal();

  /// Get all stored accounts.
  Future<List<AccountCredential>> getAccounts() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => AccountCredential.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new account (or update existing).
  Future<void> addAccount(AccountCredential account) async {
    final accounts = await getAccounts();
    // Remove existing with same key
    accounts.removeWhere((a) => a.uniqueKey == account.uniqueKey);
    accounts.add(account);
    await _saveAll(accounts);
  }

  /// Remove an account by instance URL and user ID.
  Future<void> removeAccount(String instanceUrl, String userId) async {
    final accounts = await getAccounts();
    final key = '$userId@$instanceUrl';
    accounts.removeWhere((a) => a.uniqueKey == key);
    await _saveAll(accounts);

    // If removed account was active, clear active
    final activeKey = await _storage.read(key: _activeKey);
    if (activeKey == key) {
      await _storage.delete(key: _activeKey);
    }
  }

  /// Set the active account.
  Future<void> setActiveAccount(String instanceUrl, String userId) async {
    final key = '$userId@$instanceUrl';
    await _storage.write(key: _activeKey, value: key);
  }

  /// Get the currently active account, or null.
  Future<AccountCredential?> getActiveAccount() async {
    final activeKey = await _storage.read(key: _activeKey);
    if (activeKey == null) return null;
    final accounts = await getAccounts();
    try {
      return accounts.firstWhere((a) => a.uniqueKey == activeKey);
    } catch (_) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  /// Get the count of stored accounts.
  Future<int> getAccountCount() async {
    final accounts = await getAccounts();
    return accounts.length;
  }

  Future<void> _saveAll(List<AccountCredential> accounts) async {
    final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }
}
