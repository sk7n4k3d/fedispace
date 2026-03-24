import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/core/notification_service.dart';

class UnifiedPushService {
  final String instance = "fedispace_main";
  String? endpoint;
  bool registered = false;
  ApiService? _apiService;

  /// Initialize UnifiedPush with proper error handling
  Future<bool> initUnifiedPush() async {
    try {
      appLogger.info('Initializing UnifiedPush');

      await UnifiedPush.initialize(
        onNewEndpoint: _onNewEndpoint,
        onRegistrationFailed: _onRegistrationFailed,
        onUnregistered: _onUnregistered,
        onMessage: _onMessage,
      );

      appLogger.info('UnifiedPush initialized successfully');
      return true;
    } catch (e, stackTrace) {
      appLogger.error('Failed to initialize UnifiedPush', e, stackTrace);
      return false;
    }
  }

  /// Start UnifiedPush registration with distributor check
  Future<void> startUnifiedPush(
      BuildContext context, ApiService apiService) async {
    _apiService = apiService;
    _initNotifications();

    appLogger.info('Starting UnifiedPush registration');

    // Check available distributors first
    final distributors = await UnifiedPush.getDistributors();

    if (distributors.isEmpty) {
      appLogger.error('No UnifiedPush distributors found');
      _showNoDistributorWarning(context);
      return;
    }

    appLogger.info('Found distributors: $distributors');

    // Save and use first available distributor
    await UnifiedPush.saveDistributor(distributors.first);

    // Register with UnifiedPush
    await UnifiedPush.registerApp(instance);
  }

  /// Callback when new endpoint is received (v5 API uses String)
  void _onNewEndpoint(String endpointUrl, String inst) {
    if (inst != instance) {
      appLogger.error('Received endpoint for different instance: $inst');
      return;
    }

    registered = true;
    endpoint = endpointUrl;

    appLogger.info('New UnifiedPush endpoint received: $endpointUrl');

    // Send endpoint to server
    if (_apiService != null) {
      _registerEndpointWithServer(endpointUrl);
    } else {
      appLogger.error('ApiService not set, cannot register endpoint');
    }
  }

  /// Generate random bytes for VAPID keys
  /// Register push endpoint with Pixelfed server
  Future<void> _registerEndpointWithServer(String endpointUrl) async {
    try {
      appLogger.info('Registering push endpoint with server');

      // Generate VAPID keys for the push subscription
      // These are placeholder keys - the server needs them for Web Push protocol
      // Send empty keys - Pixelfed doesn't encrypt push payloads
      final p256dhKey = '';
      final authKey = '';

      final result = await _apiService!.subscribePushNotifications(
        endpoint: endpointUrl,
        p256dhKey: p256dhKey,
        authKey: authKey,
      );

      if (result != null) {
        appLogger.info('Push endpoint registered successfully with server');
      } else {
        appLogger.error(
            'Push endpoint registration returned null - server may not support Web Push');
      }
    } catch (e, stackTrace) {
      appLogger.error('Failed to register endpoint with server', e, stackTrace);
    }
  }

  /// Callback when registration fails (v5 API uses String)
  void _onRegistrationFailed(String inst) {
    if (inst != instance) return;

    registered = false;
    appLogger.error('UnifiedPush registration failed for instance: $inst');

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'internal',
        title: 'Push Registration Failed',
        body: 'Failed to register for push notifications',
      ),
    );
  }

  /// Callback when unregistered
  void _onUnregistered(String inst) {
    if (inst != instance) return;

    registered = false;
    endpoint = null;
    appLogger.info('UnifiedPush unregistered');
  }

  /// Callback when message is received (v5 API uses Uint8List)
  void _onMessage(Uint8List message, String inst) {
    if (inst != instance) return;

    final decoded = String.fromCharCodes(message);
    appLogger
        .info('UnifiedPush message received (length: ${message.length} bytes)');

    // Try to parse as JSON (Mastodon/Pixelfed notification format)
    try {
      final data = json.decode(decoded);
      debugPrint("[UP] Parsed JSON notification: $data");
      _handleParsedNotification(data);
    } catch (e) {
      // Not JSON or parsing failed - show raw message
      appLogger.debug('Push message is not JSON, showing raw: $e');
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'status',
          title: 'New Notification',
          body: decoded,
        ),
      );
    }
  }

  /// Handle a parsed Mastodon/Pixelfed notification
  void _handleParsedNotification(dynamic data) {
    if (data is! Map<String, dynamic>) {
      appLogger.debug('Notification data is not a map');
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'status',
          title: 'New Notification',
          body: data.toString(),
        ),
      );
      return;
    }

    // Mastodon notification format:
    // { "notification_id": "...", "notification_type": "follow|favourite|reblog|mention|poll|follow_request",
    //   "title": "...", "body": "...", "icon": "...",
    //   "preferred_locale": "...", "access_token": "..." }
    final String notificationType =
        data['notification_type'] ?? data['type'] ?? 'status';
    final String title = data['title'] ?? _getTitleForType(notificationType);
    final String body = data['body'] ?? data['message'] ?? '';
    final String? icon = data['icon'];

    // Map notification type to channel
    String channelKey;
    switch (notificationType) {
      case 'follow':
        channelKey = 'follow';
        break;
      case 'follow_request':
        channelKey = 'follow_request';
        break;
      case 'favourite':
        channelKey = 'favourite';
        break;
      case 'reblog':
        channelKey = 'reblog';
        break;
      case 'mention':
        channelKey = 'mention';
        break;
      default:
        channelKey = 'status';
    }

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: channelKey,
        title: title,
        body: body,
        bigPicture: icon,
        notificationLayout: icon != null
            ? NotificationLayout.BigPicture
            : NotificationLayout.Default,
      ),
    );
  }

  /// Get a default title for a notification type
  String _getTitleForType(String type) {
    switch (type) {
      case 'follow':
        return 'New Follower';
      case 'follow_request':
        return 'Follow Request';
      case 'favourite':
        return 'Post Liked';
      case 'reblog':
        return 'Post Shared';
      case 'mention':
        return 'New Mention';
      case 'poll':
        return 'Poll Update';
      default:
        return 'New Notification';
    }
  }

  /// Show warning when no distributor is installed
  void _showNoDistributorWarning(BuildContext context) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 102,
        channelKey: 'internal',
        title: 'UnifiedPush Setup Required',
        body: 'Please install a push distributor app (e.g., ntfy) from F-Droid',
      ),
    );
  }

  /// Initialize notification channels (delegates to shared NotificationPollingService)
  void _initNotifications() {
    NotificationPollingService().initializeNotifications();
  }

  /// Unregister from push notifications
  Future<void> unregister() async {
    // Also delete server-side push subscription
    if (_apiService != null) {
      try {
        await _apiService!.deletePushSubscription();
        appLogger.info('Server-side push subscription deleted');
      } catch (e) {
        appLogger.error('Failed to delete server push subscription', e);
      }
    }
    await UnifiedPush.unregister(instance);
    appLogger.info('UnifiedPush unregistration requested');
  }
}
