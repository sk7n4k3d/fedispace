import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// Represents a saved post draft.
class PostDraft {
  final String id;
  final String caption;
  final List<String> mediaFilePaths;
  final Map<String, String> altTexts;
  final String visibility;
  final bool sensitive;
  final String? spoilerText;
  final String? locationName;
  final DateTime createdAt;

  const PostDraft({
    required this.id,
    required this.caption,
    required this.mediaFilePaths,
    this.altTexts = const {},
    this.visibility = 'public',
    this.sensitive = false,
    this.spoilerText,
    this.locationName,
    required this.createdAt,
  });

  /// Generate a simple unique ID (no uuid dependency needed).
  static String generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(99999);
    return '${now}_$rand';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caption': caption,
        'mediaFilePaths': mediaFilePaths,
        'altTexts': altTexts,
        'visibility': visibility,
        'sensitive': sensitive,
        'spoilerText': spoilerText,
        'locationName': locationName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      id: json['id'] as String,
      caption: json['caption'] as String? ?? '',
      mediaFilePaths: (json['mediaFilePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      altTexts: (json['altTexts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      visibility: json['visibility'] as String? ?? 'public',
      sensitive: json['sensitive'] as bool? ?? false,
      spoilerText: json['spoilerText'] as String?,
      locationName: json['locationName'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Manages post drafts stored as JSON in the app documents directory.
class DraftsManager {
  static const _fileName = 'post_drafts.json';

  /// Singleton instance
  static final DraftsManager _instance = DraftsManager._internal();
  factory DraftsManager() => _instance;
  DraftsManager._internal();

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Get all saved drafts, sorted newest first.
  Future<List<PostDraft>> getDrafts() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final drafts = decoded
          .map((e) => PostDraft.fromJson(e as Map<String, dynamic>))
          .toList();
      drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return drafts;
    } catch (_) {
      return [];
    }
  }

  /// Save a new draft or update existing.
  Future<void> saveDraft(PostDraft draft) async {
    final drafts = await getDrafts();
    drafts.removeWhere((d) => d.id == draft.id);
    drafts.insert(0, draft);
    await _saveAll(drafts);
  }

  /// Delete a draft by ID.
  Future<void> deleteDraft(String id) async {
    final drafts = await getDrafts();
    drafts.removeWhere((d) => d.id == id);
    await _saveAll(drafts);
  }

  /// Get draft count.
  Future<int> getDraftCount() async {
    final drafts = await getDrafts();
    return drafts.length;
  }

  Future<void> _saveAll(List<PostDraft> drafts) async {
    final file = await _getFile();
    final encoded = jsonEncode(drafts.map((d) => d.toJson()).toList());
    await file.writeAsString(encoded);
  }
}
