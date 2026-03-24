import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a draft post queued for upload.
class PostDraft {
  final String text;
  final String visibility;
  final List<String> mediaFilePaths;
  final String? inReplyToId;
  final DateTime createdAt;
  final String id;

  PostDraft({
    required this.text,
    this.visibility = 'public',
    this.mediaFilePaths = const [],
    this.inReplyToId,
    DateTime? createdAt,
    String? id,
  })  : createdAt = createdAt ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'visibility': visibility,
        'mediaFilePaths': mediaFilePaths,
        'inReplyToId': inReplyToId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) => PostDraft(
        id: json['id'] as String?,
        text: json['text'] as String? ?? '',
        visibility: json['visibility'] as String? ?? 'public',
        mediaFilePaths: (json['mediaFilePaths'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        inReplyToId: json['inReplyToId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );
}

/// Queue for posts created while offline.
/// Persists drafts to SharedPreferences and processes them when connectivity restores.
class UploadQueue {
  static const String _queueKey = 'upload_queue';
  final List<PostDraft> _queue = [];
  final StreamController<int> _pendingController =
      StreamController<int>.broadcast();
  bool _isProcessing = false;

  /// Stream of pending queue size.
  Stream<int> get pendingCount => _pendingController.stream;

  /// Current queue size.
  int get length => _queue.length;

  /// Initialize by loading persisted queue.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_queueKey);
    if (json != null) {
      try {
        final List<dynamic> data = jsonDecode(json);
        _queue.addAll(
            data.map((e) => PostDraft.fromJson(e as Map<String, dynamic>)));
        _pendingController.add(_queue.length);
      } catch (_) {}
    }
  }

  /// Add a draft to the queue.
  Future<void> enqueue(PostDraft draft) async {
    _queue.add(draft);
    await _persist();
    _pendingController.add(_queue.length);
  }

  /// Remove a draft from the queue.
  Future<void> remove(String draftId) async {
    _queue.removeWhere((d) => d.id == draftId);
    await _persist();
    _pendingController.add(_queue.length);
  }

  /// Get all queued drafts.
  List<PostDraft> getAll() => List.unmodifiable(_queue);

  /// Process the queue -- call this when connectivity is restored.
  /// [postFn] is the actual function to post (e.g., apiService.postStatus).
  Future<void> processQueue(
      Future<bool> Function(PostDraft draft) postFn) async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final toProcess = List<PostDraft>.from(_queue);
    for (final draft in toProcess) {
      try {
        final success = await postFn(draft);
        if (success) {
          _queue.remove(draft);
          await _persist();
          _pendingController.add(_queue.length);
        }
      } catch (_) {
        // Stop processing on first failure (likely still offline)
        break;
      }
    }

    _isProcessing = false;
  }

  /// Persist the queue to SharedPreferences.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _queue.map((d) => d.toJson()).toList();
    await prefs.setString(_queueKey, jsonEncode(jsonList));
  }

  /// Clear the entire queue.
  Future<void> clear() async {
    _queue.clear();
    await _persist();
    _pendingController.add(0);
  }

  /// Dispose resources.
  void dispose() {
    _pendingController.close();
  }
}
