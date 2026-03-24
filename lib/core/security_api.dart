import 'dart:convert';
import 'package:fedispace/core/api.dart';

/// Separate security API service to avoid modifying api.dart.
/// Provides methods for account security features.
class SecurityApi {
  final ApiService apiService;

  SecurityApi({required this.apiService});

  String get _baseUrl => apiService.instanceUrl ?? '';

  Future<List<Map<String, dynamic>>> getLoginActivity() async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/security/sessions',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getTwoFactorStatus() async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/security/2fa',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'enabled': false, 'confirmed': false};
  }

  Future<List<Map<String, dynamic>>> getAuthorizedApps() async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/apps/verify_credentials',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return [data as Map<String, dynamic>];
      }
    } catch (_) {}
    return [];
  }

  Future<bool> revokeApp(String appId) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/security/apps/$appId/revoke',
        body: '{}',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/security/password',
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getEmailPreferences() async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/security/email_preferences',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'on_follow': true,
      'on_mention': true,
      'on_favourite': true,
      'on_reblog': true,
    };
  }

  Future<bool> updateEmailPreferences(Map<String, bool> preferences) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/security/email_preferences',
        body: jsonEncode(preferences),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
