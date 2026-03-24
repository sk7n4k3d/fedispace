import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fedispace/models/status.dart';

/// Local recommendation engine that learns user preferences from interactions.
/// Scores and ranks posts based on hashtag affinity and author preference.
class UserPreferences {
  static const String _storageKey = 'fedispace_user_preferences';
  static const double _decayFactor = 0.95;
  static const double _likeBoost = 1.0;
  static const double _bookmarkBoost = 2.0;
  static const double _viewBoostPerSecond = 0.05;
  static const double _viewMinSeconds = 3.0;
  static const int _maxTags = 200;
  static const int _maxAuthors = 100;

  Map<String, double> tagScores = {};
  Map<String, double> authorScores = {};
  DateTime lastUpdated = DateTime.now();

  UserPreferences();

  /// Record a like interaction -- moderate boost to tags and author.
  void recordLike(Status status) {
    _boostFromStatus(status, _likeBoost);
    lastUpdated = DateTime.now();
  }

  /// Record a bookmark interaction -- stronger boost.
  void recordBookmark(Status status) {
    _boostFromStatus(status, _bookmarkBoost);
    lastUpdated = DateTime.now();
  }

  /// Record a view with duration -- mild boost if viewed for more than 3 seconds.
  void recordView(Status status, Duration viewTime) {
    if (viewTime.inMilliseconds < (_viewMinSeconds * 1000)) return;
    final seconds = viewTime.inSeconds.clamp(0, 30);
    final boost = seconds * _viewBoostPerSecond;
    _boostFromStatus(status, boost);
    lastUpdated = DateTime.now();
  }

  /// Apply time decay to all scores (call periodically, e.g., on app launch).
  void decay() {
    tagScores.updateAll((key, value) => value * _decayFactor);
    authorScores.updateAll((key, value) => value * _decayFactor);
    // Prune near-zero entries
    tagScores.removeWhere((_, v) => v < 0.01);
    authorScores.removeWhere((_, v) => v < 0.01);
  }

  /// Score a post based on current user preferences.
  double scorePost(Status status) {
    double score = 0.0;

    // Author affinity
    final authorId = status.account.id;
    if (authorScores.containsKey(authorId)) {
      score += authorScores[authorId]!;
    }

    // Tag affinity
    final tags = _extractTags(status.content);
    if (tags.isNotEmpty && tagScores.isNotEmpty) {
      double tagScore = 0.0;
      for (final tag in tags) {
        if (tagScores.containsKey(tag)) {
          tagScore += tagScores[tag]!;
        }
      }
      score += tagScore / max(1, tags.length);
    }

    // Recency bonus
    try {
      final createdAt = DateTime.parse(status.created_at);
      final age = DateTime.now().difference(createdAt);
      if (age.inHours < 1) {
        score += 0.5;
      } else if (age.inHours < 6) {
        score += 0.2;
      }
    } catch (_) {}

    return score;
  }

  /// Rank a list of posts by preference score (descending).
  List<Status> rankPosts(List<Status> posts) {
    final scored = posts.map((p) => MapEntry(p, scorePost(p))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Persist preferences to SharedPreferences as JSON.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'tagScores': tagScores,
      'authorScores': authorScores,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Load preferences from SharedPreferences.
  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) return UserPreferences();

    try {
      final data = jsonDecode(stored) as Map<String, dynamic>;
      final userPrefs = UserPreferences();

      if (data['tagScores'] != null) {
        userPrefs.tagScores = (data['tagScores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
      if (data['authorScores'] != null) {
        userPrefs.authorScores = (data['authorScores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
      if (data['lastUpdated'] != null) {
        userPrefs.lastUpdated = DateTime.parse(data['lastUpdated']);
      }

      return userPrefs;
    } catch (_) {
      return UserPreferences();
    }
  }

  // --- Private helpers ---

  void _boostFromStatus(Status status, double boost) {
    // Boost author
    final authorId = status.account.id;
    authorScores[authorId] = (authorScores[authorId] ?? 0.0) + boost;

    // Boost tags extracted from content
    final tags = _extractTags(status.content);
    for (final tag in tags) {
      tagScores[tag] = (tagScores[tag] ?? 0.0) + boost;
    }

    // Cap collection sizes
    _trimMap(tagScores, _maxTags);
    _trimMap(authorScores, _maxAuthors);
  }

  List<String> _extractTags(String content) {
    final tagRegex = RegExp(r'#(\w+)');
    return tagRegex.allMatches(content).map((m) => m.group(1)!.toLowerCase()).toList();
  }

  void _trimMap(Map<String, double> map, int maxSize) {
    if (map.length <= maxSize) return;
    final entries = map.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final toRemove = entries.take(map.length - maxSize);
    for (final e in toRemove) {
      map.remove(e.key);
    }
  }
}
