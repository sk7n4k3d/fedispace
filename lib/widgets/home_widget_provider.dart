import 'package:flutter/services.dart';

/// Provider for Android home screen widgets.
/// Uses method channels to communicate with native widget code.
class HomeWidgetProvider {
  static const MethodChannel _channel =
      MethodChannel('space.echelon4.fedispace/home_widget');
  static const String _groupId = 'space.echelon4.fedispace.widgets';

  /// Update the notification count widget.
  static Future<void> updateNotificationWidget(
      int count, String lastNotification) async {
    try {
      await _channel.invokeMethod('updateNotificationWidget', {
        'count': count,
        'lastNotification': lastNotification,
        'groupId': _groupId,
      });
    } catch (_) {
      // Widget may not be placed on home screen
    }
  }

  /// Update the latest posts widget with thumbnail URLs.
  static Future<void> updateLatestPostsWidget(
      List<String> thumbnailUrls) async {
    try {
      await _channel.invokeMethod('updateLatestPostsWidget', {
        'thumbnailUrls': thumbnailUrls,
        'groupId': _groupId,
      });
    } catch (_) {
      // Widget may not be placed on home screen
    }
  }

  /// Request widget update from the system.
  static Future<void> requestUpdate() async {
    try {
      await _channel.invokeMethod('requestWidgetUpdate', {
        'groupId': _groupId,
      });
    } catch (_) {}
  }
}
