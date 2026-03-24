import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fedispace/models/status.dart';

/// Offline cache for timeline posts.
/// Caches the last 50 timeline posts as JSON and detects offline state.
class OfflineCache {
  static const String _cacheKey = 'offline_timeline_cache';
  static const String _cacheTimestampKey = 'offline_timeline_timestamp';
  static const int _maxCachedPosts = 50;

  bool _isOffline = false;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Whether the app is currently offline.
  bool get isOffline => _isOffline;

  /// Stream of connectivity changes.
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Update offline status.
  void setOffline(bool offline) {
    _isOffline = offline;
    _connectivityController.add(offline);
  }

  /// Cache timeline posts to SharedPreferences.
  Future<void> cacheTimeline(List<Status> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toCache = posts.take(_maxCachedPosts).toList();
      final jsonList = toCache.map((p) => p.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setString(
          _cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Silently fail -- cache is best-effort
    }
  }

  /// Get cached timeline posts.
  Future<List<Status>> getCachedTimeline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null) return [];

      final List<dynamic> data = jsonDecode(json);
      return data
          .map((item) => Status.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get the timestamp of the last cache update.
  Future<DateTime?> getCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getString(_cacheTimestampKey);
      if (ts == null) return null;
      return DateTime.parse(ts);
    } catch (_) {
      return null;
    }
  }

  /// Check if cache is stale (older than the given duration).
  Future<bool> isCacheStale(Duration maxAge) async {
    final ts = await getCacheTimestamp();
    if (ts == null) return true;
    return DateTime.now().difference(ts) > maxAge;
  }

  /// Clear the cache.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  /// Dispose resources.
  void dispose() {
    _connectivityController.close();
  }
}
