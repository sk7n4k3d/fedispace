// Loops API client for loops.video instances
//
// Provides typed models and API methods for interacting with
// Loops (loops.video) federated short video platform.
// Complete client covering ALL routes from loops-server routes/api.php.
//
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Exception thrown when the Loops API returns an error.
class LoopsApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  LoopsApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() =>
      'LoopsApiException($statusCode): $message${body != null ? '\n$body' : ''}';
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A Loops video post.
class LoopsVideo {
  final String id;
  final Map<String, dynamic> account;
  final String? caption;
  final String? url;
  final bool isSensitive;

  // Media
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final String? altText;
  final int? duration;

  // Counts
  final int likes;
  final int shares;
  final int comments;
  final int bookmarks;

  // Interaction state
  final bool hasLiked;
  final bool hasBookmarked;

  // Permissions
  final bool canComment;
  final bool canDownload;
  final bool canDuet;
  final bool canStitch;

  // Audio
  final bool hasAudio;
  final String? audioId;
  final String? soundId;

  // Meta
  final bool containsAi;
  final bool containsAd;

  final String? createdAt;

  LoopsVideo({
    required this.id,
    required this.account,
    this.caption,
    this.url,
    this.isSensitive = false,
    this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    this.altText,
    this.duration,
    this.likes = 0,
    this.shares = 0,
    this.comments = 0,
    this.bookmarks = 0,
    this.hasLiked = false,
    this.hasBookmarked = false,
    this.canComment = true,
    this.canDownload = true,
    this.canDuet = false,
    this.canStitch = false,
    this.hasAudio = false,
    this.audioId,
    this.soundId,
    this.containsAi = false,
    this.containsAd = false,
    this.createdAt,
  });

  factory LoopsVideo.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as Map<String, dynamic>? ?? {};
    final permissions = json['permissions'] as Map<String, dynamic>? ?? {};
    final audio = json['audio'] as Map<String, dynamic>? ?? {};
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return LoopsVideo(
      id: json['id']?.toString() ?? '',
      account: (json['account'] as Map<String, dynamic>?) ?? {},
      caption: json['caption'] as String?,
      url: json['url'] as String?,
      isSensitive: json['is_sensitive'] == true,
      thumbnailUrl: media['thumbnail_url'] as String?,
      videoUrl: media['video_url'] as String?,
      hlsUrl: media['hls_url'] as String?,
      altText: media['alt_text'] as String?,
      duration: media['duration'] as int?,
      likes: json['likes'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      bookmarks: json['bookmarks'] as int? ?? 0,
      hasLiked: json['has_liked'] == true,
      hasBookmarked: json['has_bookmarked'] == true,
      canComment: permissions['can_comment'] != false,
      canDownload: permissions['can_download'] != false,
      canDuet: permissions['can_duet'] == true,
      canStitch: permissions['can_stitch'] == true,
      hasAudio: audio['has_audio'] == true,
      audioId: audio['id']?.toString(),
      soundId: audio['sound_id']?.toString(),
      containsAi: meta['contains_ai'] == true,
      containsAd: meta['contains_ad'] == true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account': account,
        'caption': caption,
        'url': url,
        'is_sensitive': isSensitive,
        'media': {
          'thumbnail_url': thumbnailUrl,
          'video_url': videoUrl,
          'hls_url': hlsUrl,
          'alt_text': altText,
          'duration': duration,
        },
        'likes': likes,
        'shares': shares,
        'comments': comments,
        'bookmarks': bookmarks,
        'has_liked': hasLiked,
        'has_bookmarked': hasBookmarked,
        'permissions': {
          'can_comment': canComment,
          'can_download': canDownload,
          'can_duet': canDuet,
          'can_stitch': canStitch,
        },
        'audio': {
          'has_audio': hasAudio,
          'id': audioId,
          'sound_id': soundId,
        },
        'meta': {
          'contains_ai': containsAi,
          'contains_ad': containsAd,
        },
        'created_at': createdAt,
      };
}

/// A Loops user profile.
class LoopsProfile {
  final String id;
  final String username;
  final String? name;
  final String? bio;
  final String? avatar;
  final String? header;
  final int followersCount;
  final int followingCount;
  final int videosCount;
  final bool isFollowing;
  final bool isBlocked;

  LoopsProfile({
    required this.id,
    required this.username,
    this.name,
    this.bio,
    this.avatar,
    this.header,
    this.followersCount = 0,
    this.followingCount = 0,
    this.videosCount = 0,
    this.isFollowing = false,
    this.isBlocked = false,
  });

