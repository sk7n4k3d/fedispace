// Loops API Client for FediSpace
// Complete client based on loops-server source code analysis
// https://github.com/joinloops/loops-server

import 'dart:convert';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Compact account representation used in video/comment responses.
class LoopsAccountCompact {
  final String id;
  final String username;
  final String? name;
  final String? avatar;

  LoopsAccountCompact({
    required this.id,
    required this.username,
    this.name,
    this.avatar,
  });

  factory LoopsAccountCompact.fromJson(Map<String, dynamic> json) {
    return LoopsAccountCompact(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'avatar': avatar,
      };
}

/// Full profile representation (from ProfileResource).
class LoopsProfile {
  final String id;
  final String username;
  final String? name;
  final String? avatar;
  final bool isOwner;
  final bool local;
  final String bio;
  final int postCount;
  final int followerCount;
  final int followingCount;
  final String url;
  final String? remoteUrl;
  final bool? isBlocking;
  final bool? isFollowing;
  final bool? isAdmin;
  final int? likesCount;
  final List<dynamic> links;
  final DateTime createdAt;

  LoopsProfile({
    required this.id,
    required this.username,
    this.name,
    this.avatar,
    this.isOwner = false,
    this.local = true,
    this.bio = '',
    this.postCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.url = '',
    this.remoteUrl,
    this.isBlocking,
    this.isFollowing,
    this.isAdmin,
    this.likesCount,
    this.links = const [],
    required this.createdAt,
  });

