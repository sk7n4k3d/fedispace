import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fedispace/core/loops_api.dart';

class LoopsAuth {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'loops_access_token';
  static const _clientIdKey = 'loops_client_id';
  static const _clientSecretKey = 'loops_client_secret';
  static const _instanceUrl = 'https://loops.video';
  static const _redirectUri = 'space.echelon4.fedispace://loops-callback';
  static const _scopes = 'user:read user:write video:read video:create';

  static Future<String?> getStoredToken() async =>
      await _storage.read(key: _tokenKey);

  static Future<void> storeToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  static Future<bool> isAuthenticated() async =>
      await getStoredToken() != null;

  static Future<LoopsApi> getAuthenticatedClient() async {
    final token = await getStoredToken();
    return LoopsApi(instanceUrl: _instanceUrl, accessToken: token);
  }

  static Future<Map<String, String>> registerApp() async {
    var clientId = await _storage.read(key: _clientIdKey);
    var clientSecret = await _storage.read(key: _clientSecretKey);
    if (clientId != null && clientSecret != null) {
      return {'client_id': clientId, 'client_secret': clientSecret};
    }

    debugPrint('[LOOPS AUTH] registerApp: starting HTTP request to $_instanceUrl/api/v1/apps');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.userAgent = 'Mozilla/5.0 (Linux; Android) FediSpace/0.1.5';
    try {
      final request = await client.postUrl(Uri.parse('$_instanceUrl/api/v1/apps'));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(jsonEncode({
        'client_name': 'FediSpace',
        'redirect_uris': [_redirectUri],
        'scopes': _scopes,
      }));
      debugPrint('[LOOPS AUTH] registerApp: request sent, waiting for response...');
      final response = await request.close();
      debugPrint('[LOOPS AUTH] registerApp: got response status ${response.statusCode}');
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body) as Map<String, dynamic>;
      debugPrint('[LOOPS AUTH] registerApp: result=$result');
      clientId = result['client_id']?.toString() ?? '';
      clientSecret = result['client_secret']?.toString() ?? '';
      await _storage.write(key: _clientIdKey, value: clientId);
      await _storage.write(key: _clientSecretKey, value: clientSecret);
      return {'client_id': clientId!, 'client_secret': clientSecret!};
    } finally {
      client.close();
    }
  }

  static String getAuthorizationUrl(String clientId) {
    return '$_instanceUrl/oauth/authorize?'
        'client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
        '&response_type=code'
        '&scope=${Uri.encodeComponent(_scopes)}';
  }

  static String get redirectUri => _redirectUri;

  static Future<void> exchangeCode(String code) async {
    final creds = await registerApp();
    debugPrint('[LOOPS AUTH] registerApp: starting HTTP request to $_instanceUrl/api/v1/apps');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.userAgent = 'Mozilla/5.0 (Linux; Android) FediSpace/0.1.5';
    try {
      debugPrint('[LOOPS AUTH] exchangeCode: posting to $_instanceUrl/oauth/token');
      final request = await client.postUrl(Uri.parse('$_instanceUrl/oauth/token'));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(jsonEncode({
        'client_id': creds['client_id'],
        'client_secret': creds['client_secret'],
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
      }));
      debugPrint('[LOOPS AUTH] registerApp: request sent, waiting for response...');
      final response = await request.close();
      debugPrint('[LOOPS AUTH] registerApp: got response status ${response.statusCode}');
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body) as Map<String, dynamic>;
      final token = result['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await storeToken(token);
      }
    } finally {
      client.close();
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _clientIdKey);
    await _storage.delete(key: _clientSecretKey);
  }
}