  factory LoopsProfile.fromJson(Map<String, dynamic> json) {
    return LoopsProfile(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
      header: json['header'] as String?,
      followersCount: json['followers_count'] as int? ??
          json['follower_count'] as int? ??
          0,
      followingCount: json['following_count'] as int? ?? 0,
      videosCount:
          json['videos_count'] as int? ?? json['post_count'] as int? ?? 0,
      isFollowing: json['is_following'] == true,
      isBlocked: json['is_blocked'] == true || json['is_blocking'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'bio': bio,
        'avatar': avatar,
        'header': header,
        'followers_count': followersCount,
        'following_count': followingCount,
        'videos_count': videosCount,
        'is_following': isFollowing,
        'is_blocked': isBlocked,
      };
}

/// A comment on a Loops video.
class LoopsComment {
  final String id;
  final String videoId;
  final String? accountId;
  final Map<String, dynamic>? account;
  final String content;
  final int likes;
  final bool hasLiked;
  final int replies;
  final bool isEdited;
  final bool isHidden;
  final bool isOwner;
  final String? createdAt;

  LoopsComment({
    required this.id,
    required this.videoId,
    this.accountId,
    this.account,
    required this.content,
    this.likes = 0,
    this.hasLiked = false,
    this.replies = 0,
    this.isEdited = false,
    this.isHidden = false,
    this.isOwner = false,
    this.createdAt,
  });

  factory LoopsComment.fromJson(Map<String, dynamic> json) {
    return LoopsComment(
      id: json['id']?.toString() ?? '',
      videoId: json['video_id']?.toString() ?? json['v_id']?.toString() ?? '',
      accountId: json['account_id']?.toString(),
      account: json['account'] as Map<String, dynamic>?,
      content: json['content'] as String? ?? json['caption'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      hasLiked: json['has_liked'] == true || json['liked'] == true,
      replies: json['replies'] as int? ?? 0,
      isEdited: json['is_edited'] == true,
      isHidden: json['is_hidden'] == true,
      isOwner: json['is_owner'] == true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'video_id': videoId,
        'account_id': accountId,
        'account': account,
        'content': content,
        'likes': likes,
        'has_liked': hasLiked,
        'replies': replies,
        'is_edited': isEdited,
        'is_hidden': isHidden,
        'is_owner': isOwner,
        'created_at': createdAt,
      };
}

/// A comment reply on a Loops video.
class LoopsCommentReply {
  final String id;
  final String videoId;
  final String parentId;
  final Map<String, dynamic>? account;
  final String content;
  final int likes;
  final bool hasLiked;
  final bool isEdited;
  final bool isHidden;
  final bool isOwner;
  final String? createdAt;

  LoopsCommentReply({
    required this.id,
    required this.videoId,
    required this.parentId,
    this.account,
    required this.content,
    this.likes = 0,
    this.hasLiked = false,
    this.isEdited = false,
    this.isHidden = false,
    this.isOwner = false,
    this.createdAt,
  });

  factory LoopsCommentReply.fromJson(Map<String, dynamic> json) {
    return LoopsCommentReply(
      id: json['id']?.toString() ?? '',
      videoId: json['video_id']?.toString() ?? json['v_id']?.toString() ?? '',
      parentId: json['parent_id']?.toString() ?? json['p_id']?.toString() ?? '',
      account: json['account'] as Map<String, dynamic>?,
      content: json['content'] as String? ?? json['caption'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      hasLiked: json['has_liked'] == true || json['liked'] == true,
      isEdited: json['is_edited'] == true,
      isHidden: json['is_hidden'] == true,
      isOwner: json['is_owner'] == true,
      createdAt: json['created_at'] as String?,
    );
  }
}

/// A Loops playlist.
class LoopsPlaylist {
  final String id;
  final String name;
  final String? description;
  final String visibility;
  final String? coverImage;
  final int videosCount;
  final String? createdAt;

  LoopsPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.visibility = 'public',
    this.coverImage,
    this.videosCount = 0,
    this.createdAt,
  });

  factory LoopsPlaylist.fromJson(Map<String, dynamic> json) {
    return LoopsPlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      visibility: json['visibility']?.toString() ?? 'public',
      coverImage: json['cover_image'] as String?,
      videosCount: json['videos_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Paginated response wrapper
// ---------------------------------------------------------------------------

/// Wraps a list of items with an optional cursor for pagination.
class LoopsPaginatedResponse<T> {
  final List<T> data;
  final String? nextCursor;

  LoopsPaginatedResponse({required this.data, this.nextCursor});
}

// ---------------------------------------------------------------------------
// API Client
// ---------------------------------------------------------------------------

/// Complete Loops API client covering ALL routes from loops-server routes/api.php.
///
/// Supports authentication via OAuth2 and provides typed methods for:
///   - Feeds: for-you, local, following, account, recommended (v0)
///   - Videos: CRUD, like/unlike, bookmark/unbookmark, likes, shares, history, tags
///   - Comments: CRUD, replies, like/unlike, hide/unhide, edit history
///   - Accounts: self, profile, follow/unfollow, block/unblock, followers/following/friends
///   - Notifications: list, count, mark read, system notifications
///   - Search: unified, users
///   - Explore: trending tags, tag feed
///   - Autocomplete: tags, accounts
///   - Studio: posts, playlist management, upload, duet upload
///   - Playlists: full CRUD + reorder
///   - Sounds: details, feed
///   - Settings: bio, avatar, password, 2FA, privacy, blocked accounts,
///     email, birthdate, push notifications, links, starter kits, account disable/delete
///   - User preferences
///   - Reports
///   - Starter kits (full CRUD + browse + membership + media)
///   - Account data / exports
///   - Intents
///   - Registration: invite-based, email-based
///   - Email verification
///   - Private media tokens
///   - App configuration, i18n, pages, contact info
class LoopsApi {
  final String instanceUrl;
  String? accessToken;
  final http.Client _client;

  LoopsApi({
    required this.instanceUrl,
    this.accessToken,
    http.Client? client,
  }) : _client = client ??
            IOClient(HttpClient()
              ..connectionTimeout = const Duration(seconds: 15)
              ..idleTimeout = const Duration(seconds: 15));

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 16) FediSpace/0.1.5',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Map<String, String> get _multipartHeaders => {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 16) FediSpace/0.1.5',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = instanceUrl.endsWith('/')
        ? instanceUrl.substring(0, instanceUrl.length - 1)
        : instanceUrl;
    return Uri.parse('$base$path').replace(queryParameters: queryParams);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    debugPrint('[LOOPS API] GET $path');
    final response = await _client
        .get(
          _uri(path, queryParams),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));
    debugPrint('[LOOPS API] GET $path -> ${response.statusCode}');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    debugPrint('[LOOPS API] POST $path');
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    debugPrint('[LOOPS API] POST $path -> ${response.statusCode}');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    debugPrint('[LOOPS API] PUT $path');
    final response = await _client.put(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    debugPrint('[LOOPS API] PUT $path -> ${response.statusCode}');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    debugPrint('[LOOPS API] DELETE $path');
    final response = await _client.delete(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    debugPrint('[LOOPS API] DELETE $path -> ${response.statusCode}');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _multipartPost(
    String path,
    http.MultipartRequest request,
  ) async {
    debugPrint('[LOOPS API] MULTIPART POST $path');
    request.headers.addAll(_multipartHeaders);
    final streamedResp = await _client.send(request);
    final response = await http.Response.fromStream(streamedResp);
    debugPrint('[LOOPS API] MULTIPART POST $path -> ${response.statusCode}');
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw LoopsApiException(
      response.statusCode,
      'Request failed: ${response.reasonPhrase}',
      body: response.body,
    );
  }

  List<LoopsVideo> _parseVideos(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data
          .map((e) => LoopsVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  LoopsPaginatedResponse<LoopsVideo> _parsePaginatedVideos(
    Map<String, dynamic> json,
  ) {
    return LoopsPaginatedResponse(
      data: _parseVideos(json),
      nextCursor: json['next_cursor']?.toString() ??
          json['meta']?['next_cursor']?.toString(),
    );
  }

  List<LoopsComment> _parseComments(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data
          .map((e) => LoopsComment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  List<LoopsCommentReply> _parseReplies(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data
          .map((e) => LoopsCommentReply.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // =========================================================================
  // 1. AUTH / OAUTH
  // =========================================================================

  /// POST /api/v1/apps -- Register an OAuth2 application.
  Future<Map<String, dynamic>> registerApp({
    required String clientName,
    required String redirectUri,
    String scopes = 'read write',
  }) async {
    debugPrint('[LOOPS API] registerApp: starting request');
    return _post('/api/v1/apps', body: {
      'client_name': clientName,
      'redirect_uris': redirectUri,
      'scopes': scopes,
    });
  }

  /// Build the authorization URL the user should visit to grant access.
  String getAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    String scopes = 'read write',
  }) {
    debugPrint('[LOOPS API] getAuthorizationUrl: building URL');
    final base = instanceUrl.endsWith('/')
        ? instanceUrl.substring(0, instanceUrl.length - 1)
        : instanceUrl;
    final params = Uri(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes,
    }).query;
    return '$base/oauth/authorize?$params';
  }

  /// POST /oauth/token -- Exchange an authorization code for an access token.
  Future<Map<String, dynamic>> exchangeToken({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    debugPrint('[LOOPS API] exchangeToken: starting request');
    return _post('/oauth/token', body: {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
    });
  }

  /// POST /oauth/token -- Refresh an access token.
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    required String clientId,
    required String clientSecret,
  }) async {
    debugPrint('[LOOPS API] refreshToken: starting request');
    return _post('/oauth/token', body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
      'client_secret': clientSecret,
    });
  }

  /// POST /api/v1/auth/2fa/verify
  Future<Map<String, dynamic>> verifyTwoFactor(String otpCode) async {
    debugPrint('[LOOPS API] verifyTwoFactor: starting request');
    return _post('/api/v1/auth/2fa/verify', body: {'otp_code': otpCode});
  }

  /// POST /auth/start -- Auth start fallback.
  Future<Map<String, dynamic>> authStart(Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] authStart: starting request');
    return _post('/auth/start', body: body);
  }

  // =========================================================================
  // 2. APP CONFIGURATION
  // =========================================================================

  /// GET /api/v1/config -- Instance configuration.
  Future<Map<String, dynamic>> getConfig() async {
    debugPrint('[LOOPS API] getConfig: starting request');
    return _get('/api/v1/config');
  }

  /// GET /api/v1/i18n/list -- Available languages.
  Future<Map<String, dynamic>> getLanguagesList() async {
    debugPrint('[LOOPS API] getLanguagesList: starting request');
    return _get('/api/v1/i18n/list');
  }

  /// GET /api/v1/platform/contact -- Contact info.
  Future<Map<String, dynamic>> getContactInfo() async {
    debugPrint('[LOOPS API] getContactInfo: starting request');
    return _get('/api/v1/platform/contact');
  }

  /// GET /api/v1/page/content -- Static page content.
  Future<Map<String, dynamic>> getPageContent({required String slug}) async {
    debugPrint('[LOOPS API] getPageContent: starting request for slug=$slug');
    return _get('/api/v1/page/content', queryParams: {'slug': slug});
  }

  /// GET /api/v1/web/report-rules -- Report types/rules.
  Future<Map<String, dynamic>> getReportRules() async {
    debugPrint('[LOOPS API] getReportRules: starting request');
    return _get('/api/v1/web/report-rules');
  }

  // =========================================================================
  // 3. FEEDS
  // =========================================================================

  /// GET /api/v0/user/self -- Self account info (v0 legacy).
  Future<Map<String, dynamic>> getSelfV0() async {
    debugPrint('[LOOPS API] getSelfV0: starting request');
    return _get('/api/v0/user/self');
  }

  /// GET /api/v1/feed/for-you
  Future<LoopsPaginatedResponse<LoopsVideo>> getForYouFeed({
    int? limit,
    String? cursor,
  }) async {
    debugPrint('[LOOPS API] getForYouFeed: starting request');
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/for-you', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v1/feed/local
  Future<LoopsPaginatedResponse<LoopsVideo>> getLocalFeed({
    int? limit,
    String? cursor,
  }) async {
    debugPrint('[LOOPS API] getLocalFeed: starting request');
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/local', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v1/feed/following
  Future<LoopsPaginatedResponse<LoopsVideo>> getFollowingFeed({
    int? limit,
    String? cursor,
  }) async {
    debugPrint('[LOOPS API] getFollowingFeed: starting request');
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/following', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/web/feed -- Public feed (no auth).
  Future<List<LoopsVideo>> getPublicFeed() async {
    debugPrint('[LOOPS API] getPublicFeed: starting request');
    final json = await _get('/api/web/feed');
    return _parseVideos(json);
  }

  /// GET /api/v0/feed/for-you -- v0 legacy for-you feed.
  Future<LoopsPaginatedResponse<LoopsVideo>> getForYouFeedV0({
    int? limit,
    String? cursor,
  }) async {
    debugPrint('[LOOPS API] getForYouFeedV0: starting request');
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v0/feed/for-you', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v1/feed/account/{id}
  Future<LoopsPaginatedResponse<LoopsVideo>> getUserFeed(
    String userId, {
    String? cursor,
    String sort = 'Latest',
  }) async {
    debugPrint('[LOOPS API] getUserFeed: starting request for id=$userId');
    final params = <String, String>{'sort': sort};
    if (cursor != null) params['cursor'] = cursor;
    final json =
        await _get('/api/v1/feed/account/$userId', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v1/feed/account/self
  Future<LoopsPaginatedResponse<LoopsVideo>> getSelfFeed({
    String sort = 'Latest',
    int? limit,
    String? cursor,
  }) async {
    debugPrint('[LOOPS API] getSelfFeed: starting request');
    final params = <String, String>{'sort': sort};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/account/self', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v1/feed/account/{id}/cursor
  Future<LoopsPaginatedResponse<LoopsVideo>> getAccountFeedWithCursor(
    String profileId, {
    required int videoId,
    int limit = 10,
  }) async {
    debugPrint(
        '[LOOPS API] getAccountFeedWithCursor: starting request for id=$profileId');
    final params = <String, String>{
      'id': videoId.toString(),
      'limit': limit.toString(),
    };
    final json = await _get('/api/v1/feed/account/$profileId/cursor',
        queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v0/feed/recommended
  Future<Map<String, dynamic>> getRecommendedFeed({
    String? cursor,
    int limit = 20,
  }) async {
    debugPrint('[LOOPS API] getRecommendedFeed: starting request');
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v0/feed/recommended', queryParams: params);
  }

  /// POST /api/v0/feed/recommended/impression
  Future<Map<String, dynamic>> recordFeedImpression({
    required int videoId,
    required int watchDuration,
    bool completed = false,
  }) async {
    debugPrint(
        '[LOOPS API] recordFeedImpression: starting request for videoId=$videoId');
    return _post('/api/v0/feed/recommended/impression', body: {
      'video_id': videoId,
      'watch_duration': watchDuration,
      'completed': completed,
    });
  }

  /// POST /api/v0/feed/recommended/feedback
  Future<Map<String, dynamic>> recordFeedFeedback({
    required int videoId,
    required String feedbackType,
  }) async {
    debugPrint(
        '[LOOPS API] recordFeedFeedback: starting request for videoId=$videoId');
    return _post('/api/v0/feed/recommended/feedback', body: {
      'video_id': videoId,
      'feedback_type': feedbackType,
    });
  }

  /// DELETE /api/v0/feed/recommended/feedback/{videoId}
  Future<Map<String, dynamic>> removeFeedFeedback(int videoId) async {
    debugPrint(
        '[LOOPS API] removeFeedFeedback: starting request for videoId=$videoId');
    return _delete('/api/v0/feed/recommended/feedback/$videoId');
  }

  // =========================================================================
  // 4. VIDEOS
  // =========================================================================

  /// GET /api/v1/video/{id}
  Future<LoopsVideo> getVideo(String id) async {
    debugPrint('[LOOPS API] getVideo: starting request for id=$id');
    final json = await _get('/api/v1/video/$id');
    return LoopsVideo.fromJson(json['data'] ?? json);
  }

  /// POST /api/v1/video/edit/{id}
  Future<Map<String, dynamic>> editVideo(
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
    debugPrint('[LOOPS API] editVideo: starting request for id=$id');
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
    return _post('/api/v1/video/edit/$id', body: body);
  }

  /// POST /api/v1/video/like/{id}
  Future<Map<String, dynamic>> likeVideo(String id) async {
    debugPrint('[LOOPS API] likeVideo: starting request for id=$id');
    return _post('/api/v1/video/like/$id');
  }

  /// POST /api/v1/video/unlike/{id}
  Future<Map<String, dynamic>> unlikeVideo(String id) async {
    debugPrint('[LOOPS API] unlikeVideo: starting request for id=$id');
    return _post('/api/v1/video/unlike/$id');
  }

  /// POST /api/v1/video/bookmark/{id}
  Future<Map<String, dynamic>> bookmarkVideo(String id) async {
    debugPrint('[LOOPS API] bookmarkVideo: starting request for id=$id');
    return _post('/api/v1/video/bookmark/$id');
  }

  /// POST /api/v1/video/unbookmark/{id}
  Future<Map<String, dynamic>> unbookmarkVideo(String id) async {
    debugPrint('[LOOPS API] unbookmarkVideo: starting request for id=$id');
    return _post('/api/v1/video/unbookmark/$id');
  }

  /// POST /api/v1/video/delete/{id}
  Future<Map<String, dynamic>> deleteVideo(String id) async {
    debugPrint('[LOOPS API] deleteVideo: starting request for id=$id');
    return _post('/api/v1/video/delete/$id');
  }

  /// GET /api/v1/video/likes/{id}
  Future<Map<String, dynamic>> getVideoLikes(String id) async {
    debugPrint('[LOOPS API] getVideoLikes: starting request for id=$id');
    return _get('/api/v1/video/likes/$id');
  }

  /// GET /api/v1/video/shares/{id}
  Future<Map<String, dynamic>> getVideoShares(String id) async {
    debugPrint('[LOOPS API] getVideoShares: starting request for id=$id');
    return _get('/api/v1/video/shares/$id');
  }

  /// GET /api/v1/video/history/{id}
  Future<Map<String, dynamic>> getVideoHistory(String id,
      {String? cursor}) async {
    debugPrint('[LOOPS API] getVideoHistory: starting request for id=$id');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/video/history/$id',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/tags/video/{id}
  Future<Map<String, dynamic>> getVideoTags(String id) async {
    debugPrint('[LOOPS API] getVideoTags: starting request for id=$id');
    return _get('/api/v1/tags/video/$id');
  }

  /// POST /api/v1/studio/upload -- Upload a new video (multipart).
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
    debugPrint('[LOOPS API] uploadVideo: starting multipart upload');
    final request =
        http.MultipartRequest('POST', _uri('/api/v1/studio/upload'));
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
    return _multipartPost('/api/v1/studio/upload', request);
  }

  /// POST /api/v1/studio/duet/upload -- Upload a duet video (multipart).
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
    debugPrint(
        '[LOOPS API] uploadDuet: starting multipart upload for duetId=$duetId');
    final request =
        http.MultipartRequest('POST', _uri('/api/v1/studio/duet/upload'));
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
    return _multipartPost('/api/v1/studio/duet/upload', request);
  }

  // =========================================================================
  // 5. COMMENTS
  // =========================================================================

  /// GET /api/v1/video/comments/{id} -- Get comments on a video.
  Future<List<LoopsComment>> getVideoComments(String id,
      {String? cursor}) async {
    debugPrint('[LOOPS API] getVideoComments: starting request for id=$id');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/video/comments/$id',
        queryParams: params.isNotEmpty ? params : null);
    return _parseComments(json);
  }

  /// GET /api/v1/video/comments/{vid}/replies -- Comment thread replies.
  Future<List<LoopsCommentReply>> getCommentReplies(
    String videoId, {
    required String commentId,
    String? cursor,
  }) async {
    debugPrint(
        '[LOOPS API] getCommentReplies: starting request for videoId=$videoId commentId=$commentId');
    final params = <String, String>{'cr': commentId};
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/video/comments/$videoId/replies',
        queryParams: params);
    return _parseReplies(json);
  }

  /// GET /api/v1/video/comments/{vid}/hidden -- Hidden comments (owner only).
  Future<List<LoopsComment>> getHiddenComments(String videoId,
      {String? cursor}) async {
    debugPrint(
        '[LOOPS API] getHiddenComments: starting request for videoId=$videoId');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/video/comments/$videoId/hidden',
        queryParams: params.isNotEmpty ? params : null);
    return _parseComments(json);
  }

  /// GET /api/v1/video/comments/{videoId}/comment/{commentId}
  Future<Map<String, dynamic>> getCommentById(
      String videoId, String commentId) async {
    debugPrint('[LOOPS API] getCommentById: starting request');
    return _get('/api/v1/video/comments/$videoId/comment/$commentId');
  }

  /// GET /api/v1/video/comments/{videoId}/reply/{replyId}
  Future<Map<String, dynamic>> getReplyById(
      String videoId, String replyId) async {
    debugPrint('[LOOPS API] getReplyById: starting request');
    return _get('/api/v1/video/comments/$videoId/reply/$replyId');
  }

  /// POST /api/v1/video/comments/{id} -- Post a comment.
  Future<Map<String, dynamic>> postComment(String videoId, String text,
      {String? parentId}) async {
    debugPrint(
        '[LOOPS API] postComment: starting request for videoId=$videoId');
    final body = <String, dynamic>{'comment': text};
    if (parentId != null) body['parent_id'] = parentId;
    return _post('/api/v1/video/comments/$videoId', body: body);
  }

  /// POST /api/v1/video/comments/edit/{id}
  Future<Map<String, dynamic>> editComment(
    String id, {
    required String commentId,
    required String comment,
  }) async {
    debugPrint('[LOOPS API] editComment: starting request for id=$id');
    return _post('/api/v1/video/comments/edit/$id',
        body: {'id': commentId, 'comment': comment});
  }

  /// POST /api/v1/video/comments/reply/edit/{id}
  Future<Map<String, dynamic>> editCommentReply(
    String id, {
    required String replyId,
    required String comment,
  }) async {
    debugPrint('[LOOPS API] editCommentReply: starting request for id=$id');
    return _post('/api/v1/video/comments/reply/edit/$id',
        body: {'id': replyId, 'comment': comment});
  }

  /// POST /api/v1/comments/like/{vid}/{id}
  Future<Map<String, dynamic>> likeComment(
      String videoId, String commentId) async {
    debugPrint('[LOOPS API] likeComment: starting request');
    return _post('/api/v1/comments/like/$videoId/$commentId');
  }

  /// POST /api/v1/comments/unlike/{vid}/{id}
  Future<Map<String, dynamic>> unlikeComment(
      String videoId, String commentId) async {
    debugPrint('[LOOPS API] unlikeComment: starting request');
    return _post('/api/v1/comments/unlike/$videoId/$commentId');
  }

  /// POST /api/v1/comments/like/{vid}/{pid}/{id} -- Like a reply.
  Future<Map<String, dynamic>> likeCommentReply(
      String videoId, String parentId, String replyId) async {
    debugPrint('[LOOPS API] likeCommentReply: starting request');
    return _post('/api/v1/comments/like/$videoId/$parentId/$replyId');
  }

  /// POST /api/v1/comments/unlike/{vid}/{pid}/{id} -- Unlike a reply.
  Future<Map<String, dynamic>> unlikeCommentReply(
      String videoId, String parentId, String replyId) async {
    debugPrint('[LOOPS API] unlikeCommentReply: starting request');
    return _post('/api/v1/comments/unlike/$videoId/$parentId/$replyId');
  }

  /// POST /api/v1/comments/delete/{vid}/{id}
  Future<Map<String, dynamic>> deleteComment(
      String videoId, String commentId) async {
    debugPrint('[LOOPS API] deleteComment: starting request');
    return _post('/api/v1/comments/delete/$videoId/$commentId');
  }

  /// POST /api/v1/comments/delete/{vid}/{pid}/{id} -- Delete a reply.
  Future<Map<String, dynamic>> deleteCommentReply(
      String videoId, String parentId, String replyId) async {
    debugPrint('[LOOPS API] deleteCommentReply: starting request');
    return _post('/api/v1/comments/delete/$videoId/$parentId/$replyId');
  }

  /// POST /api/v1/comments/hide/{vid}/{id}
  Future<Map<String, dynamic>> hideComment(
      String videoId, String commentId) async {
    debugPrint('[LOOPS API] hideComment: starting request');
    return _post('/api/v1/comments/hide/$videoId/$commentId');
  }

  /// POST /api/v1/comments/hide/{vid}/{pid}/{id}
  Future<Map<String, dynamic>> hideCommentReply(
      String videoId, String parentId, String replyId) async {
    debugPrint('[LOOPS API] hideCommentReply: starting request');
    return _post('/api/v1/comments/hide/$videoId/$parentId/$replyId');
  }

  /// POST /api/v1/comments/unhide/{vid}/{id}
  Future<Map<String, dynamic>> unhideComment(
      String videoId, String commentId) async {
    debugPrint('[LOOPS API] unhideComment: starting request');
    return _post('/api/v1/comments/unhide/$videoId/$commentId');
  }

  /// GET /api/v1/comments/history/{vid}/{cid}
  Future<Map<String, dynamic>> getCommentHistory(
      String videoId, String commentId,
      {String? cursor}) async {
    debugPrint('[LOOPS API] getCommentHistory: starting request');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/comments/history/$videoId/$commentId',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/comments/history/{vid}/{cid}/{id}
  Future<Map<String, dynamic>> getCommentReplyHistory(
      String videoId, String commentId, String replyId,
      {String? cursor}) async {
    debugPrint('[LOOPS API] getCommentReplyHistory: starting request');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/comments/history/$videoId/$commentId/$replyId',
        queryParams: params.isNotEmpty ? params : null);
  }

  // =========================================================================
  // 6. ACCOUNTS
  // =========================================================================

  /// GET /api/v1/account/info/self
  Future<LoopsProfile> getSelf() async {
    debugPrint('[LOOPS API] getSelf: starting request');
    final json = await _get('/api/v1/account/info/self');
    return LoopsProfile.fromJson(json['data'] ?? json);
  }

  /// GET /api/v1/account/info/{id}
  Future<LoopsProfile> getAccount(String id) async {
    debugPrint('[LOOPS API] getAccount: starting request for id=$id');
    final json = await _get('/api/v1/account/info/$id');
    return LoopsProfile.fromJson(json['data'] ?? json);
  }

  /// GET /api/v1/account/username/{id} -- Get account by username (public).
  Future<Map<String, dynamic>> getAccountByUsername(String username) async {
    debugPrint(
        '[LOOPS API] getAccountByUsername: starting request for username=$username');
    return _get('/api/v1/account/username/$username');
  }

  /// GET /api/v1/account/state/{id}
  Future<Map<String, dynamic>> getRelationship(String id) async {
    debugPrint('[LOOPS API] getRelationship: starting request for id=$id');
    return _get('/api/v1/account/state/$id');
  }

  /// POST /api/v1/account/follow/{id}
  Future<Map<String, dynamic>> followAccount(String id) async {
    debugPrint('[LOOPS API] followAccount: starting request for id=$id');
    return _post('/api/v1/account/follow/$id');
  }

  /// POST /api/v1/account/unfollow/{id}
  Future<Map<String, dynamic>> unfollowAccount(String id) async {
    debugPrint('[LOOPS API] unfollowAccount: starting request for id=$id');
    return _post('/api/v1/account/unfollow/$id');
  }

  /// POST /api/v1/account/undo-follow-request/{id}
  Future<Map<String, dynamic>> undoFollowRequest(String id) async {
    debugPrint('[LOOPS API] undoFollowRequest: starting request for id=$id');
    return _post('/api/v1/account/undo-follow-request/$id');
  }

  /// POST /api/v1/account/block/{id}
  Future<Map<String, dynamic>> blockAccount(String id) async {
    debugPrint('[LOOPS API] blockAccount: starting request for id=$id');
    return _post('/api/v1/account/block/$id');
  }

  /// POST /api/v1/account/unblock/{id}
  Future<Map<String, dynamic>> unblockAccount(String id) async {
    debugPrint('[LOOPS API] unblockAccount: starting request for id=$id');
    return _post('/api/v1/account/unblock/$id');
  }

  /// GET /api/v1/account/followers/{id}
  Future<Map<String, dynamic>> getFollowers(String id,
      {String? cursor, String? search}) async {
    debugPrint('[LOOPS API] getFollowers: starting request for id=$id');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    return _get('/api/v1/account/followers/$id',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/account/following/{id}
  Future<Map<String, dynamic>> getFollowing(String id,
      {String? cursor, String? search}) async {
    debugPrint('[LOOPS API] getFollowing: starting request for id=$id');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    return _get('/api/v1/account/following/$id',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/account/friends/{id}
  Future<Map<String, dynamic>> getAccountFriends(String id,
      {String? cursor, String? search}) async {
    debugPrint('[LOOPS API] getAccountFriends: starting request for id=$id');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    return _get('/api/v1/account/friends/$id',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/account/suggested/{id}
  Future<Map<String, dynamic>> getAccountSuggestedFollows(String id) async {
    debugPrint(
        '[LOOPS API] getAccountSuggestedFollows: starting request for id=$id');
    return _get('/api/v1/account/suggested/$id');
  }

  /// GET /api/v1/accounts/suggested
  Future<Map<String, dynamic>> getSuggestedAccounts() async {
    debugPrint('[LOOPS API] getSuggestedAccounts: starting request');
    return _get('/api/v1/accounts/suggested');
  }

  /// POST /api/v1/accounts/suggested/hide
  Future<Map<String, dynamic>> hideSuggestion(String profileId) async {
    debugPrint(
        '[LOOPS API] hideSuggestion: starting request for profileId=$profileId');
    return _post('/api/v1/accounts/suggested/hide',
        body: {'profile_id': profileId});
  }

  /// POST /api/v1/accounts/suggested/unhide
  Future<Map<String, dynamic>> unhideSuggestion(String profileId) async {
    debugPrint(
        '[LOOPS API] unhideSuggestion: starting request for profileId=$profileId');
    return _post('/api/v1/accounts/suggested/unhide',
        body: {'profile_id': profileId});
  }

  /// GET /api/v1/account/videos/likes
  Future<Map<String, dynamic>> getAccountVideoLikes({String? cursor}) async {
    debugPrint('[LOOPS API] getAccountVideoLikes: starting request');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/account/videos/likes',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/account/favourites -- Bookmarked videos.
  Future<Map<String, dynamic>> getBookmarks(
      {String sort = 'latest', int limit = 12, String? cursor}) async {
    debugPrint('[LOOPS API] getBookmarks: starting request');
    final params = <String, String>{'sort': sort, 'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/account/favourites', queryParams: params);
  }

  /// GET /api/v1/web/account/followers/{id}
  Future<Map<String, dynamic>> getPublicAccountFollowers(String id) async {
    debugPrint(
        '[LOOPS API] getPublicAccountFollowers: starting request for id=$id');
    return _get('/api/v1/web/account/followers/$id');
  }

  /// GET /api/v1/web/account/following/{id}
  Future<Map<String, dynamic>> getPublicAccountFollowing(String id) async {
    debugPrint(
        '[LOOPS API] getPublicAccountFollowing: starting request for id=$id');
    return _get('/api/v1/web/account/following/$id');
  }

  // =========================================================================
  // 7. NOTIFICATIONS
  // =========================================================================

  /// GET /api/v1/account/notifications
  Future<Map<String, dynamic>> getNotifications({String? cursor}) async {
    debugPrint('[LOOPS API] getNotifications: starting request');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/account/notifications',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// GET /api/v1/account/notifications/count
  Future<int> getUnreadCount() async {
    debugPrint('[LOOPS API] getUnreadCount: starting request');
    final json = await _get('/api/v1/account/notifications/count');
    return json['count'] as int? ?? 0;
  }

  /// POST /api/v1/account/notifications/{id}/read
  Future<Map<String, dynamic>> markRead(String id) async {
    debugPrint('[LOOPS API] markRead: starting request for id=$id');
    return _post('/api/v1/account/notifications/$id/read');
  }

  /// POST /api/v1/account/notifications/mark-all-read
  Future<Map<String, dynamic>> markAllRead() async {
    debugPrint('[LOOPS API] markAllRead: starting request');
    return _post('/api/v1/account/notifications/mark-all-read');
  }

  /// GET /api/v1/account/notifications/system/{id}
  Future<Map<String, dynamic>> getSystemNotification(String id) async {
    debugPrint(
        '[LOOPS API] getSystemNotification: starting request for id=$id');
    return _get('/api/v1/account/notifications/system/$id');
  }

  /// GET /api/v1/notifications/system/{id} -- Public system notification.
  Future<Map<String, dynamic>> getPublicSystemNotification(String id) async {
    debugPrint(
        '[LOOPS API] getPublicSystemNotification: starting request for id=$id');
    return _get('/api/v1/notifications/system/$id');
  }

  // =========================================================================
  // 8. SEARCH
  // =========================================================================

  /// GET /api/v1/search
  Future<Map<String, dynamic>> search(String query,
      {String? type, int? limit, String? cursor}) async {
    debugPrint('[LOOPS API] search: starting request for query=$query');
    final params = <String, String>{'q': query};
    if (type != null) params['type'] = type;
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/search', queryParams: params);
  }

  /// POST /api/v1/search/users
  Future<Map<String, dynamic>> searchUsers(String query) async {
    debugPrint('[LOOPS API] searchUsers: starting request for query=$query');
    return _post('/api/v1/search/users', body: {'q': query});
  }

  // =========================================================================
  // 9. EXPLORE
  // =========================================================================

  /// GET /api/v1/explore/tags
  Future<Map<String, dynamic>> getTrendingTags() async {
    debugPrint('[LOOPS API] getTrendingTags: starting request');
    return _get('/api/v1/explore/tags');
  }

  /// GET /api/v1/explore/tag-feed/{id}
  Future<LoopsPaginatedResponse<LoopsVideo>> getTagFeed(String tagId,
      {String? cursor, int? limit}) async {
    debugPrint('[LOOPS API] getTagFeed: starting request for tagId=$tagId');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    final json = await _get('/api/v1/explore/tag-feed/$tagId',
        queryParams: params.isNotEmpty ? params : null);
    return _parsePaginatedVideos(json);
  }

  /// GET /api/v1/tags/video/{name}
  Future<LoopsPaginatedResponse<LoopsVideo>> getVideoTagFeed(String tagName,
      {String? cursor, int? limit}) async {
    debugPrint(
        '[LOOPS API] getVideoTagFeed: starting request for tag=$tagName');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    final json = await _get('/api/v1/tags/video/$tagName',
        queryParams: params.isNotEmpty ? params : null);
    return _parsePaginatedVideos(json);
  }

  // =========================================================================
  // 10. AUTOCOMPLETE
  // =========================================================================

  /// GET /api/v1/autocomplete/tags
  Future<Map<String, dynamic>> autocompleteTags(String query) async {
    debugPrint(
        '[LOOPS API] autocompleteTags: starting request for query=$query');
    return _get('/api/v1/autocomplete/tags', queryParams: {'q': query});
  }

  /// GET /api/v1/autocomplete/accounts
  Future<Map<String, dynamic>> autocompleteAccounts(String query) async {
    debugPrint(
        '[LOOPS API] autocompleteAccounts: starting request for query=$query');
    return _get('/api/v1/autocomplete/accounts', queryParams: {'q': query});
  }

  // =========================================================================
  // 11. SOUNDS
  // =========================================================================

  /// GET /api/v1/sounds/details/{id}
  Future<Map<String, dynamic>> getSoundDetails(String id) async {
    debugPrint('[LOOPS API] getSoundDetails: starting request for id=$id');
    return _get('/api/v1/sounds/details/$id');
  }

  /// GET /api/v1/sounds/feed/{id}
  Future<LoopsPaginatedResponse<LoopsVideo>> getSoundFeed(String id,
      {required String key, String? cursor}) async {
    debugPrint('[LOOPS API] getSoundFeed: starting request for id=$id');
    final params = <String, String>{'key': key};
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/sounds/feed/$id', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  // =========================================================================
  // 12. STUDIO
  // =========================================================================

  /// GET /api/v1/studio/posts
  Future<Map<String, dynamic>> getStudioPosts(
      {String? search, int limit = 10, String? cursor}) async {
    debugPrint('[LOOPS API] getStudioPosts: starting request');
    final params = <String, String>{'limit': limit.toString()};
    if (search != null) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/studio/posts', queryParams: params);
  }

  /// GET /api/v1/studio/playlist-posts
  Future<Map<String, dynamic>> getStudioPlaylistPosts(
      {String? search, int limit = 10, String? cursor}) async {
    debugPrint('[LOOPS API] getStudioPlaylistPosts: starting request');
    final params = <String, String>{'limit': limit.toString()};
    if (search != null) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/studio/playlist-posts', queryParams: params);
  }

  // =========================================================================
  // 13. PLAYLISTS
  // =========================================================================

  /// GET /api/v1/studio/playlists
  Future<Map<String, dynamic>> getPlaylists(
      {String? search, int limit = 10, String? cursor}) async {
    debugPrint('[LOOPS API] getPlaylists: starting request');
    final params = <String, String>{'limit': limit.toString()};
    if (search != null) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/studio/playlists', queryParams: params);
  }

  /// POST /api/v1/studio/playlists
  Future<Map<String, dynamic>> createPlaylist(
      {required String name,
      String? description,
      String visibility = 'public'}) async {
    debugPrint('[LOOPS API] createPlaylist: starting request for name=$name');
    return _post('/api/v1/studio/playlists', body: {
      'name': name,
      if (description != null) 'description': description,
      'visibility': visibility,
    });
  }

  /// GET /api/v1/studio/playlists/{id}
  Future<Map<String, dynamic>> getPlaylist(String id) async {
    debugPrint('[LOOPS API] getPlaylist: starting request for id=$id');
    return _get('/api/v1/studio/playlists/$id');
  }

  /// PUT /api/v1/studio/playlists/{id}
  Future<Map<String, dynamic>> updatePlaylist(String id,
      {String? name, String? description, String? visibility}) async {
    debugPrint('[LOOPS API] updatePlaylist: starting request for id=$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (visibility != null) body['visibility'] = visibility;
    return _put('/api/v1/studio/playlists/$id', body: body);
  }

  /// DELETE /api/v1/studio/playlists/{id}
  Future<Map<String, dynamic>> deletePlaylist(String id) async {
    debugPrint('[LOOPS API] deletePlaylist: starting request for id=$id');
    return _delete('/api/v1/studio/playlists/$id');
  }

  /// GET /api/v1/studio/playlists/{id}/videos
  Future<Map<String, dynamic>> getPlaylistVideos(String playlistId,
      {int limit = 10, String? cursor}) async {
    debugPrint(
        '[LOOPS API] getPlaylistVideos: starting request for playlistId=$playlistId');
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/studio/playlists/$playlistId/videos',
        queryParams: params);
  }

  /// POST /api/v1/studio/playlists/{id}/videos
  Future<Map<String, dynamic>> addVideoToPlaylist(
      String playlistId, int videoId,
      {int? position}) async {
    debugPrint('[LOOPS API] addVideoToPlaylist: starting request');
    final body = <String, dynamic>{'video_id': videoId};
    if (position != null) body['position'] = position;
    return _post('/api/v1/studio/playlists/$playlistId/videos', body: body);
  }

  /// DELETE /api/v1/studio/playlists/{playlistId}/videos/{videoId}
  Future<Map<String, dynamic>> removeVideoFromPlaylist(
      String playlistId, String videoId) async {
    debugPrint('[LOOPS API] removeVideoFromPlaylist: starting request');
    return _delete('/api/v1/studio/playlists/$playlistId/videos/$videoId');
  }

  /// PUT /api/v1/studio/playlists/{id}/reorder
  Future<Map<String, dynamic>> reorderPlaylistVideos(
      String playlistId, List<int> videoIds) async {
    debugPrint('[LOOPS API] reorderPlaylistVideos: starting request');
    return _put('/api/v1/studio/playlists/$playlistId/reorder',
        body: {'video_ids': videoIds});
  }

  // =========================================================================
  // 14. SETTINGS
  // =========================================================================

  /// GET /api/v1/account/settings/privacy
  Future<Map<String, dynamic>> getPrivacySettings() async {
    debugPrint('[LOOPS API] getPrivacySettings: starting request');
    return _get('/api/v1/account/settings/privacy');
  }

  /// POST /api/v1/account/settings/privacy
  Future<Map<String, dynamic>> updatePrivacySettings(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] updatePrivacySettings: starting request');
    return _post('/api/v1/account/settings/privacy', body: body);
  }

  /// GET /api/v1/account/settings/birthdate
  Future<Map<String, dynamic>> checkBirthdate() async {
    debugPrint('[LOOPS API] checkBirthdate: starting request');
    return _get('/api/v1/account/settings/birthdate');
  }

  /// POST /api/v1/account/settings/birthdate
  Future<Map<String, dynamic>> setBirthdate(String birthDate) async {
    debugPrint('[LOOPS API] setBirthdate: starting request');
    return _post('/api/v1/account/settings/birthdate',
        body: {'birth_date': birthDate});
  }

  /// POST /api/v1/account/settings/bio
  Future<Map<String, dynamic>> updateBio({String? name, String? bio}) async {
    debugPrint('[LOOPS API] updateBio: starting request');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    return _post('/api/v1/account/settings/bio', body: body);
  }

  /// POST /api/v1/account/settings/update-avatar (multipart)
  Future<Map<String, dynamic>> updateAvatar(String filePath,
      {Map<String, dynamic>? coordinates}) async {
    debugPrint('[LOOPS API] updateAvatar: starting multipart upload');
    final request = http.MultipartRequest(
        'POST', _uri('/api/v1/account/settings/update-avatar'));
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    if (coordinates != null)
      request.fields['coordinates'] = jsonEncode(coordinates);
    return _multipartPost('/api/v1/account/settings/update-avatar', request);
  }

  /// POST /api/v1/account/settings/delete-avatar
  Future<Map<String, dynamic>> deleteAvatar() async {
    debugPrint('[LOOPS API] deleteAvatar: starting request');
    return _post('/api/v1/account/settings/delete-avatar');
  }

  /// GET /api/v1/account/settings/security-config
  Future<Map<String, dynamic>> getSecurityConfig() async {
    debugPrint('[LOOPS API] getSecurityConfig: starting request');
    return _get('/api/v1/account/settings/security-config');
  }

  /// POST /api/v1/account/settings/update-password
  Future<Map<String, dynamic>> updatePassword(
      String password, String passwordConfirmation) async {
    debugPrint('[LOOPS API] updatePassword: starting request');
    return _post('/api/v1/account/settings/update-password', body: {
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  /// POST /api/v1/account/settings/disable-2fa
  Future<Map<String, dynamic>> disableTwoFactor() async {
    debugPrint('[LOOPS API] disableTwoFactor: starting request');
    return _post('/api/v1/account/settings/disable-2fa');
  }

  /// POST /api/v1/account/settings/setup-2fa
  Future<Map<String, dynamic>> setupTwoFactor() async {
    debugPrint('[LOOPS API] setupTwoFactor: starting request');
    return _post('/api/v1/account/settings/setup-2fa');
  }

  /// POST /api/v1/account/settings/confirm-2fa
  Future<Map<String, dynamic>> confirmTwoFactor(String code) async {
    debugPrint('[LOOPS API] confirmTwoFactor: starting request');
    return _post('/api/v1/account/settings/confirm-2fa', body: {'code': code});
  }

  /// GET /api/v1/account/settings/total-blocked-accounts
  Future<Map<String, dynamic>> getTotalBlockedAccounts() async {
    debugPrint('[LOOPS API] getTotalBlockedAccounts: starting request');
    return _get('/api/v1/account/settings/total-blocked-accounts');
  }

  /// GET /api/v1/account/settings/blocked-accounts
  Future<Map<String, dynamic>> getBlockedAccounts(
      {String? cursor, String? search}) async {
    debugPrint('[LOOPS API] getBlockedAccounts: starting request');
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null) params['q'] = search;
    return _get('/api/v1/account/settings/blocked-accounts',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// POST /api/v1/account/settings/blocked-account-search
  Future<Map<String, dynamic>> searchBlockableAccounts(String query) async {
    debugPrint(
        '[LOOPS API] searchBlockableAccounts: starting request for query=$query');
    return _post('/api/v1/account/settings/blocked-account-search',
        body: {'q': query});
  }

  /// GET /api/v1/account/settings/email
  Future<Map<String, dynamic>> getEmailSettings() async {
    debugPrint('[LOOPS API] getEmailSettings: starting request');
    return _get('/api/v1/account/settings/email');
  }

  /// POST /api/v1/account/settings/email/update
  Future<Map<String, dynamic>> changeEmail(Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] changeEmail: starting request');
    return _post('/api/v1/account/settings/email/update', body: body);
  }

  /// POST /api/v1/account/settings/email/cancel
  Future<Map<String, dynamic>> cancelEmailChange() async {
    debugPrint('[LOOPS API] cancelEmailChange: starting request');
    return _post('/api/v1/account/settings/email/cancel');
  }

  /// POST /api/v1/account/settings/email/verify
  Future<Map<String, dynamic>> verifyEmailChange(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] verifyEmailChange: starting request');
    return _post('/api/v1/account/settings/email/verify', body: body);
  }

  /// POST /api/v1/account/settings/email/resend
  Future<Map<String, dynamic>> resendEmailVerification() async {
    debugPrint('[LOOPS API] resendEmailVerification: starting request');
    return _post('/api/v1/account/settings/email/resend');
  }

  /// POST /api/v1/account/settings/account/disable
  Future<Map<String, dynamic>> disableAccount(String password) async {
    debugPrint('[LOOPS API] disableAccount: starting request');
    return _post('/api/v1/account/settings/account/disable',
        body: {'password': password});
  }

  /// POST /api/v1/account/settings/account/delete
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    debugPrint('[LOOPS API] deleteAccount: starting request');
    return _post('/api/v1/account/settings/account/delete',
        body: {'password': password});
  }

  /// GET /api/v1/account/settings/links
  Future<Map<String, dynamic>> getProfileLinks() async {
    debugPrint('[LOOPS API] getProfileLinks: starting request');
    return _get('/api/v1/account/settings/links');
  }

  /// POST /api/v1/account/settings/links/add
  Future<Map<String, dynamic>> addProfileLink(
      {required String title, required String url}) async {
    debugPrint('[LOOPS API] addProfileLink: starting request');
    return _post('/api/v1/account/settings/links/add',
        body: {'title': title, 'url': url});
  }

  /// POST /api/v1/account/settings/links/delete/{id}
  Future<Map<String, dynamic>> removeProfileLink(String id) async {
    debugPrint('[LOOPS API] removeProfileLink: starting request for id=$id');
    return _post('/api/v1/account/settings/links/delete/$id');
  }

  /// GET /api/v1/account/settings/push-notifications/status
  Future<Map<String, dynamic>> getPushNotificationStatus() async {
    debugPrint('[LOOPS API] getPushNotificationStatus: starting request');
    return _get('/api/v1/account/settings/push-notifications/status');
  }

  /// POST /api/v1/account/settings/push-notifications/enable
  Future<Map<String, dynamic>> enablePushNotifications(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] enablePushNotifications: starting request');
    return _post('/api/v1/account/settings/push-notifications/enable',
        body: body);
  }

  /// POST /api/v1/account/settings/push-notifications/disable
  Future<Map<String, dynamic>> disablePushNotifications() async {
    debugPrint('[LOOPS API] disablePushNotifications: starting request');
    return _post('/api/v1/account/settings/push-notifications/disable');
  }

  /// GET /api/v1/account/settings/starter-kits/status
  Future<Map<String, dynamic>> getStarterKitsStatus() async {
    debugPrint('[LOOPS API] getStarterKitsStatus: starting request');
    return _get('/api/v1/account/settings/starter-kits/status');
  }

  /// POST /api/v1/account/settings/starter-kits/update
  Future<Map<String, dynamic>> updateStarterKitsStatus(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] updateStarterKitsStatus: starting request');
    return _post('/api/v1/account/settings/starter-kits/update', body: body);
  }

  // =========================================================================
  // 15. USER PREFERENCES
  // =========================================================================

  /// GET /api/v1/app/preferences
  Future<Map<String, dynamic>> getAppPreferences() async {
    debugPrint('[LOOPS API] getAppPreferences: starting request');
    return _get('/api/v1/app/preferences');
  }

  /// POST /api/v1/app/preferences
  Future<Map<String, dynamic>> updateAppPreferences(
      Map<String, dynamic> preferences) async {
    debugPrint('[LOOPS API] updateAppPreferences: starting request');
    return _post('/api/v1/app/preferences', body: preferences);
  }

  // =========================================================================
  // 16. REPORTS
  // =========================================================================

  /// POST /api/v1/report
  Future<Map<String, dynamic>> submitReport(
      {required String type,
      required String id,
      required String key,
      String? comment}) async {
    debugPrint(
        '[LOOPS API] submitReport: starting request for type=$type id=$id');
    final body = <String, dynamic>{'type': type, 'id': id, 'key': key};
    if (comment != null) body['comment'] = comment;
    return _post('/api/v1/report', body: body);
  }

  // =========================================================================
  // 17. STARTER KITS
  // =========================================================================

  /// POST /api/v1/starter-kits/create
  Future<Map<String, dynamic>> createStarterKit(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] createStarterKit: starting request');
    return _post('/api/v1/starter-kits/create', body: body);
  }

  /// GET /api/v1/starter-kits/my-kits
  Future<Map<String, dynamic>> getMyStarterKits() async {
    debugPrint('[LOOPS API] getMyStarterKits: starting request');
    return _get('/api/v1/starter-kits/my-kits');
  }

  /// GET /api/v1/starter-kits/joined-kits
  Future<Map<String, dynamic>> getJoinedStarterKits() async {
    debugPrint('[LOOPS API] getJoinedStarterKits: starting request');
    return _get('/api/v1/starter-kits/joined-kits');
  }

  /// GET /api/v1/starter-kits/details/{id}
  Future<Map<String, dynamic>> getStarterKit(String id) async {
    debugPrint('[LOOPS API] getStarterKit: starting request for id=$id');
    return _get('/api/v1/starter-kits/details/$id');
  }

  /// POST /api/v1/starter-kits/details/{id}
  Future<Map<String, dynamic>> updateStarterKit(
      String id, Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] updateStarterKit: starting request for id=$id');
    return _post('/api/v1/starter-kits/details/$id', body: body);
  }

  /// DELETE /api/v1/starter-kits/details/{id}
  Future<Map<String, dynamic>> deleteStarterKit(String id) async {
    debugPrint('[LOOPS API] deleteStarterKit: starting request for id=$id');
    return _delete('/api/v1/starter-kits/details/$id');
  }

  /// POST /api/v1/starter-kits/details/{id}/use
  Future<Map<String, dynamic>> useStarterKit(String id) async {
    debugPrint('[LOOPS API] useStarterKit: starting request for id=$id');
    return _post('/api/v1/starter-kits/details/$id/use');
  }

  /// POST /api/v1/starter-kits/details/{id}/reuse
  Future<Map<String, dynamic>> reuseStarterKit(String id) async {
    debugPrint('[LOOPS API] reuseStarterKit: starting request for id=$id');
    return _post('/api/v1/starter-kits/details/$id/reuse');
  }

  /// GET /api/v1/starter-kits/details/{id}/used
  Future<Map<String, dynamic>> hasUsedStarterKit(String id) async {
    debugPrint('[LOOPS API] hasUsedStarterKit: starting request for id=$id');
    return _get('/api/v1/starter-kits/details/$id/used');
  }

  /// GET /api/v1/starter-kits/details/{id}/accounts
  Future<Map<String, dynamic>> getStarterKitAccounts(String id) async {
    debugPrint(
        '[LOOPS API] getStarterKitAccounts: starting request for id=$id');
    return _get('/api/v1/starter-kits/details/$id/accounts');
  }

  /// DELETE /api/v1/starter-kits/details/{id}/accounts/{accountId}
  Future<Map<String, dynamic>> removeAccountFromStarterKit(
      String kitId, String accountId) async {
    debugPrint('[LOOPS API] removeAccountFromStarterKit: starting request');
    return _delete('/api/v1/starter-kits/details/$kitId/accounts/$accountId');
  }

  /// GET /api/v1/starter-kits/details/{id}/membership
  Future<Map<String, dynamic>> checkKitMembership(String id) async {
    debugPrint('[LOOPS API] checkKitMembership: starting request for id=$id');
    return _get('/api/v1/starter-kits/details/$id/membership');
  }

  /// POST /api/v1/starter-kits/details/{id}/membership
  Future<Map<String, dynamic>> handleKitMembership(
      String id, Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] handleKitMembership: starting request for id=$id');
    return _post('/api/v1/starter-kits/details/$id/membership', body: body);
  }

  /// POST /api/v1/starter-kits/details/{id}/membership/revoke
  Future<Map<String, dynamic>> revokeKitMembership(String id) async {
    debugPrint('[LOOPS API] revokeKitMembership: starting request for id=$id');
    return _post('/api/v1/starter-kits/details/$id/membership/revoke');
  }

  /// GET /api/v1/starter-kits/details/{id}/pending-changes
  Future<Map<String, dynamic>> getKitPendingChanges(String id) async {
    debugPrint('[LOOPS API] getKitPendingChanges: starting request for id=$id');
    return _get('/api/v1/starter-kits/details/$id/pending-changes');
  }

  /// POST /api/v1/starter-kits/details/{id}/accounts/add
  Future<Map<String, dynamic>> addAccountToStarterKit(
      String kitId, Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] addAccountToStarterKit: starting request');
    return _post('/api/v1/starter-kits/details/$kitId/accounts/add',
        body: body);
  }

  /// POST /api/v1/starter-kits/details/{id}/icon (multipart)
  Future<Map<String, dynamic>> uploadStarterKitIcon(
      String id, String filePath) async {
    debugPrint(
        '[LOOPS API] uploadStarterKitIcon: starting multipart upload for id=$id');
    final request = http.MultipartRequest(
        'POST', _uri('/api/v1/starter-kits/details/$id/icon'));
    request.files.add(await http.MultipartFile.fromPath('icon', filePath));
    return _multipartPost('/api/v1/starter-kits/details/$id/icon', request);
  }

  /// DELETE /api/v1/starter-kits/details/{id}/icon
  Future<Map<String, dynamic>> deleteStarterKitIcon(String id) async {
    debugPrint('[LOOPS API] deleteStarterKitIcon: starting request for id=$id');
    return _delete('/api/v1/starter-kits/details/$id/icon');
  }

  /// POST /api/v1/starter-kits/details/{id}/header (multipart)
  Future<Map<String, dynamic>> uploadStarterKitHeader(
      String id, String filePath) async {
    debugPrint(
        '[LOOPS API] uploadStarterKitHeader: starting multipart upload for id=$id');
    final request = http.MultipartRequest(
        'POST', _uri('/api/v1/starter-kits/details/$id/header'));
    request.files.add(await http.MultipartFile.fromPath('header', filePath));
    return _multipartPost('/api/v1/starter-kits/details/$id/header', request);
  }

  /// DELETE /api/v1/starter-kits/details/{id}/header
  Future<Map<String, dynamic>> deleteStarterKitHeader(String id) async {
    debugPrint(
        '[LOOPS API] deleteStarterKitHeader: starting request for id=$id');
    return _delete('/api/v1/starter-kits/details/$id/header');
  }

  /// POST /api/v1/starter-kits/compose/search/accounts
  Future<Map<String, dynamic>> searchStarterKitAccounts(String query) async {
    debugPrint('[LOOPS API] searchStarterKitAccounts: starting request');
    return _post('/api/v1/starter-kits/compose/search/accounts',
        body: {'q': query});
  }

  /// POST /api/v1/starter-kits/compose/search/hashtags
  Future<Map<String, dynamic>> searchStarterKitHashtags(String query) async {
    debugPrint('[LOOPS API] searchStarterKitHashtags: starting request');
    return _post('/api/v1/starter-kits/compose/search/hashtags',
        body: {'q': query});
  }

  /// POST /api/v1/starter-kits/edit/search/accounts/{id}
  Future<Map<String, dynamic>> searchStarterKitEditAccounts(
      String kitId, String query) async {
    debugPrint('[LOOPS API] searchStarterKitEditAccounts: starting request');
    return _post('/api/v1/starter-kits/edit/search/accounts/$kitId',
        body: {'q': query});
  }

  /// GET /api/v1/starter-kits/config
  Future<Map<String, dynamic>> getStarterKitsConfig() async {
    debugPrint('[LOOPS API] getStarterKitsConfig: starting request');
    return _get('/api/v1/starter-kits/config');
  }

  /// GET /api/v1/starter-kits/stats
  Future<Map<String, dynamic>> getStarterKitsStats() async {
    debugPrint('[LOOPS API] getStarterKitsStats: starting request');
    return _get('/api/v1/starter-kits/stats');
  }

  /// GET /api/v1/starter-kits/self/config
  Future<Map<String, dynamic>> getSelfStarterKitConfig() async {
    debugPrint('[LOOPS API] getSelfStarterKitConfig: starting request');
    return _get('/api/v1/starter-kits/self/config');
  }

  /// GET /api/v1/starter-kits/top-creators
  Future<Map<String, dynamic>> getStarterKitTopCreators() async {
    debugPrint('[LOOPS API] getStarterKitTopCreators: starting request');
    return _get('/api/v1/starter-kits/top-creators');
  }

  /// GET /api/v1/starter-kits/popular
  Future<Map<String, dynamic>> getPopularStarterKits() async {
    debugPrint('[LOOPS API] getPopularStarterKits: starting request');
    return _get('/api/v1/starter-kits/popular');
  }

  /// GET /api/v1/starter-kits/latest
  Future<Map<String, dynamic>> getLatestStarterKits() async {
    debugPrint('[LOOPS API] getLatestStarterKits: starting request');
    return _get('/api/v1/starter-kits/latest');
  }

  /// GET /api/v1/starter-kits/browse
  Future<Map<String, dynamic>> browseStarterKits(
      {String sort = 'popular',
      int limit = 6,
      String? tag,
      String? search,
      String? cursor}) async {
    debugPrint('[LOOPS API] browseStarterKits: starting request');
    final params = <String, String>{'sort': sort, 'limit': limit.toString()};
    if (tag != null) params['tag'] = tag;
    if (search != null) params['q'] = search;
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/starter-kits/browse', queryParams: params);
  }

  /// GET /api/v1/starter-kits/hashtag/popular
  Future<Map<String, dynamic>> getStarterKitPopularHashtags() async {
    debugPrint('[LOOPS API] getStarterKitPopularHashtags: starting request');
    return _get('/api/v1/starter-kits/hashtag/popular');
  }

  /// GET /api/v1/starter-kits/hashtag/kits
  Future<Map<String, dynamic>> getStarterKitsByHashtag(
      {required String tag, String sort = 'popular', String? cursor}) async {
    debugPrint(
        '[LOOPS API] getStarterKitsByHashtag: starting request for tag=$tag');
    final params = <String, String>{'tag': tag, 'sort': sort};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/starter-kits/hashtag/kits', queryParams: params);
  }

  // =========================================================================
  // 18. ACCOUNT DATA / EXPORTS
  // =========================================================================

  /// GET /api/v1/account/data/insights
  Future<Map<String, dynamic>> getDataInsights() async {
    debugPrint('[LOOPS API] getDataInsights: starting request');
    return _get('/api/v1/account/data/insights');
  }

  /// GET /api/v1/account/data/settings
  Future<Map<String, dynamic>> getDataSettings() async {
    debugPrint('[LOOPS API] getDataSettings: starting request');
    return _get('/api/v1/account/data/settings');
  }

  /// PUT /api/v1/account/data/settings
  Future<Map<String, dynamic>> updateDataSettings(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] updateDataSettings: starting request');
    return _put('/api/v1/account/data/settings', body: body);
  }

  /// POST /api/v1/account/data/export/full
  Future<Map<String, dynamic>> requestFullExport() async {
    debugPrint('[LOOPS API] requestFullExport: starting request');
    return _post('/api/v1/account/data/export/full');
  }

  /// POST /api/v1/account/data/export/selective
  Future<Map<String, dynamic>> requestSelectiveExport(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] requestSelectiveExport: starting request');
    return _post('/api/v1/account/data/export/selective', body: body);
  }

  /// GET /api/v1/account/data/export/history
  Future<Map<String, dynamic>> getExportHistory() async {
    debugPrint('[LOOPS API] getExportHistory: starting request');
    return _get('/api/v1/account/data/export/history');
  }

  /// GET /api/v1/account/data/export/{id}/download
  Future<Map<String, dynamic>> downloadExport(String id) async {
    debugPrint('[LOOPS API] downloadExport: starting request for id=$id');
    return _get('/api/v1/account/data/export/$id/download');
  }

  // =========================================================================
  // 19. INTENTS
  // =========================================================================

  /// POST /api/v1/intents/follow/account
  Future<Map<String, dynamic>> followIntent(Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] followIntent: starting request');
    return _post('/api/v1/intents/follow/account', body: body);
  }

  // =========================================================================
  // 20. REGISTRATION (invite-based)
  // =========================================================================

  /// POST /api/v1/invite/verify
  Future<Map<String, dynamic>> verifyInvite(Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] verifyInvite: starting request');
    return _post('/api/v1/invite/verify', body: body);
  }

  /// POST /api/v1/invite/check-username
  Future<Map<String, dynamic>> checkUsername(String username) async {
    debugPrint('[LOOPS API] checkUsername: starting request');
    return _post('/api/v1/invite/check-username', body: {'username': username});
  }

  /// POST /api/v1/invite/register
  Future<Map<String, dynamic>> registerViaInvite(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] registerViaInvite: starting request');
    return _post('/api/v1/invite/register', body: body);
  }

  /// POST /api/v1/invite/verify-age
  Future<Map<String, dynamic>> verifyAgeInvite(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] verifyAgeInvite: starting request');
    return _post('/api/v1/invite/verify-age', body: body);
  }

  // =========================================================================
  // 21. REGISTRATION (email-based)
  // =========================================================================

  /// POST /api/v1/auth/register/email
  Future<Map<String, dynamic>> registerSendEmail(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] registerSendEmail: starting request');
    return _post('/api/v1/auth/register/email', body: body);
  }

  /// POST /api/v1/auth/register/email/resend
  Future<Map<String, dynamic>> registerResendEmail(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] registerResendEmail: starting request');
    return _post('/api/v1/auth/register/email/resend', body: body);
  }

  /// POST /api/v1/auth/register/email/verify
  Future<Map<String, dynamic>> registerVerifyEmail(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] registerVerifyEmail: starting request');
    return _post('/api/v1/auth/register/email/verify', body: body);
  }

  /// POST /api/v1/auth/register/username
  Future<Map<String, dynamic>> registerClaimUsername(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] registerClaimUsername: starting request');
    return _post('/api/v1/auth/register/username', body: body);
  }

  /// POST /api/v1/auth/register/verify-age
  Future<Map<String, dynamic>> registerVerifyAge(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] registerVerifyAge: starting request');
    return _post('/api/v1/auth/register/verify-age', body: body);
  }

  // =========================================================================
  // 22. EMAIL VERIFICATION (existing accounts)
  // =========================================================================

  /// POST /api/v1/auth/verify/email
  Future<Map<String, dynamic>> initiateEmailVerification(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] initiateEmailVerification: starting request');
    return _post('/api/v1/auth/verify/email', body: body);
  }

  /// POST /api/v1/auth/verify/email/confirm
  Future<Map<String, dynamic>> confirmEmailVerification(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] confirmEmailVerification: starting request');
    return _post('/api/v1/auth/verify/email/confirm', body: body);
  }

  /// POST /api/v1/auth/verify/email/resend
  Future<Map<String, dynamic>> resendEmailVerificationExisting(
      Map<String, dynamic> body) async {
    debugPrint('[LOOPS API] resendEmailVerificationExisting: starting request');
    return _post('/api/v1/auth/verify/email/resend', body: body);
  }

  // =========================================================================
  // 23. PRIVATE MEDIA TOKENS
  // =========================================================================

  /// GET /api/v2026.3/pmt/{tokenId}
  Future<Map<String, dynamic>> getPrivateMediaToken(String tokenId) async {
    debugPrint(
        '[LOOPS API] getPrivateMediaToken: starting request for tokenId=$tokenId');
    return _get('/api/v2026.3/pmt/$tokenId');
  }

  // =========================================================================
  // Cleanup
  // =========================================================================

  /// Close the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