  factory LoopsProfile.fromJson(Map<String, dynamic> json) {
    return LoopsProfile(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
      isOwner: json['is_owner'] == true,
      local: json['local'] == true,
      bio: json['bio']?.toString() ?? '',
      postCount: json['post_count'] as int? ?? 0,
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      url: json['url']?.toString() ?? '',
      remoteUrl: json['remote_url']?.toString(),
      isBlocking: json['is_blocking'] as bool?,
      isFollowing: json['is_following'] as bool?,
      isAdmin: json['is_admin'] as bool?,
      likesCount: json['likes_count'] as int?,
      links: json['links'] as List<dynamic>? ?? [],
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'avatar': avatar,
        'is_owner': isOwner,
        'local': local,
        'bio': bio,
        'post_count': postCount,
        'follower_count': followerCount,
        'following_count': followingCount,
        'url': url,
        'remote_url': remoteUrl,
        'is_blocking': isBlocking,
        'is_following': isFollowing,
        'is_admin': isAdmin,
        'likes_count': likesCount,
        'links': links,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Video media details.
class LoopsVideoMedia {
  final String? thumbnail;
  final String? srcUrl;
  final String? hlsUrl;
  final String? altText;
  final int? duration;

  LoopsVideoMedia({
    this.thumbnail,
    this.srcUrl,
    this.hlsUrl,
    this.altText,
    this.duration,
  });

  factory LoopsVideoMedia.fromJson(Map<String, dynamic> json) {
    return LoopsVideoMedia(
      thumbnail: json['thumbnail']?.toString(),
      srcUrl: json['src_url']?.toString(),
      hlsUrl: json['hls_url']?.toString() ?? json['hls']?.toString(),
      altText: json['alt_text']?.toString(),
      duration: json['duration'] as int?,
    );
  }
}

/// Video permissions.
class LoopsVideoPermissions {
  final bool canComment;
  final bool canDownload;
  final bool canDuet;
  final bool canStitch;

  LoopsVideoPermissions({
    this.canComment = true,
    this.canDownload = false,
    this.canDuet = false,
    this.canStitch = false,
  });

  factory LoopsVideoPermissions.fromJson(Map<String, dynamic> json) {
    return LoopsVideoPermissions(
      canComment: json['can_comment'] == true,
      canDownload: json['can_download'] == true,
      canDuet: json['can_duet'] == true,
      canStitch: json['can_stitch'] == true,
    );
  }
}

/// Video audio info.
class LoopsVideoAudio {
  final bool hasAudio;
  final String? id;
  final int count;
  final String? key;
  final String? soundId;

  LoopsVideoAudio({
    this.hasAudio = false,
    this.id,
    this.count = 0,
    this.key,
    this.soundId,
  });

  factory LoopsVideoAudio.fromJson(Map<String, dynamic> json) {
    return LoopsVideoAudio(
      hasAudio: json['has_audio'] == true,
      id: json['id']?.toString(),
      count: json['count'] as int? ?? 0,
      key: json['key']?.toString(),
      soundId: json['sound_id']?.toString(),
    );
  }
}

/// Video metadata flags.
class LoopsVideoMeta {
  final bool containsAi;
  final bool containsAd;

  LoopsVideoMeta({this.containsAi = false, this.containsAd = false});

  factory LoopsVideoMeta.fromJson(Map<String, dynamic> json) {
    return LoopsVideoMeta(
      containsAi: json['contains_ai'] == true,
      containsAd: json['contains_ad'] == true,
    );
  }
}

/// Full video representation (from VideoResource).
class LoopsVideo {
  final String id;
  final LoopsAccountCompact account;
  final String? caption;
  final String url;
  final bool isOwner;
  final bool isSensitive;
  final LoopsVideoMedia media;
  final bool pinned;
  final int likes;
  final int shares;
  final int comments;
  final int bookmarks;
  final bool hasLiked;
  final bool hasBookmarked;
  final bool isEdited;
  final String? lang;
  final List<String> tags;
  final List<dynamic> mentions;
  final LoopsVideoPermissions permissions;
  final LoopsVideoAudio audio;
  final LoopsVideoMeta meta;
  final DateTime createdAt;

  LoopsVideo({
    required this.id,
    required this.account,
    this.caption,
    required this.url,
    this.isOwner = false,
    this.isSensitive = false,
    required this.media,
    this.pinned = false,
    this.likes = 0,
    this.shares = 0,
    this.comments = 0,
    this.bookmarks = 0,
    this.hasLiked = false,
    this.hasBookmarked = false,
    this.isEdited = false,
    this.lang,
    this.tags = const [],
    this.mentions = const [],
    required this.permissions,
    required this.audio,
    required this.meta,
    required this.createdAt,
  });

  factory LoopsVideo.fromJson(Map<String, dynamic> json) {
    return LoopsVideo(
      id: json['id']?.toString() ?? '',
      account: LoopsAccountCompact.fromJson(
          json['account'] as Map<String, dynamic>? ?? {}),
      caption: json['caption']?.toString(),
      url: json['url']?.toString() ?? '',
      isOwner: json['is_owner'] == true,
      isSensitive: json['is_sensitive'] == true,
      media: LoopsVideoMedia.fromJson(
          json['media'] as Map<String, dynamic>? ?? {}),
      pinned: json['pinned'] == true,
      likes: json['likes'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      bookmarks: json['bookmarks'] as int? ?? 0,
      hasLiked: json['has_liked'] == true,
      hasBookmarked: json['has_bookmarked'] == true,
      isEdited: json['is_edited'] == true,
      lang: json['lang']?.toString(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      mentions: json['mentions'] as List<dynamic>? ?? [],
      permissions: LoopsVideoPermissions.fromJson(
          json['permissions'] as Map<String, dynamic>? ?? {}),
      audio: LoopsVideoAudio.fromJson(
          json['audio'] as Map<String, dynamic>? ?? {}),
      meta:
          LoopsVideoMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Comment representation (from CommentResource).
class LoopsComment {
  final String id;
  final String videoId;
  final LoopsAccountCompact account;
  final String? caption;
  final int replies;
  final List<dynamic> children;
  final List<String> tags;
  final List<dynamic> mentions;
  final int likes;
  final int shares;
  final bool liked;
  final String? url;
  final String? remoteUrl;
  final bool tombstone;
  final bool isEdited;
  final bool isHidden;
  final bool isOwner;
  final DateTime createdAt;

  LoopsComment({
    required this.id,
    required this.videoId,
    required this.account,
    this.caption,
    this.replies = 0,
    this.children = const [],
    this.tags = const [],
    this.mentions = const [],
    this.likes = 0,
    this.shares = 0,
    this.liked = false,
    this.url,
    this.remoteUrl,
    this.tombstone = false,
    this.isEdited = false,
    this.isHidden = false,
    this.isOwner = false,
    required this.createdAt,
  });

  factory LoopsComment.fromJson(Map<String, dynamic> json) {
    return LoopsComment(
      id: json['id']?.toString() ?? '',
      videoId: json['v_id']?.toString() ?? '',
      account: LoopsAccountCompact.fromJson(
          json['account'] as Map<String, dynamic>? ?? {}),
      caption: json['caption']?.toString(),
      replies: json['replies'] as int? ?? 0,
      children: json['children'] as List<dynamic>? ?? [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      mentions: json['mentions'] as List<dynamic>? ?? [],
      likes: json['likes'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      liked: json['liked'] == true,
      url: json['url']?.toString(),
      remoteUrl: json['remote_url']?.toString(),
      tombstone: json['tombstone'] == true,
      isEdited: json['is_edited'] == true,
      isHidden: json['is_hidden'] == true,
      isOwner: json['is_owner'] == true,
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Comment reply representation (from CommentReplyResource).
class LoopsCommentReply {
  final String id;
  final String videoId;
  final String parentId;
  final LoopsAccountCompact account;
  final String? caption;
  final int likes;
  final int shares;
  final List<String> tags;
  final List<dynamic> mentions;
  final bool liked;
  final String? url;
  final String? remoteUrl;
  final bool tombstone;
  final bool isEdited;
  final bool isHidden;
  final bool isOwner;
  final DateTime createdAt;

  LoopsCommentReply({
    required this.id,
    required this.videoId,
    required this.parentId,
    required this.account,
    this.caption,
    this.likes = 0,
    this.shares = 0,
    this.tags = const [],
    this.mentions = const [],
    this.liked = false,
    this.url,
    this.remoteUrl,
    this.tombstone = false,
    this.isEdited = false,
    this.isHidden = false,
    this.isOwner = false,
    required this.createdAt,
  });

  factory LoopsCommentReply.fromJson(Map<String, dynamic> json) {
    return LoopsCommentReply(
      id: json['id']?.toString() ?? '',
      videoId: json['v_id']?.toString() ?? '',
      parentId: json['p_id']?.toString() ?? '',
      account: LoopsAccountCompact.fromJson(
          json['account'] as Map<String, dynamic>? ?? {}),
      caption: json['caption']?.toString(),
      likes: json['likes'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      mentions: json['mentions'] as List<dynamic>? ?? [],
      liked: json['liked'] == true,
      url: json['url']?.toString(),
      remoteUrl: json['remote_url']?.toString(),
      tombstone: json['tombstone'] == true,
      isEdited: json['is_edited'] == true,
      isHidden: json['is_hidden'] == true,
      isOwner: json['is_owner'] == true,
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Hashtag representation (from HashtagResource).
class LoopsHashtag {
  final int id;
  final String name;
  final String? slug;
  final int count;
  final DateTime? createdAt;

  LoopsHashtag({
    required this.id,
    required this.name,
    this.slug,
    this.count = 0,
    this.createdAt,
  });

  factory LoopsHashtag.fromJson(Map<String, dynamic> json) {
    return LoopsHashtag(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      count: json['count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

/// Sound details (from VideoSoundResource).
class LoopsSound {
  final String id;
  final String? url;
  final String? key;
  final Map<String, dynamic>? originalVideo;
  final int? usageCount;
  final bool? allowReuse;
  final int? duration;

  LoopsSound({
    required this.id,
    this.url,
    this.key,
    this.originalVideo,
    this.usageCount,
    this.allowReuse,
    this.duration,
  });

  factory LoopsSound.fromJson(Map<String, dynamic> json) {
    return LoopsSound(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString(),
      key: json['key']?.toString(),
      originalVideo: json['original_video'] is Map
          ? json['original_video'] as Map<String, dynamic>
          : null,
      usageCount: json['usage_count'] as int?,
      allowReuse: json['allow_reuse'] as bool?,
      duration: json['duration'] as int?,
    );
  }
}

/// Notification (from NotificationResource).
class LoopsNotification {
  final String id;
  final String type;
  final Map<String, dynamic>? actor;
  final String? videoId;
  final String? videoThumbnail;
  final String? url;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> raw;

  LoopsNotification({
    required this.id,
    required this.type,
    this.actor,
    this.videoId,
    this.videoThumbnail,
    this.url,
    this.readAt,
    required this.createdAt,
    required this.raw,
  });

  factory LoopsNotification.fromJson(Map<String, dynamic> json) {
    return LoopsNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'unknown',
      actor: json['actor'] as Map<String, dynamic>?,
      videoId: json['video_id']?.toString(),
      videoThumbnail: json['video_thumbnail']?.toString(),
      url: json['url']?.toString(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      raw: json,
    );
  }
}

/// Playlist (from PlaylistResource).
class LoopsPlaylist {
  final int id;
  final int profileId;
  final String name;
  final String? description;
  final String visibility;
  final String? coverImage;
  final int videosCount;
  final LoopsAccountCompact? profile;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoopsPlaylist({
    required this.id,
    required this.profileId,
    required this.name,
    this.description,
    this.visibility = 'public',
    this.coverImage,
    this.videosCount = 0,
    this.profile,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoopsPlaylist.fromJson(Map<String, dynamic> json) {
    return LoopsPlaylist(
      id: json['id'] as int? ?? 0,
      profileId: json['profile_id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      visibility: json['visibility']?.toString() ?? 'public',
      coverImage: json['cover_image']?.toString(),
      videosCount: json['videos_count'] as int? ?? 0,
      profile: json['profile'] != null
          ? LoopsAccountCompact.fromJson(
              json['profile'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Search results (from SearchResultResource).
class LoopsSearchResults {
  final List<LoopsHashtag> hashtags;
  final List<LoopsProfile> users;
  final List<LoopsVideo> videos;
  final Map<String, dynamic> pager;

  LoopsSearchResults({
    this.hashtags = const [],
    this.users = const [],
    this.videos = const [],
    this.pager = const {},
  });

  factory LoopsSearchResults.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return LoopsSearchResults(
      hashtags: (data['hashtags'] as List<dynamic>?)
              ?.map((e) => LoopsHashtag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      users: (data['users'] as List<dynamic>?)
              ?.map((e) => LoopsProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos: (data['videos'] as List<dynamic>?)
              ?.map((e) => LoopsVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pager: json['pager'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Paginated response wrapper.
class LoopsPaginatedResponse<T> {
  final List<T> data;
  final String? nextCursor;
  final String? prevCursor;
  final bool hasMore;
  final Map<String, dynamic>? meta;

  LoopsPaginatedResponse({
    required this.data,
    this.nextCursor,
    this.prevCursor,
    this.hasMore = false,
    this.meta,
  });
}

/// OAuth app registration response.
class LoopsOAuthApp {
  final String clientId;
  final String clientName;
  final String? clientSecret;
  final List<String> redirectUris;

  LoopsOAuthApp({
    required this.clientId,
    required this.clientName,
    this.clientSecret,
    this.redirectUris = const [],
  });

  factory LoopsOAuthApp.fromJson(Map<String, dynamic> json) {
    return LoopsOAuthApp(
      clientId: json['client_id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      clientSecret: json['client_secret']?.toString(),
      redirectUris: (json['redirect_uris'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class LoopsApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;

  LoopsApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'LoopsApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// API Client
// ---------------------------------------------------------------------------

/// Complete Loops API client based on loops-server source code.
///
/// Covers every public and authenticated endpoint from routes/api.php:
///   - OAuth app registration (POST /api/v1/apps)
///   - Feeds: for-you, local, following, account, recommended
///   - Videos: CRUD, like/unlike, bookmark/unbookmark, likes list, shares list
///   - Comments: CRUD, like/unlike, replies, hide/unhide, edit history
///   - Accounts: self, profile, follow/unfollow, block/unblock,
///     followers/following/friends, suggestions, relationship state
///   - Notifications: list, count, mark read
///   - Search: unified, users
///   - Explore: trending tags, tag feed, video tags
///   - Studio: posts, playlist management, upload, duet upload
///   - Sounds: details, feed
///   - Settings: bio, avatar, password, 2FA, privacy, blocked accounts,
///     email, birthdate, push notifications, starter kits, account disable/delete
///   - User preferences
///   - Reports
///   - Starter kits (full CRUD + browse)
///   - Account data exports
///   - App configuration, i18n, pages, contact info
class LoopsApi {
  /// Base URL of the Loops instance (e.g., https://loops.video).
  final String instanceUrl;

  /// OAuth2 Bearer token, set after authentication.
  String? accessToken;

  /// HTTP client (injectable for testing).
  final http.Client httpClient;

  LoopsApi({
    required this.instanceUrl,
    this.accessToken,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  // -------------------------------------------------------------------------
  // HTTP helpers
  // -------------------------------------------------------------------------

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = instanceUrl.endsWith('/')
        ? instanceUrl.substring(0, instanceUrl.length - 1)
        : instanceUrl;
    final uri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Map<String, String> get _jsonHeaders => {
        ..._headers,
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    throw LoopsApiException(
      response.statusCode,
      body?['message']?.toString() ??
          body?['error']?.toString() ??
          'Request failed',
      body: body,
    );
  }

  Future<List<dynamic>> _handleListResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'] as List<dynamic>;
      }
      return [decoded];
    }
    throw LoopsApiException(response.statusCode, 'Request failed');
  }

  Future<http.Response> _get(String path,
      [Map<String, String>? queryParams]) async {
    return httpClient.get(_uri(path, queryParams), headers: _headers);
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    return httpClient.post(
      _uri(path),
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> _put(String path, {Map<String, dynamic>? body}) async {
    return httpClient.put(
      _uri(path),
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> _delete(String path,
      {Map<String, dynamic>? body}) async {
    return httpClient.delete(
      _uri(path),
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Parse a standard paginated response with cursor.
  LoopsPaginatedResponse<T> _parsePaginated<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>?;
    final links = json['links'] as Map<String, dynamic>?;

    return LoopsPaginatedResponse<T>(
      data: dataList.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      nextCursor: meta?['next_cursor']?.toString(),
      prevCursor: meta?['prev_cursor']?.toString(),
      hasMore: meta?['next_cursor'] != null ||
          (links?['next'] != null && links!['next'] != ''),
      meta: meta,
    );
  }

  // =========================================================================
  // 1. AUTH / OAUTH
  // =========================================================================

  /// POST /api/v1/apps -- Register an OAuth application.
  /// Returns client_id, client_secret, redirect_uris.
  Future<LoopsOAuthApp> registerApp({
    required String clientName,
    required List<String> redirectUris,
  }) async {
    final resp = await _post('/api/v1/apps', body: {
      'client_name': clientName,
      'redirect_uris': redirectUris,
    });
    final json = await _handleResponse(resp);
    return LoopsOAuthApp.fromJson(json);
  }

  /// Build the OAuth2 authorization URL for the user to visit.
  /// Uses Passport's standard /oauth/authorize endpoint.
  String getAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    String responseType = 'code',
    String scope = '',
  }) {
    return _uri('/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': responseType,
      if (scope.isNotEmpty) 'scope': scope,
    }).toString();
  }

  /// POST /oauth/token -- Exchange authorization code for access token.
  Future<Map<String, dynamic>> exchangeToken({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    String grantType = 'authorization_code',
  }) async {
    final resp = await _post('/oauth/token', body: {
      'grant_type': grantType,
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
    });
    return _handleResponse(resp);
  }

  /// POST /oauth/token -- Refresh an access token.
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    required String clientId,
    required String clientSecret,
  }) async {
    final resp = await _post('/oauth/token', body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
      'client_secret': clientSecret,
    });
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/2fa/verify
  Future<Map<String, dynamic>> verifyTwoFactor(String otpCode) async {
    final resp =
        await _post('/api/v1/auth/2fa/verify', body: {'otp_code': otpCode});
    return _handleResponse(resp);
  }

  // =========================================================================
  // 2. APP CONFIGURATION
  // =========================================================================

  /// GET /api/v1/config -- App configuration (software version, features).
  Future<Map<String, dynamic>> getAppConfiguration() async {
    final resp = await _get('/api/v1/config');
    return _handleResponse(resp);
  }

  /// GET /api/v1/i18n/list -- Available languages.
  Future<Map<String, dynamic>> getLanguagesList() async {
    final resp = await _get('/api/v1/i18n/list');
    return _handleResponse(resp);
  }

  /// GET /api/v1/platform/contact -- Contact info.
  Future<Map<String, dynamic>> getContactInfo() async {
    final resp = await _get('/api/v1/platform/contact');
    return _handleResponse(resp);
  }

  /// GET /api/v1/page/content -- Static page content.
  Future<Map<String, dynamic>> getPageContent(String slug) async {
    final resp = await _get('/api/v1/page/content', {'slug': slug});
    return _handleResponse(resp);
  }

  /// GET /api/v1/web/report-rules -- Report types/rules.
  Future<Map<String, dynamic>> getReportRules() async {
    final resp = await _get('/api/v1/web/report-rules');
    return _handleResponse(resp);
  }

  // =========================================================================
  // 3. FEEDS
  // =========================================================================

  /// GET /api/v1/feed/for-you -- For You feed (auth required).
  Future<LoopsPaginatedResponse<LoopsVideo>> getForYouFeed({
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/feed/for-you', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v1/feed/local -- Local feed (same handler as for-you, auth required).
  Future<LoopsPaginatedResponse<LoopsVideo>> getLocalFeed({
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/feed/local', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v1/feed/following -- Following feed (auth required).
  Future<LoopsPaginatedResponse<LoopsVideo>> getFollowingFeed({
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/feed/following', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/web/feed -- Public feed (no auth, cached 45min).
  Future<LoopsPaginatedResponse<LoopsVideo>> getPublicFeed() async {
    final resp = await _get('/api/web/feed');
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v1/feed/account/self -- Own account feed (auth required).
  /// [sort]: Latest, Popular, Oldest. [limit]: 1-20.
  Future<LoopsPaginatedResponse<LoopsVideo>> getSelfAccountFeed({
    String sort = 'Latest',
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
    };
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/feed/account/self', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v1/feed/account/{id} -- Any account's public feed.
  /// [sort]: Latest, Popular, Oldest.
  Future<LoopsPaginatedResponse<LoopsVideo>> getAccountFeed(
    String profileId, {
    String sort = 'Latest',
    String? cursor,
  }) async {
    final params = <String, String>{'sort': sort};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/feed/account/$profileId', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v1/feed/account/{id}/cursor -- Account feed with cursor.
  /// Requires [videoId] as starting point.
  Future<LoopsPaginatedResponse<LoopsVideo>> getAccountFeedWithCursor(
    String profileId, {
    required int videoId,
    int limit = 10,
  }) async {
    final params = <String, String>{
      'id': videoId.toString(),
      'limit': limit.toString(),
    };
    final resp = await _get('/api/v1/feed/account/$profileId/cursor', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v0/feed/recommended -- Recommended / For You v2 feed (auth required).
  Future<Map<String, dynamic>> getRecommendedFeed({
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v0/feed/recommended', params);
    return _handleResponse(resp);
  }

  /// POST /api/v0/feed/recommended/impression -- Record video impression.
  Future<void> recordFeedImpression({
    required int videoId,
    required int watchDuration,
    bool completed = false,
  }) async {
    final resp = await _post('/api/v0/feed/recommended/impression', body: {
      'video_id': videoId,
      'watch_duration': watchDuration,
      'completed': completed,
    });
    await _handleResponse(resp);
  }

  /// POST /api/v0/feed/recommended/feedback -- Record feed feedback.
  /// [feedbackType]: like, dislike, not_interested, hide_creator.
  Future<void> recordFeedFeedback({
    required int videoId,
    required String feedbackType,
  }) async {
    final resp = await _post('/api/v0/feed/recommended/feedback', body: {
      'video_id': videoId,
      'feedback_type': feedbackType,
    });
    await _handleResponse(resp);
  }

  /// DELETE /api/v0/feed/recommended/feedback/{videoId} -- Remove feedback.
  Future<void> removeFeedFeedback(int videoId) async {
    final resp = await _delete('/api/v0/feed/recommended/feedback/$videoId');
    await _handleResponse(resp);
  }

  // =========================================================================
  // 4. VIDEOS
  // =========================================================================

  /// GET /api/v1/video/{id} -- Get a single video (public, throttled).
  Future<LoopsVideo> getVideo(String id) async {
    final resp = await _get('/api/v1/video/$id');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsVideo.fromJson(data);
  }

  /// POST /api/v1/studio/upload -- Upload a new video (auth required).
  /// Returns success/error. Video is processed asynchronously.
  Future<Map<String, dynamic>> uploadVideo({
    required String filePath,
    String? description,
    bool isSensitive = false,
    bool canComment = true,
    bool canDownload = false,
    bool canDuet = false,
    bool canStitch = false,
    String? altText,
    bool containsAi = false,
    bool containsAd = false,
    String? lang,
  }) async {
    final request =
        http.MultipartRequest('POST', _uri('/api/v1/studio/upload'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('video', filePath));
    if (description != null) request.fields['description'] = description;
    request.fields['is_sensitive'] = isSensitive ? '1' : '0';
    request.fields['comment_state'] = canComment ? '4' : '0';
    request.fields['can_download'] = canDownload ? '1' : '0';
    request.fields['can_duet'] = canDuet ? '1' : '0';
    request.fields['can_stitch'] = canStitch ? '1' : '0';
    if (altText != null) request.fields['alt_text'] = altText;
    request.fields['contains_ai'] = containsAi ? '1' : '0';
    request.fields['contains_ad'] = containsAd ? '1' : '0';
    if (lang != null) request.fields['lang'] = lang;

    final streamedResp = await httpClient.send(request);
    final resp = await http.Response.fromStream(streamedResp);
    return _handleResponse(resp);
  }

  /// POST /api/v1/studio/duet/upload -- Upload a duet video.
  Future<Map<String, dynamic>> uploadDuet({
    required String filePath,
    required int duetId,
    String duetLayout = 'side-by-side',
    String? description,
    bool isSensitive = false,
    bool canComment = true,
    bool canDownload = false,
    bool canDuet = false,
    bool canStitch = false,
    String? altText,
    bool containsAi = false,
    bool containsAd = false,
    String? lang,
  }) async {
    final request =
        http.MultipartRequest('POST', _uri('/api/v1/studio/duet/upload'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('video', filePath));
    request.fields['duet_id'] = duetId.toString();
    request.fields['duet_layout'] = duetLayout;
    if (description != null) request.fields['description'] = description;
    request.fields['is_sensitive'] = isSensitive ? '1' : '0';
    request.fields['comment_state'] = canComment ? '4' : '0';
    request.fields['can_download'] = canDownload ? '1' : '0';
    request.fields['can_duet'] = canDuet ? '1' : '0';
    request.fields['can_stitch'] = canStitch ? '1' : '0';
    if (altText != null) request.fields['alt_text'] = altText;
    request.fields['contains_ai'] = containsAi ? '1' : '0';
    request.fields['contains_ad'] = containsAd ? '1' : '0';
    if (lang != null) request.fields['lang'] = lang;

    final streamedResp = await httpClient.send(request);
    final resp = await http.Response.fromStream(streamedResp);
    return _handleResponse(resp);
  }

  /// POST /api/v1/video/edit/{id} -- Update video metadata (auth required).
  Future<LoopsVideo> updateVideo(
    String id, {
    String? caption,
    bool? canDownload,
    bool? canComment,
    bool? isPinned,
    String? altText,
    bool? canDuet,
    bool? canStitch,
    String? lang,
    bool? isSensitive,
    bool? containsAd,
    bool? containsAi,
  }) async {
    final body = <String, dynamic>{};
    if (caption != null) body['caption'] = caption;
    if (canDownload != null) body['can_download'] = canDownload;
    if (canComment != null) body['can_comment'] = canComment;
    if (isPinned != null) body['is_pinned'] = isPinned;
    if (altText != null) body['alt_text'] = altText;
    if (canDuet != null) body['can_duet'] = canDuet;
    if (canStitch != null) body['can_stitch'] = canStitch;
    if (lang != null) body['lang'] = lang;
    if (isSensitive != null) body['is_sensitive'] = isSensitive;
    if (containsAd != null) body['contains_ad'] = containsAd;
    if (containsAi != null) body['contains_ai'] = containsAi;
    final resp = await _post('/api/v1/video/edit/$id', body: body);
    final json = await _handleResponse(resp);
    return LoopsVideo.fromJson(json);
  }

  /// POST /api/v1/video/delete/{id} -- Delete a video (auth required).
  Future<void> deleteVideo(String id) async {
    final resp = await _post('/api/v1/video/delete/$id');
    await _handleResponse(resp);
  }

  /// POST /api/v1/video/like/{id} -- Like a video. Returns updated VideoResource.
  Future<LoopsVideo> likeVideo(String id) async {
    final resp = await _post('/api/v1/video/like/$id');
    final json = await _handleResponse(resp);
    return LoopsVideo.fromJson(json);
  }

  /// POST /api/v1/video/unlike/{id} -- Unlike a video. Returns updated VideoResource.
  Future<LoopsVideo> unlikeVideo(String id) async {
    final resp = await _post('/api/v1/video/unlike/$id');
    final json = await _handleResponse(resp);
    return LoopsVideo.fromJson(json);
  }

  /// POST /api/v1/video/bookmark/{id} -- Bookmark a video (auth required).
  Future<LoopsVideo> bookmarkVideo(String id) async {
    final resp = await _post('/api/v1/video/bookmark/$id');
    final json = await _handleResponse(resp);
    return LoopsVideo.fromJson(json);
  }

  /// POST /api/v1/video/unbookmark/{id} -- Unbookmark a video (auth required).
  Future<LoopsVideo> unbookmarkVideo(String id) async {
    final resp = await _post('/api/v1/video/unbookmark/$id');
    final json = await _handleResponse(resp);
    return LoopsVideo.fromJson(json);
  }

  /// GET /api/v1/video/likes/{id} -- Video likes list (auth required).
  Future<List<Map<String, dynamic>>> getVideoLikes(String id) async {
    final resp = await _get('/api/v1/video/likes/$id');
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/video/shares/{id} -- Video shares/reposts list (auth required).
  Future<List<Map<String, dynamic>>> getVideoShares(String id) async {
    final resp = await _get('/api/v1/video/shares/$id');
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/video/history/{id} -- Video caption edit history.
  Future<List<Map<String, dynamic>>> getVideoHistory(String id,
      {String? cursor}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/video/history/$id', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/account/favourites -- User's bookmarked videos (auth required).
  /// [sort]: latest, oldest, popular. [limit]: 1-20.
  Future<LoopsPaginatedResponse<LoopsVideo>> getBookmarks({
    String sort = 'latest',
    int limit = 12,
    String? cursor,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
    };
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/account/favourites', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Bookmarks error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  // =========================================================================
  // 5. COMMENTS
  // =========================================================================

  /// GET /api/v1/video/comments/{videoId} -- Get comments (public, cursor-paginated).
  Future<LoopsPaginatedResponse<LoopsComment>> getComments(
    String videoId, {
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/video/comments/$videoId', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Comments error');
    return _parsePaginated(resp, LoopsComment.fromJson);
  }

  /// GET /api/v1/video/comments/{videoId}/comment/{commentId} -- Single comment.
  Future<LoopsComment> getCommentById(String videoId, String commentId) async {
    final resp =
        await _get('/api/v1/video/comments/$videoId/comment/$commentId');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsComment.fromJson(data);
  }

  /// GET /api/v1/video/comments/{videoId}/reply/{replyId} -- Single reply.
  Future<Map<String, dynamic>> getReplyById(
      String videoId, String replyId) async {
    final resp = await _get('/api/v1/video/comments/$videoId/reply/$replyId');
    return _handleResponse(resp);
  }

  /// GET /api/v1/video/comments/{videoId}/replies -- Comment replies thread.
  /// [commentId] is the parent comment (passed as ?cr=).
  Future<LoopsPaginatedResponse<LoopsCommentReply>> getCommentReplies(
    String videoId, {
    required String commentId,
    String? cursor,
  }) async {
    final params = <String, String>{'cr': commentId};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/video/comments/$videoId/replies', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Replies error');
    return _parsePaginated(resp, LoopsCommentReply.fromJson);
  }

  /// GET /api/v1/video/comments/{videoId}/hidden -- Hidden comments (auth, owner only).
  Future<LoopsPaginatedResponse<LoopsComment>> getHiddenComments(
    String videoId, {
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/video/comments/$videoId/hidden', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Hidden comments error');
    return _parsePaginated(resp, LoopsComment.fromJson);
  }

  /// POST /api/v1/video/comments/{videoId} -- Post a comment or reply.
  /// If [parentId] is set, creates a reply to that comment.
  Future<Map<String, dynamic>> postComment(
    String videoId, {
    required String comment,
    String? parentId,
  }) async {
    final body = <String, dynamic>{'comment': comment};
    if (parentId != null) body['parent_id'] = parentId;
    final resp = await _post('/api/v1/video/comments/$videoId', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/video/comments/edit/{videoId} -- Edit a comment.
  Future<Map<String, dynamic>> editComment(
    String videoId, {
    required String commentId,
    required String comment,
  }) async {
    final resp = await _post('/api/v1/video/comments/edit/$videoId',
        body: {'id': commentId, 'comment': comment});
    return _handleResponse(resp);
  }

  /// POST /api/v1/video/comments/reply/edit/{videoId} -- Edit a comment reply.
  Future<Map<String, dynamic>> editCommentReply(
    String videoId, {
    required String replyId,
    required String comment,
  }) async {
    final resp = await _post('/api/v1/video/comments/reply/edit/$videoId',
        body: {'id': replyId, 'comment': comment});
    return _handleResponse(resp);
  }

  /// POST /api/v1/comments/delete/{videoId}/{commentId} -- Delete a comment.
  Future<void> deleteComment(String videoId, String commentId) async {
    final resp = await _post('/api/v1/comments/delete/$videoId/$commentId');
    await _handleResponse(resp);
  }

  /// POST /api/v1/comments/delete/{videoId}/{parentId}/{replyId} -- Delete a reply.
  Future<void> deleteCommentReply(
      String videoId, String parentId, String replyId) async {
    final resp =
        await _post('/api/v1/comments/delete/$videoId/$parentId/$replyId');
    await _handleResponse(resp);
  }

  /// POST /api/v1/comments/like/{videoId}/{commentId} -- Like a comment.
  Future<Map<String, dynamic>> likeComment(
      String videoId, String commentId) async {
    final resp = await _post('/api/v1/comments/like/$videoId/$commentId');
    return _handleResponse(resp);
  }

  /// POST /api/v1/comments/unlike/{videoId}/{commentId} -- Unlike a comment.
  Future<Map<String, dynamic>> unlikeComment(
      String videoId, String commentId) async {
    final resp = await _post('/api/v1/comments/unlike/$videoId/$commentId');
    return _handleResponse(resp);
  }

  /// POST /api/v1/comments/like/{videoId}/{parentId}/{replyId} -- Like a reply.
  Future<Map<String, dynamic>> likeCommentReply(
      String videoId, String parentId, String replyId) async {
    final resp =
        await _post('/api/v1/comments/like/$videoId/$parentId/$replyId');
    return _handleResponse(resp);
  }

  /// POST /api/v1/comments/unlike/{videoId}/{parentId}/{replyId} -- Unlike a reply.
  Future<Map<String, dynamic>> unlikeCommentReply(
      String videoId, String parentId, String replyId) async {
    final resp =
        await _post('/api/v1/comments/unlike/$videoId/$parentId/$replyId');
    return _handleResponse(resp);
  }

  /// POST /api/v1/comments/hide/{videoId}/{commentId} -- Hide a comment (owner).
  Future<void> hideComment(String videoId, String commentId) async {
    final resp = await _post('/api/v1/comments/hide/$videoId/$commentId');
    await _handleResponse(resp);
  }

  /// POST /api/v1/comments/hide/{videoId}/{parentId}/{replyId} -- Hide reply.
  Future<void> hideCommentReply(
      String videoId, String parentId, String replyId) async {
    final resp =
        await _post('/api/v1/comments/hide/$videoId/$parentId/$replyId');
    await _handleResponse(resp);
  }

  /// POST /api/v1/comments/unhide/{videoId}/{commentId} -- Unhide a comment.
  Future<LoopsComment> unhideComment(String videoId, String commentId) async {
    final resp = await _post('/api/v1/comments/unhide/$videoId/$commentId');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsComment.fromJson(data);
  }

  /// GET /api/v1/comments/history/{videoId}/{commentId} -- Comment edit history.
  Future<List<Map<String, dynamic>>> getCommentHistory(
      String videoId, String commentId,
      {String? cursor}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp =
        await _get('/api/v1/comments/history/$videoId/$commentId', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/comments/history/{videoId}/{commentId}/{replyId} -- Reply edit history.
  Future<List<Map<String, dynamic>>> getCommentReplyHistory(
      String videoId, String commentId, String replyId,
      {String? cursor}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get(
        '/api/v1/comments/history/$videoId/$commentId/$replyId', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  // =========================================================================
  // 6. ACCOUNTS
  // =========================================================================

  /// GET /api/v1/account/info/self -- Current user's profile (auth required).
  Future<LoopsProfile> getSelf() async {
    final resp = await _get('/api/v1/account/info/self');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsProfile.fromJson(data);
  }

  /// GET /api/v1/account/info/{id} -- Get account by ID (auth required).
  Future<LoopsProfile> getAccountInfo(String id) async {
    final resp = await _get('/api/v1/account/info/$id');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsProfile.fromJson(data);
  }

  /// GET /api/v1/account/username/{username} -- Get account by username (public).
  Future<LoopsProfile> getAccountByUsername(String username) async {
    final resp = await _get('/api/v1/account/username/$username');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsProfile.fromJson(data);
  }

  /// GET /api/v1/account/state/{id} -- Get relationship state with account.
  /// Returns: is_following, is_followed_by, has_pending_follow_request, is_blocking, is_muting, etc.
  Future<Map<String, dynamic>> getRelationshipState(String id) async {
    final resp = await _get('/api/v1/account/state/$id');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/follow/{id} -- Follow an account.
  Future<Map<String, dynamic>> followAccount(String id) async {
    final resp = await _post('/api/v1/account/follow/$id');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/unfollow/{id} -- Unfollow an account.
  Future<Map<String, dynamic>> unfollowAccount(String id) async {
    final resp = await _post('/api/v1/account/unfollow/$id');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/undo-follow-request/{id} -- Cancel pending follow request.
  Future<Map<String, dynamic>> undoFollowRequest(String id) async {
    final resp = await _post('/api/v1/account/undo-follow-request/$id');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/block/{id} -- Block an account.
  Future<Map<String, dynamic>> blockAccount(String id) async {
    final resp = await _post('/api/v1/account/block/$id');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/unblock/{id} -- Unblock an account.
  Future<Map<String, dynamic>> unblockAccount(String id) async {
    final resp = await _post('/api/v1/account/unblock/$id');
    return _handleResponse(resp);
  }

  /// GET /api/v1/account/followers/{id} -- Account followers (auth required, cursor-paginated).
  Future<List<Map<String, dynamic>>> getAccountFollowers(String id,
      {String? cursor, String? search}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    final resp = await _get('/api/v1/account/followers/$id', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/web/account/followers/{id} -- Public followers list (throttled).
  Future<List<Map<String, dynamic>>> getPublicAccountFollowers(
      String id) async {
    final resp = await _get('/api/v1/web/account/followers/$id');
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/account/following/{id} -- Account following (auth required).
  Future<List<Map<String, dynamic>>> getAccountFollowing(String id,
      {String? cursor, String? search}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    final resp = await _get('/api/v1/account/following/$id', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/web/account/following/{id} -- Public following list (throttled).
  Future<List<Map<String, dynamic>>> getPublicAccountFollowing(
      String id) async {
    final resp = await _get('/api/v1/web/account/following/$id');
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/account/friends/{id} -- Mutual follows (auth required).
  Future<List<Map<String, dynamic>>> getAccountFriends(String id,
      {String? cursor, String? search}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    final resp = await _get('/api/v1/account/friends/$id', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/account/suggested/{id} -- Suggested follows for account.
  Future<List<Map<String, dynamic>>> getAccountSuggestedFollows(
      String id) async {
    final resp = await _get('/api/v1/account/suggested/$id');
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/accounts/suggested -- Global suggested accounts (auth required).
  Future<Map<String, dynamic>> getSuggestedAccounts() async {
    final resp = await _get('/api/v1/accounts/suggested');
    return _handleResponse(resp);
  }

  /// POST /api/v1/accounts/suggested/hide -- Hide a suggestion.
  Future<void> hideSuggestion(String profileId) async {
    final resp = await _post('/api/v1/accounts/suggested/hide',
        body: {'profile_id': profileId});
    await _handleResponse(resp);
  }

  /// POST /api/v1/accounts/suggested/unhide -- Unhide a suggestion.
  Future<void> unhideSuggestion(String profileId) async {
    final resp = await _post('/api/v1/accounts/suggested/unhide',
        body: {'profile_id': profileId});
    await _handleResponse(resp);
  }

  /// GET /api/v1/account/videos/likes -- User's liked videos (auth required).
  Future<LoopsPaginatedResponse<LoopsVideo>> getAccountVideoLikes({
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/account/videos/likes', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Likes error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  // =========================================================================
  // 7. NOTIFICATIONS
  // =========================================================================

  /// GET /api/v1/account/notifications -- List notifications (auth, cursor-paginated).
  Future<LoopsPaginatedResponse<LoopsNotification>> getNotifications({
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/account/notifications', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Notifications error');
    return _parsePaginated(resp, LoopsNotification.fromJson);
  }

  /// GET /api/v1/account/notifications/count -- Unread notification count.
  Future<int> getNotificationUnreadCount() async {
    final resp = await _get('/api/v1/account/notifications/count');
    final json = await _handleResponse(resp);
    return json['data'] as int? ?? json['count'] as int? ?? 0;
  }

  /// POST /api/v1/account/notifications/{id}/read -- Mark single notification read.
  Future<void> markNotificationAsRead(String id) async {
    final resp = await _post('/api/v1/account/notifications/$id/read');
    await _handleResponse(resp);
  }

  /// POST /api/v1/account/notifications/mark-all-read -- Mark all notifications read.
  Future<void> markAllNotificationsAsRead() async {
    final resp = await _post('/api/v1/account/notifications/mark-all-read');
    await _handleResponse(resp);
  }

  /// GET /api/v1/account/notifications/system/{id} -- Get system notification (auth).
  Future<Map<String, dynamic>> getSystemNotification(String id) async {
    final resp = await _get('/api/v1/account/notifications/system/$id');
    return _handleResponse(resp);
  }

  /// GET /api/v1/notifications/system/{id} -- Public system notification.
  Future<Map<String, dynamic>> getPublicSystemNotification(String id) async {
    final resp = await _get('/api/v1/notifications/system/$id');
    return _handleResponse(resp);
  }

  // =========================================================================
  // 8. SEARCH
  // =========================================================================

  /// GET /api/v1/search -- Unified search (auth required).
  /// [type]: top, all, videos, users, hashtags. [limit]: 1-20.
  Future<LoopsSearchResults> search(
    String query, {
    String type = 'all',
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, String>{
      'query': query,
      'type': type,
      'limit': limit.toString(),
    };
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/search', params);
    final json = await _handleResponse(resp);
    return LoopsSearchResults.fromJson(json);
  }

  /// POST /api/v1/search/users -- Search users (autocomplete).
  Future<List<LoopsProfile>> searchUsers(String query) async {
    final resp = await _post('/api/v1/search/users', body: {'q': query});
    final list = await _handleListResponse(resp);
    return list
        .map((e) => LoopsProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =========================================================================
  // 9. EXPLORE
  // =========================================================================

  /// GET /api/v1/explore/tags -- Trending tags.
  Future<List<Map<String, dynamic>>> getTrendingTags() async {
    final resp = await _get('/api/v1/explore/tags');
    final json = await _handleResponse(resp);
    return (json['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// GET /api/v1/explore/tag-feed/{name} -- Tag feed from explore (trending tags only).
  Future<LoopsPaginatedResponse<LoopsVideo>> getExploreTagFeed(
    String tagName, {
    String? cursor,
    int limit = 10,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/explore/tag-feed/$tagName', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Tag feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// GET /api/v1/tags/video/{name} -- Video tag feed (public or auth).
  Future<LoopsPaginatedResponse<LoopsVideo>> getVideoTagFeed(
    String tagName, {
    String? cursor,
    int limit = 10,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/tags/video/$tagName', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Tag feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  // =========================================================================
  // 10. AUTOCOMPLETE
  // =========================================================================

  /// GET /api/v1/autocomplete/tags -- Tag autocomplete (auth required).
  Future<List<LoopsHashtag>> autocompleteTags(String query) async {
    final resp = await _get('/api/v1/autocomplete/tags', {'q': query});
    final list = await _handleListResponse(resp);
    return list
        .map((e) => LoopsHashtag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/autocomplete/accounts -- Account autocomplete (auth required).
  Future<List<LoopsProfile>> autocompleteAccounts(String query) async {
    final resp = await _get('/api/v1/autocomplete/accounts', {'q': query});
    final list = await _handleListResponse(resp);
    return list
        .map((e) => LoopsProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =========================================================================
  // 11. SOUNDS
  // =========================================================================

  /// GET /api/v1/sounds/details/{id} -- Sound details (auth required).
  Future<LoopsSound> getSoundDetails(String id) async {
    final resp = await _get('/api/v1/sounds/details/$id');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsSound.fromJson(data);
  }

  /// GET /api/v1/sounds/feed/{id} -- Videos using a sound (auth required).
  Future<LoopsPaginatedResponse<LoopsVideo>> getSoundFeed(
    String id, {
    required String key,
    String? cursor,
  }) async {
    final params = <String, String>{'key': key};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/sounds/feed/$id', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Sound feed error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  // =========================================================================
  // 12. STUDIO
  // =========================================================================

  /// GET /api/v1/studio/posts -- Own posts for studio management (auth required).
  Future<LoopsPaginatedResponse<Map<String, dynamic>>> getStudioPosts({
    String? search,
    int limit = 10,
    String sortField = 'created_at',
    String sortDirection = 'desc',
    String? cursor,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'sort_field': sortField,
      'sort_direction': sortDirection,
    };
    if (search != null) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/studio/posts', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Studio error');
    return _parsePaginated(resp, (json) => json);
  }

  /// GET /api/v1/studio/playlist-posts -- Videos available for playlists.
  Future<LoopsPaginatedResponse<Map<String, dynamic>>> getStudioPlaylistPosts({
    String? search,
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (search != null) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/studio/playlist-posts', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Studio error');
    return _parsePaginated(resp, (json) => json);
  }

  // =========================================================================
  // 13. PLAYLISTS
  // =========================================================================

  /// GET /api/v1/studio/playlists -- List own playlists (auth required).
  Future<LoopsPaginatedResponse<LoopsPlaylist>> getPlaylists({
    String? search,
    int limit = 10,
    String sortField = 'created_at',
    String sortDirection = 'desc',
    String? cursor,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'sort_field': sortField,
      'sort_direction': sortDirection,
    };
    if (search != null) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/studio/playlists', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Playlists error');
    return _parsePaginated(resp, LoopsPlaylist.fromJson);
  }

  /// POST /api/v1/studio/playlists -- Create a playlist.
  Future<LoopsPlaylist> createPlaylist({
    required String name,
    String? description,
    String visibility = 'public',
  }) async {
    final resp = await _post('/api/v1/studio/playlists', body: {
      'name': name,
      if (description != null) 'description': description,
      'visibility': visibility,
    });
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsPlaylist.fromJson(data);
  }

  /// GET /api/v1/studio/playlists/{id} -- Get playlist details.
  Future<LoopsPlaylist> getPlaylist(int id) async {
    final resp = await _get('/api/v1/studio/playlists/$id');
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsPlaylist.fromJson(data);
  }

  /// PUT /api/v1/studio/playlists/{id} -- Update a playlist.
  Future<LoopsPlaylist> updatePlaylist(
    int id, {
    String? name,
    String? description,
    String? visibility,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (visibility != null) body['visibility'] = visibility;
    final resp = await _put('/api/v1/studio/playlists/$id', body: body);
    final json = await _handleResponse(resp);
    final data =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return LoopsPlaylist.fromJson(data);
  }

  /// DELETE /api/v1/studio/playlists/{id} -- Delete a playlist.
  Future<void> deletePlaylist(int id) async {
    final resp = await _delete('/api/v1/studio/playlists/$id');
    if (resp.statusCode != 204 && resp.statusCode < 200 ||
        resp.statusCode >= 300) {
      throw LoopsApiException(resp.statusCode, 'Delete playlist failed');
    }
  }

  /// GET /api/v1/studio/playlists/{id}/videos -- List playlist videos.
  Future<LoopsPaginatedResponse<LoopsVideo>> getPlaylistVideos(
    int playlistId, {
    int limit = 10,
    String? cursor,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    final resp =
        await _get('/api/v1/studio/playlists/$playlistId/videos', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Playlist videos error');
    return _parsePaginated(resp, LoopsVideo.fromJson);
  }

  /// POST /api/v1/studio/playlists/{id}/videos -- Add video to playlist.
  Future<void> addVideoToPlaylist(int playlistId, int videoId,
      {int? position}) async {
    final body = <String, dynamic>{'video_id': videoId};
    if (position != null) body['position'] = position;
    final resp =
        await _post('/api/v1/studio/playlists/$playlistId/videos', body: body);
    await _handleResponse(resp);
  }

  /// DELETE /api/v1/studio/playlists/{playlistId}/videos/{videoId} -- Remove video.
  Future<void> removeVideoFromPlaylist(int playlistId, int videoId) async {
    final resp =
        await _delete('/api/v1/studio/playlists/$playlistId/videos/$videoId');
    await _handleResponse(resp);
  }

  /// PUT /api/v1/studio/playlists/{id}/reorder -- Reorder playlist videos.
  Future<void> reorderPlaylistVideos(int playlistId, List<int> videoIds) async {
    final resp = await _put('/api/v1/studio/playlists/$playlistId/reorder',
        body: {'video_ids': videoIds});
    await _handleResponse(resp);
  }

  // =========================================================================
  // 14. SETTINGS
  // =========================================================================

  /// POST /api/v1/account/settings/bio -- Update display name and bio.
  Future<Map<String, dynamic>> updateBio({
    String? name,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    final resp = await _post('/api/v1/account/settings/bio', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/update-avatar -- Upload new avatar.
  Future<Map<String, dynamic>> updateAvatar(String filePath,
      {Map<String, dynamic>? coordinates}) async {
    final request = http.MultipartRequest(
        'POST', _uri('/api/v1/account/settings/update-avatar'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    if (coordinates != null) {
      request.fields['coordinates'] = jsonEncode(coordinates);
    }
    final streamedResp = await httpClient.send(request);
    final resp = await http.Response.fromStream(streamedResp);
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/delete-avatar -- Remove avatar.
  Future<Map<String, dynamic>> deleteAvatar() async {
    final resp = await _post('/api/v1/account/settings/delete-avatar');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/update-password -- Change password.
  Future<void> updatePassword(
      String password, String passwordConfirmation) async {
    final resp = await _post('/api/v1/account/settings/update-password', body: {
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    await _handleResponse(resp);
  }

  /// GET /api/v1/account/settings/security-config -- 2FA status.
  Future<Map<String, dynamic>> getSecurityConfig() async {
    final resp = await _get('/api/v1/account/settings/security-config');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/setup-2fa -- Begin 2FA setup, returns QR.
  Future<Map<String, dynamic>> setupTwoFactor() async {
    final resp = await _post('/api/v1/account/settings/setup-2fa');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/confirm-2fa -- Confirm 2FA with code.
  Future<void> confirmTwoFactor(String code) async {
    final resp = await _post('/api/v1/account/settings/confirm-2fa',
        body: {'code': code});
    await _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/disable-2fa -- Disable 2FA.
  Future<void> disableTwoFactor() async {
    final resp = await _post('/api/v1/account/settings/disable-2fa');
    await _handleResponse(resp);
  }

  /// GET /api/v1/account/settings/privacy -- Privacy settings.
  Future<Map<String, dynamic>> getPrivacySettings() async {
    final resp = await _get('/api/v1/account/settings/privacy');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/privacy -- Update privacy settings.
  Future<Map<String, dynamic>> updatePrivacySettings(
      {required bool discoverable}) async {
    final resp = await _post('/api/v1/account/settings/privacy',
        body: {'discoverable': discoverable});
    return _handleResponse(resp);
  }

  /// GET /api/v1/account/settings/birthdate -- Check birthdate status.
  Future<Map<String, dynamic>> checkBirthdate() async {
    final resp = await _get('/api/v1/account/settings/birthdate');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/birthdate -- Set birthdate.
  Future<void> setBirthdate(String birthDate) async {
    final resp = await _post('/api/v1/account/settings/birthdate',
        body: {'birth_date': birthDate});
    await _handleResponse(resp);
  }

  /// GET /api/v1/account/settings/total-blocked-accounts -- Blocked count.
  Future<int> getTotalBlockedAccounts() async {
    final resp = await _get('/api/v1/account/settings/total-blocked-accounts');
    final json = await _handleResponse(resp);
    return (json['data'] as Map<String, dynamic>?)?['count'] as int? ?? 0;
  }

  /// GET /api/v1/account/settings/blocked-accounts -- List blocked (cursor-paginated).
  Future<List<Map<String, dynamic>>> getBlockedAccounts(
      {String? cursor, String? search}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    final resp =
        await _get('/api/v1/account/settings/blocked-accounts', params);
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/account/settings/blocked-account-search -- Search for accounts to block.
  Future<List<LoopsProfile>> searchBlockableAccounts(String query) async {
    final resp = await _post('/api/v1/account/settings/blocked-account-search',
        body: {'q': query});
    final list = await _handleListResponse(resp);
    return list
        .map((e) => LoopsProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/account/settings/account/disable -- Disable account (requires password).
  Future<void> disableAccount(String password) async {
    final resp = await _post('/api/v1/account/settings/account/disable',
        body: {'password': password});
    await _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/account/delete -- Delete account (requires password).
  Future<void> deleteAccount(String password) async {
    final resp = await _post('/api/v1/account/settings/account/delete',
        body: {'password': password});
    await _handleResponse(resp);
  }

  // =========================================================================
  // 15. PROFILE LINKS
  // =========================================================================

  /// GET /api/v1/account/settings/links -- List profile links.
  Future<List<Map<String, dynamic>>> getProfileLinks() async {
    final resp = await _get('/api/v1/account/settings/links');
    final json = await _handleResponse(resp);
    final data = json['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// POST /api/v1/account/settings/links/add -- Add a profile link.
  Future<Map<String, dynamic>> addProfileLink({
    required String title,
    required String url,
  }) async {
    final resp = await _post('/api/v1/account/settings/links/add',
        body: {'title': title, 'url': url});
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/links/delete/{id} -- Remove a profile link.
  Future<void> removeProfileLink(String id) async {
    final resp = await _post('/api/v1/account/settings/links/delete/$id');
    await _handleResponse(resp);
  }

  // =========================================================================
  // 16. EMAIL SETTINGS
  // =========================================================================

  /// GET /api/v1/account/settings/email -- Get email settings.
  Future<Map<String, dynamic>> getEmailSettings() async {
    final resp = await _get('/api/v1/account/settings/email');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/email/update -- Change email.
  Future<Map<String, dynamic>> changeEmail(Map<String, dynamic> body) async {
    final resp =
        await _post('/api/v1/account/settings/email/update', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/email/cancel -- Cancel email change.
  Future<void> cancelEmailChange() async {
    final resp = await _post('/api/v1/account/settings/email/cancel');
    await _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/email/verify -- Verify email change.
  Future<Map<String, dynamic>> verifyEmailChange(
      Map<String, dynamic> body) async {
    final resp =
        await _post('/api/v1/account/settings/email/verify', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/email/resend -- Resend verification.
  Future<void> resendEmailVerification() async {
    final resp = await _post('/api/v1/account/settings/email/resend');
    await _handleResponse(resp);
  }

  // =========================================================================
  // 17. PUSH NOTIFICATIONS
  // =========================================================================

  /// GET /api/v1/account/settings/push-notifications/status
  Future<Map<String, dynamic>> getPushNotificationStatus() async {
    final resp =
        await _get('/api/v1/account/settings/push-notifications/status');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/push-notifications/enable
  Future<Map<String, dynamic>> enablePushNotifications(
      Map<String, dynamic> body) async {
    final resp = await _post(
        '/api/v1/account/settings/push-notifications/enable',
        body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/push-notifications/disable
  Future<void> disablePushNotifications() async {
    final resp =
        await _post('/api/v1/account/settings/push-notifications/disable');
    await _handleResponse(resp);
  }

  // =========================================================================
  // 18. USER PREFERENCES
  // =========================================================================

  /// GET /api/v1/app/preferences -- Get app preferences.
  Future<Map<String, dynamic>> getAppPreferences() async {
    final resp = await _get('/api/v1/app/preferences');
    return _handleResponse(resp);
  }

  /// POST /api/v1/app/preferences -- Update app preferences.
  /// Supports: autoplay_videos, loop_videos, default_feed (local/following/forYou),
  /// hide_for_you_feed, mute_on_open, auto_expand_cw, appearance (light/dark/system).
  Future<Map<String, dynamic>> updateAppPreferences(
      Map<String, dynamic> preferences) async {
    final resp = await _post('/api/v1/app/preferences', body: preferences);
    return _handleResponse(resp);
  }

  // =========================================================================
  // 19. REPORTS
  // =========================================================================

  /// POST /api/v1/report -- Submit a report.
  /// [type]: video, profile, comment, reply, hashtag, starter_kit.
  /// [key]: report subtype. [comment]: optional user message.
  Future<void> submitReport({
    required String type,
    required String id,
    required String key,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'id': id,
      'key': key,
    };
    if (comment != null) body['comment'] = comment;
    final resp = await _post('/api/v1/report', body: body);
    await _handleResponse(resp);
  }

  // =========================================================================
  // 20. STARTER KITS
  // =========================================================================

  /// GET /api/v1/starter-kits/browse -- Browse starter kits (public).
  Future<LoopsPaginatedResponse<Map<String, dynamic>>> browseStarterKits({
    String sort = 'popular',
    int limit = 6,
    String? tag,
    String? search,
    String? cursor,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
    };
    if (tag != null) params['tag'] = tag;
    if (search != null) params['q'] = search;
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/starter-kits/browse', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Starter kits error');
    return _parsePaginated(resp, (json) => json);
  }

  /// GET /api/v1/starter-kits/popular -- Popular starter kits.
  Future<Map<String, dynamic>> getPopularStarterKits() async {
    final resp = await _get('/api/v1/starter-kits/popular');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/latest -- Latest starter kits.
  Future<Map<String, dynamic>> getLatestStarterKits() async {
    final resp = await _get('/api/v1/starter-kits/latest');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/details/{id} -- Starter kit details (public).
  Future<Map<String, dynamic>> getStarterKit(String id) async {
    final resp = await _get('/api/v1/starter-kits/details/$id');
    return _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/create -- Create a starter kit (auth).
  Future<Map<String, dynamic>> createStarterKit(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/starter-kits/create', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id} -- Update a starter kit.
  Future<Map<String, dynamic>> updateStarterKit(
      String id, Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/starter-kits/details/$id', body: body);
    return _handleResponse(resp);
  }

  /// DELETE /api/v1/starter-kits/details/{id} -- Delete a starter kit.
  Future<void> deleteStarterKit(String id) async {
    final resp = await _delete('/api/v1/starter-kits/details/$id');
    await _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id}/use -- Use a starter kit.
  Future<Map<String, dynamic>> useStarterKit(String id) async {
    final resp = await _post('/api/v1/starter-kits/details/$id/use');
    return _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id}/reuse -- Reuse a starter kit.
  Future<Map<String, dynamic>> reuseStarterKit(String id) async {
    final resp = await _post('/api/v1/starter-kits/details/$id/reuse');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/details/{id}/used -- Check if used.
  Future<Map<String, dynamic>> hasUsedStarterKit(String id) async {
    final resp = await _get('/api/v1/starter-kits/details/$id/used');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/details/{id}/accounts -- Kit accounts.
  Future<List<Map<String, dynamic>>> getStarterKitAccounts(String id) async {
    final resp = await _get('/api/v1/starter-kits/details/$id/accounts');
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/starter-kits/details/{id}/accounts/add -- Add account to kit.
  Future<Map<String, dynamic>> addAccountToStarterKit(
      String kitId, Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/starter-kits/details/$kitId/accounts/add',
        body: body);
    return _handleResponse(resp);
  }

  /// DELETE /api/v1/starter-kits/details/{id}/accounts/{accountId} -- Remove account from kit.
  Future<void> removeAccountFromStarterKit(
      String kitId, String accountId) async {
    final resp = await _delete(
        '/api/v1/starter-kits/details/$kitId/accounts/$accountId');
    await _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/details/{id}/membership -- Check membership.
  Future<Map<String, dynamic>> checkKitMembership(String id) async {
    final resp = await _get('/api/v1/starter-kits/details/$id/membership');
    return _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id}/membership -- Handle membership.
  Future<Map<String, dynamic>> handleKitMembership(
      String id, Map<String, dynamic> body) async {
    final resp =
        await _post('/api/v1/starter-kits/details/$id/membership', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id}/membership/revoke -- Revoke membership.
  Future<void> revokeKitMembership(String id) async {
    final resp =
        await _post('/api/v1/starter-kits/details/$id/membership/revoke');
    await _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/details/{id}/pending-changes -- Pending changes.
  Future<Map<String, dynamic>> getKitPendingChanges(String id) async {
    final resp = await _get('/api/v1/starter-kits/details/$id/pending-changes');
    return _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id}/icon -- Upload kit icon.
  Future<Map<String, dynamic>> uploadStarterKitIcon(
      String id, String filePath) async {
    final request = http.MultipartRequest(
        'POST', _uri('/api/v1/starter-kits/details/$id/icon'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('icon', filePath));
    final streamedResp = await httpClient.send(request);
    final resp = await http.Response.fromStream(streamedResp);
    return _handleResponse(resp);
  }

  /// DELETE /api/v1/starter-kits/details/{id}/icon -- Delete kit icon.
  Future<void> deleteStarterKitIcon(String id) async {
    final resp = await _delete('/api/v1/starter-kits/details/$id/icon');
    await _handleResponse(resp);
  }

  /// POST /api/v1/starter-kits/details/{id}/header -- Upload kit header.
  Future<Map<String, dynamic>> uploadStarterKitHeader(
      String id, String filePath) async {
    final request = http.MultipartRequest(
        'POST', _uri('/api/v1/starter-kits/details/$id/header'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('header', filePath));
    final streamedResp = await httpClient.send(request);
    final resp = await http.Response.fromStream(streamedResp);
    return _handleResponse(resp);
  }

  /// DELETE /api/v1/starter-kits/details/{id}/header -- Delete kit header.
  Future<void> deleteStarterKitHeader(String id) async {
    final resp = await _delete('/api/v1/starter-kits/details/$id/header');
    await _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/my-kits -- Own starter kits (auth).
  Future<Map<String, dynamic>> getMyStarterKits() async {
    final resp = await _get('/api/v1/starter-kits/my-kits');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/joined-kits -- Joined starter kits (auth).
  Future<Map<String, dynamic>> getJoinedStarterKits() async {
    final resp = await _get('/api/v1/starter-kits/joined-kits');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/config -- Starter kits configuration.
  Future<Map<String, dynamic>> getStarterKitsConfig() async {
    final resp = await _get('/api/v1/starter-kits/config');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/stats -- Starter kits stats.
  Future<Map<String, dynamic>> getStarterKitsStats() async {
    final resp = await _get('/api/v1/starter-kits/stats');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/self/config -- Self starter kit config.
  Future<Map<String, dynamic>> getSelfStarterKitConfig() async {
    final resp = await _get('/api/v1/starter-kits/self/config');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/top-creators -- Top starter kit creators.
  Future<Map<String, dynamic>> getStarterKitTopCreators() async {
    final resp = await _get('/api/v1/starter-kits/top-creators');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/hashtag/popular -- Popular hashtags for kits.
  Future<Map<String, dynamic>> getStarterKitPopularHashtags() async {
    final resp = await _get('/api/v1/starter-kits/hashtag/popular');
    return _handleResponse(resp);
  }

  /// GET /api/v1/starter-kits/hashtag/kits -- Kits by hashtag.
  Future<LoopsPaginatedResponse<Map<String, dynamic>>> getStarterKitsByHashtag({
    required String tag,
    String sort = 'popular',
    String? cursor,
  }) async {
    final params = <String, String>{'tag': tag, 'sort': sort};
    if (cursor != null) params['cursor'] = cursor;
    final resp = await _get('/api/v1/starter-kits/hashtag/kits', params);
    if (resp.statusCode >= 400)
      throw LoopsApiException(resp.statusCode, 'Kits by hashtag error');
    return _parsePaginated(resp, (json) => json);
  }

  /// POST /api/v1/starter-kits/compose/search/accounts -- Search accounts for kit composition.
  Future<List<Map<String, dynamic>>> searchStarterKitAccounts(
      String query) async {
    final resp = await _post('/api/v1/starter-kits/compose/search/accounts',
        body: {'q': query});
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/starter-kits/compose/search/hashtags -- Search hashtags for kit.
  Future<List<Map<String, dynamic>>> searchStarterKitHashtags(
      String query) async {
    final resp = await _post('/api/v1/starter-kits/compose/search/hashtags',
        body: {'q': query});
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/starter-kits/edit/search/accounts/{id} -- Search accounts for kit edit.
  Future<List<Map<String, dynamic>>> searchStarterKitEditAccounts(
      String kitId, String query) async {
    final resp = await _post('/api/v1/starter-kits/edit/search/accounts/$kitId',
        body: {'q': query});
    final list = await _handleListResponse(resp);
    return list.cast<Map<String, dynamic>>();
  }

  // =========================================================================
  // 21. STARTER KIT SETTINGS (Account-level)
  // =========================================================================

  /// GET /api/v1/account/settings/starter-kits/status
  Future<Map<String, dynamic>> getStarterKitsStatus() async {
    final resp = await _get('/api/v1/account/settings/starter-kits/status');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/settings/starter-kits/update
  Future<Map<String, dynamic>> updateStarterKitsStatus(
      Map<String, dynamic> body) async {
    final resp =
        await _post('/api/v1/account/settings/starter-kits/update', body: body);
    return _handleResponse(resp);
  }

  // =========================================================================
  // 22. ACCOUNT DATA / EXPORTS
  // =========================================================================

  /// GET /api/v1/account/data/insights -- Data insights.
  Future<Map<String, dynamic>> getDataInsights() async {
    final resp = await _get('/api/v1/account/data/insights');
    return _handleResponse(resp);
  }

  /// GET /api/v1/account/data/settings -- Data settings.
  Future<Map<String, dynamic>> getDataSettings() async {
    final resp = await _get('/api/v1/account/data/settings');
    return _handleResponse(resp);
  }

  /// PUT /api/v1/account/data/settings -- Update data settings.
  Future<Map<String, dynamic>> updateDataSettings(
      Map<String, dynamic> body) async {
    final resp = await _put('/api/v1/account/data/settings', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/data/export/full -- Request full data export.
  Future<Map<String, dynamic>> requestFullExport() async {
    final resp = await _post('/api/v1/account/data/export/full');
    return _handleResponse(resp);
  }

  /// POST /api/v1/account/data/export/selective -- Request selective export.
  Future<Map<String, dynamic>> requestSelectiveExport(
      Map<String, dynamic> body) async {
    final resp =
        await _post('/api/v1/account/data/export/selective', body: body);
    return _handleResponse(resp);
  }

  /// GET /api/v1/account/data/export/history -- Export history.
  Future<Map<String, dynamic>> getExportHistory() async {
    final resp = await _get('/api/v1/account/data/export/history');
    return _handleResponse(resp);
  }

  /// GET /api/v1/account/data/export/{id}/download -- Download export.
  Future<http.Response> downloadExport(String id) async {
    return _get('/api/v1/account/data/export/$id/download');
  }

  // =========================================================================
  // 23. INTENTS
  // =========================================================================

  /// POST /api/v1/intents/follow/account -- Follow intent (for deep links).
  Future<Map<String, dynamic>> followIntent(Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/intents/follow/account', body: body);
    return _handleResponse(resp);
  }

  // =========================================================================
  // 24. REGISTRATION (invite-based)
  // =========================================================================

  /// POST /api/v1/invite/verify -- Verify an invite code.
  Future<Map<String, dynamic>> verifyInvite(Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/invite/verify', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/invite/check-username -- Check username availability.
  Future<Map<String, dynamic>> checkUsername(String username) async {
    final resp = await _post('/api/v1/invite/check-username',
        body: {'username': username});
    return _handleResponse(resp);
  }

  /// POST /api/v1/invite/register -- Register via invite.
  Future<Map<String, dynamic>> registerViaInvite(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/invite/register', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/invite/verify-age -- Verify age for invite registration.
  Future<Map<String, dynamic>> verifyAgeInvite(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/invite/verify-age', body: body);
    return _handleResponse(resp);
  }

  // =========================================================================
  // 25. REGISTRATION (email-based)
  // =========================================================================

  /// POST /api/v1/auth/register/email -- Send email verification.
  Future<Map<String, dynamic>> registerSendEmail(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/register/email', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/register/email/resend -- Resend email verification.
  Future<Map<String, dynamic>> registerResendEmail(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/register/email/resend', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/register/email/verify -- Verify email code.
  Future<Map<String, dynamic>> registerVerifyEmail(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/register/email/verify', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/register/username -- Claim username.
  Future<Map<String, dynamic>> registerClaimUsername(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/register/username', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/register/verify-age -- Verify age for registration.
  Future<Map<String, dynamic>> registerVerifyAge(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/register/verify-age', body: body);
    return _handleResponse(resp);
  }

  // =========================================================================
  // 26. EMAIL VERIFICATION (existing accounts)
  // =========================================================================

  /// POST /api/v1/auth/verify/email -- Initiate email verification.
  Future<Map<String, dynamic>> initiateEmailVerification(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/verify/email', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/verify/email/confirm -- Confirm email verification.
  Future<Map<String, dynamic>> confirmEmailVerification(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/verify/email/confirm', body: body);
    return _handleResponse(resp);
  }

  /// POST /api/v1/auth/verify/email/resend -- Resend verification.
  Future<Map<String, dynamic>> resendEmailVerificationExisting(
      Map<String, dynamic> body) async {
    final resp = await _post('/api/v1/auth/verify/email/resend', body: body);
    return _handleResponse(resp);
  }
}
