// Loops API client for loops.video instances
//
// Provides typed models and API methods for interacting with
// Loops (loops.video) federated short video platform.
//
// Based on the Loops server API (routes/api.php).
//
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

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
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      videosCount: json['videos_count'] as int? ?? 0,
      isFollowing: json['is_following'] == true,
      isBlocked: json['is_blocked'] == true,
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
  final String? createdAt;

  LoopsComment({
    required this.id,
    required this.videoId,
    this.accountId,
    this.account,
    required this.content,
    this.likes = 0,
    this.hasLiked = false,
    this.createdAt,
  });

  factory LoopsComment.fromJson(Map<String, dynamic> json) {
    return LoopsComment(
      id: json['id']?.toString() ?? '',
      videoId: json['video_id']?.toString() ?? '',
      accountId: json['account_id']?.toString(),
      account: json['account'] as Map<String, dynamic>?,
      content: json['content'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      hasLiked: json['has_liked'] == true,
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
        'created_at': createdAt,
      };
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

/// Client for the Loops (loops.video) API.
///
/// Supports authentication via OAuth2 and provides typed methods
/// for feeds, videos, comments, accounts, search, explore,
/// notifications, and configuration.
class LoopsApi {
  final String instanceUrl;
  String? accessToken;
  final http.Client _client;

  LoopsApi({
    required this.instanceUrl,
    this.accessToken,
    http.Client? client,
  }) : _client = client ?? IOClient(HttpClient()
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
    final response = await _client.get(
      _uri(path, queryParams),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }


  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Wrap arrays in a data key for consistency
      return {'data': decoded};
    }
    throw LoopsApiException(
      response.statusCode,
      'Request failed: ${response.reasonPhrase}',
      body: response.body,
    );
  }

  // Helper to extract a list of videos from a response
  List<LoopsVideo> _parseVideos(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data
          .map((e) => LoopsVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Helper to extract paginated videos
  LoopsPaginatedResponse<LoopsVideo> _parsePaginatedVideos(
    Map<String, dynamic> json,
  ) {
    return LoopsPaginatedResponse(
      data: _parseVideos(json),
      nextCursor: json['next_cursor']?.toString() ??
          json['meta']?['next_cursor']?.toString(),
    );
  }

  // -------------------------------------------------------------------------
  // AUTH — OAuth2 app registration and token exchange
  // -------------------------------------------------------------------------

  /// Register an OAuth2 application.
  /// POST /api/v1/apps
  Future<Map<String, dynamic>> registerApp({
    required String clientName,
    required String redirectUri,
    String scopes = 'read write',
  }) async {
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

  /// Exchange an authorization code for an access token.
  /// POST /oauth/token
  Future<Map<String, dynamic>> exchangeToken({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    return _post('/oauth/token', body: {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
    });
  }

  // -------------------------------------------------------------------------
  // FEEDS
  // -------------------------------------------------------------------------

  /// Get the "For You" feed.
  /// GET /api/v1/feed/for-you
  Future<LoopsPaginatedResponse<LoopsVideo>> getForYouFeed({
    int? limit,
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/for-you', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// Get the local feed.
  /// GET /api/v1/feed/local
  Future<LoopsPaginatedResponse<LoopsVideo>> getLocalFeed({
    int? limit,
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/local', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// Get the following feed.
  /// GET /api/v1/feed/following
  Future<LoopsPaginatedResponse<LoopsVideo>> getFollowingFeed({
    int? limit,
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/following', queryParams: params);
    return _parsePaginatedVideos(json);
  }

  /// Get the public web feed (no auth required).
  /// GET /api/web/feed
  Future<List<LoopsVideo>> getPublicFeed() async {
    final json = await _get('/api/web/feed');
    return _parseVideos(json);
  }

  /// Get a specific user's feed.
  /// GET /api/v1/feed/account/{id}
  Future<LoopsPaginatedResponse<LoopsVideo>> getUserFeed(
    String userId, {
    String? cursor,
  }) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    final json = await _get('/api/v1/feed/account/$userId',
        queryParams: params.isNotEmpty ? params : null);
    return _parsePaginatedVideos(json);
  }

  /// Get the authenticated user's own feed.
  /// GET /api/v1/feed/account/self
  Future<LoopsPaginatedResponse<LoopsVideo>> getSelfFeed() async {
    final json = await _get('/api/v1/feed/account/self');
    return _parsePaginatedVideos(json);
  }

  // -------------------------------------------------------------------------
  // VIDEOS
  // -------------------------------------------------------------------------

  /// Get a single video by ID.
  /// GET /api/v1/video/{id}
  Future<LoopsVideo> getVideo(String id) async {
    final json = await _get('/api/v1/video/$id');
    return LoopsVideo.fromJson(json['data'] ?? json);
  }

  /// Like a video.
  /// POST /api/v1/video/like/{id}
  Future<Map<String, dynamic>> likeVideo(String id) async {
    return _post('/api/v1/video/like/$id');
  }

  /// Unlike a video.
  /// POST /api/v1/video/unlike/{id}
  Future<Map<String, dynamic>> unlikeVideo(String id) async {
    return _post('/api/v1/video/unlike/$id');
  }

  /// Bookmark a video.
  /// POST /api/v1/video/bookmark/{id}
  Future<Map<String, dynamic>> bookmarkVideo(String id) async {
    return _post('/api/v1/video/bookmark/$id');
  }

  /// Unbookmark a video.
  /// POST /api/v1/video/unbookmark/{id}
  Future<Map<String, dynamic>> unbookmarkVideo(String id) async {
    return _post('/api/v1/video/unbookmark/$id');
  }

  /// Delete a video.
  /// POST /api/v1/video/delete/{id}
  Future<Map<String, dynamic>> deleteVideo(String id) async {
    return _post('/api/v1/video/delete/$id');
  }

  /// Get accounts that liked a video.
  /// GET /api/v1/video/likes/{id}
  Future<Map<String, dynamic>> getVideoLikes(String id) async {
    return _get('/api/v1/video/likes/$id');
  }

  /// Get accounts that shared a video.
  /// GET /api/v1/video/shares/{id}
  Future<Map<String, dynamic>> getVideoShares(String id) async {
    return _get('/api/v1/video/shares/$id');
  }

  /// Get comments on a video.
  /// GET /api/v1/video/comments/{id}
  Future<List<LoopsComment>> getVideoComments(String id) async {
    final json = await _get('/api/v1/video/comments/$id');
    final data = json['data'];
    if (data is List) {
      return data
          .map((e) => LoopsComment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // -------------------------------------------------------------------------
  // COMMENTS
  // -------------------------------------------------------------------------

  /// Post a new comment on a video.
  /// POST /api/v1/video/comments/{id}
  Future<Map<String, dynamic>> postComment(
    String videoId,
    String text,
  ) async {
    return _post('/api/v1/video/comments/$videoId', body: {
      'comment': text,
    });
  }

  /// Delete a comment.
  /// POST /api/v1/comments/delete/{vid}/{id}
  Future<Map<String, dynamic>> deleteComment(
    String videoId,
    String commentId,
  ) async {
    return _post('/api/v1/comments/delete/$videoId/$commentId');
  }

  /// Like a comment.
  /// POST /api/v1/comments/like/{vid}/{id}
  Future<Map<String, dynamic>> likeComment(
    String videoId,
    String commentId,
  ) async {
    return _post('/api/v1/comments/like/$videoId/$commentId');
  }

  /// Unlike a comment.
  /// POST /api/v1/comments/unlike/{vid}/{id}
  Future<Map<String, dynamic>> unlikeComment(
    String videoId,
    String commentId,
  ) async {
    return _post('/api/v1/comments/unlike/$videoId/$commentId');
  }

  // -------------------------------------------------------------------------
  // ACCOUNTS
  // -------------------------------------------------------------------------

  /// Get the authenticated user's own profile.
  /// GET /api/v1/account/info/self
  Future<LoopsProfile> getSelf() async {
    final json = await _get('/api/v1/account/info/self');
    return LoopsProfile.fromJson(json['data'] ?? json);
  }

  /// Get a user's profile by ID.
  /// GET /api/v1/account/info/{id}
  Future<LoopsProfile> getAccount(String id) async {
    final json = await _get('/api/v1/account/info/$id');
    return LoopsProfile.fromJson(json['data'] ?? json);
  }

  /// Follow an account.
  /// POST /api/v1/account/follow/{id}
  Future<Map<String, dynamic>> followAccount(String id) async {
    return _post('/api/v1/account/follow/$id');
  }

  /// Unfollow an account.
  /// POST /api/v1/account/unfollow/{id}
  Future<Map<String, dynamic>> unfollowAccount(String id) async {
    return _post('/api/v1/account/unfollow/$id');
  }

  /// Block an account.
  /// POST /api/v1/account/block/{id}
  Future<Map<String, dynamic>> blockAccount(String id) async {
    return _post('/api/v1/account/block/$id');
  }

  /// Unblock an account.
  /// POST /api/v1/account/unblock/{id}
  Future<Map<String, dynamic>> unblockAccount(String id) async {
    return _post('/api/v1/account/unblock/$id');
  }

  /// Get an account's followers.
  /// GET /api/v1/account/followers/{id}
  Future<Map<String, dynamic>> getFollowers(String id) async {
    return _get('/api/v1/account/followers/$id');
  }

  /// Get accounts that a user is following.
  /// GET /api/v1/account/following/{id}
  Future<Map<String, dynamic>> getFollowing(String id) async {
    return _get('/api/v1/account/following/$id');
  }

  /// Get the relationship state with another account.
  /// GET /api/v1/account/state/{id}
  Future<Map<String, dynamic>> getRelationship(String id) async {
    return _get('/api/v1/account/state/$id');
  }

  // -------------------------------------------------------------------------
  // SEARCH
  // -------------------------------------------------------------------------

  /// Search for accounts and videos.
  /// GET /api/v1/search?q=query
  Future<Map<String, dynamic>> search(
    String query, {
    String? cursor,
  }) async {
    final params = <String, String>{'q': query};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/search', queryParams: params);
  }

  // -------------------------------------------------------------------------
  // EXPLORE
  // -------------------------------------------------------------------------

  /// Get trending tags.
  /// GET /api/v1/explore/tags
  Future<Map<String, dynamic>> getTrendingTags() async {
    return _get('/api/v1/explore/tags');
  }

  /// Get feed for a specific tag.
  /// GET /api/v1/explore/tag-feed/{id}
  Future<LoopsPaginatedResponse<LoopsVideo>> getTagFeed(String tagId) async {
    final json = await _get('/api/v1/explore/tag-feed/$tagId');
    return _parsePaginatedVideos(json);
  }

  // -------------------------------------------------------------------------
  // NOTIFICATIONS
  // -------------------------------------------------------------------------

  /// Get the authenticated user's notifications.
  /// GET /api/v1/account/notifications
  Future<Map<String, dynamic>> getNotifications({String? cursor}) async {
    final params = <String, String>{};
    if (cursor != null) params['cursor'] = cursor;
    return _get('/api/v1/account/notifications',
        queryParams: params.isNotEmpty ? params : null);
  }

  /// Get the unread notification count.
  /// GET /api/v1/account/notifications/count
  Future<int> getUnreadCount() async {
    final json = await _get('/api/v1/account/notifications/count');
    return json['count'] as int? ?? 0;
  }

  /// Mark a notification as read.
  /// POST /api/v1/account/notifications/{id}/read
  Future<Map<String, dynamic>> markRead(String id) async {
    return _post('/api/v1/account/notifications/$id/read');
  }

  /// Mark all notifications as read.
  /// POST /api/v1/account/notifications/mark-all-read
  Future<Map<String, dynamic>> markAllRead() async {
    return _post('/api/v1/account/notifications/mark-all-read');
  }

  // -------------------------------------------------------------------------
  // CONFIG
  // -------------------------------------------------------------------------

  /// Get instance configuration.
  /// GET /api/v1/config
  Future<Map<String, dynamic>> getConfig() async {
    return _get('/api/v1/config');
  }

  // -------------------------------------------------------------------------
  // Cleanup
  // -------------------------------------------------------------------------

  /// Close the underlying HTTP client.
  ///
  /// Only call this if you provided no external [http.Client] — otherwise
  /// the caller is responsible for closing it.
  void dispose() {
    _client.close();
  }
}
