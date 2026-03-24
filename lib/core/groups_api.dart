import 'dart:convert';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/status.dart';

/// Separate API file for group endpoints.
/// Groups MVP for Pixelfed/Mastodon instances that support the groups feature.
class GroupsApi {
  final ApiService apiService;

  GroupsApi({required this.apiService});

  String get _baseUrl => apiService.instanceUrl ?? '';

  /// List popular/featured groups.
  Future<List<Map<String, dynamic>>> listGroups({
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var url = '$_baseUrl/api/v1/groups?limit=$limit&offset=$offset';
      if (query != null && query.isNotEmpty) {
        url += '&q=${Uri.encodeComponent(query)}';
      }
      final response = await apiService.helper!.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// List groups the current user has joined.
  Future<List<Map<String, dynamic>>> listJoinedGroups() async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/groups/joined',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Get a specific group by ID.
  Future<Map<String, dynamic>?> getGroup(String groupId) async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/groups/$groupId',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Join a group.
  Future<bool> joinGroup(String groupId) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/groups/$groupId/join',
        body: '{}',
      );
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Leave a group.
  Future<bool> leaveGroup(String groupId) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/groups/$groupId/leave',
        body: '{}',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get group feed (timeline of posts in the group).
  Future<List<Status>> getGroupFeed(String groupId,
      {int limit = 20, String? maxId}) async {
    try {
      var url = '$_baseUrl/api/v1/groups/$groupId/statuses?limit=$limit';
      if (maxId != null) url += '&max_id=$maxId';
      final response = await apiService.helper!.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Status.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Post to a group.
  Future<bool> postToGroup(String groupId, String content,
      {String visibility = 'public'}) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/groups/$groupId/statuses',
        body: jsonEncode({
          'status': content,
          'visibility': visibility,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Get group members.
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId,
      {int limit = 40}) async {
    try {
      final response = await apiService.helper!.get(
        '$_baseUrl/api/v1/groups/$groupId/members?limit=$limit',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Create a new group.
  Future<Map<String, dynamic>?> createGroup({
    required String name,
    String? description,
    String? category,
    String privacy = 'public',
  }) async {
    try {
      final response = await apiService.helper!.post(
        '$_baseUrl/api/v1/groups',
        body: jsonEncode({
          'name': name,
          'description': description ?? '',
          'category': category ?? '',
          'privacy': privacy,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
