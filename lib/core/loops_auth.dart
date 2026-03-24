import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fedispace/core/loops_api.dart';

/// Handles OAuth2 authentication with Loops.video.
/// Stores tokens securely and provides authenticated API clients.
class LoopsAuth {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'loops_access_token';
  static const _clientIdKey = 'loops_client_id';
  static const _clientSecretKey = 'loops_client_secret';
  static const _instanceUrl = 'https://loops.video';
  static const _redirectUri = 'space.echelon4.fedispace://loops-callback';
  static const _scopes = 'read write';

  static Future<String?> getStoredToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<bool> isAuthenticated() async {
    return await getStoredToken() != null;
  }

  static Future<LoopsApi> getAuthenticatedClient() async {
    final token = await getStoredToken();
    return LoopsApi(
      instanceUrl: _instanceUrl,
      accessToken: token,
    );
  }

  static Future<LoopsApi> getPublicClient() async {
    return LoopsApi(instanceUrl: _instanceUrl);
  }

  /// Register the OAuth2 app with Loops (cached after first call).
  static Future<Map<String, String>> registerApp() async {
    var clientId = await _storage.read(key: _clientIdKey);
    var clientSecret = await _storage.read(key: _clientSecretKey);

    if (clientId != null && clientSecret != null) {
      return {'client_id': clientId, 'client_secret': clientSecret};
    }

    final api = LoopsApi(instanceUrl: _instanceUrl);
    try {
      final result = await api.registerApp(
        clientName: 'FediSpace',
        redirectUri: _redirectUri,
        scopes: _scopes,
      );

      clientId = result['client_id']?.toString() ?? '';
      clientSecret = result['client_secret']?.toString() ?? '';

      await _storage.write(key: _clientIdKey, value: clientId);
      await _storage.write(key: _clientSecretKey, value: clientSecret);

      return {'client_id': clientId!, 'client_secret': clientSecret!};
    } finally {
      api.dispose();
    }
  }

  /// Build the authorization URL for the browser.
  static String getAuthorizationUrl(String clientId) {
    return '$_instanceUrl/oauth/authorize?'
        'client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
        '&response_type=code'
        '&scope=${Uri.encodeComponent(_scopes)}';
  }

  static String get redirectUri => _redirectUri;

  /// Exchange the authorization code for an access token.
  static Future<void> exchangeCode(String code) async {
    final creds = await registerApp();
    final api = LoopsApi(instanceUrl: _instanceUrl);
    try {
      final result = await api.exchangeToken(
        code: code,
        clientId: creds['client_id']!,
        clientSecret: creds['client_secret']!,
        redirectUri: _redirectUri,
      );
      final token = result['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await storeToken(token);
      }
    } finally {
      api.dispose();
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _clientIdKey);
    await _storage.delete(key: _clientSecretKey);
  }
}
