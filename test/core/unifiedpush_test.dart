import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Push message parsing', () {
    test('parses follow notification JSON', () {
      final messageBytes = Uint8List.fromList(utf8.encode(json.encode({
        'notification_type': 'follow',
        'title': 'New Follower',
        'body': 'user123 followed you',
        'icon': 'https://instance.social/avatar.png',
      })));

      final decoded = String.fromCharCodes(messageBytes);
      final data = json.decode(decoded) as Map<String, dynamic>;

      expect(data['notification_type'], 'follow');
      expect(data['title'], 'New Follower');
      expect(data['body'], 'user123 followed you');
      expect(data['icon'], 'https://instance.social/avatar.png');
    });

    test('parses favourite notification JSON', () {
      final payload = {
        'notification_type': 'favourite',
        'title': 'Post Liked',
        'body': 'user456 liked your post',
      };

      final messageBytes =
          Uint8List.fromList(utf8.encode(json.encode(payload)));
      final decoded = String.fromCharCodes(messageBytes);
      final data = json.decode(decoded) as Map<String, dynamic>;

      expect(data['notification_type'], 'favourite');
    });

    test('parses reblog notification JSON', () {
      final payload = {
        'notification_type': 'reblog',
        'title': 'Post Shared',
        'body': 'user789 shared your post',
      };

      final messageBytes =
          Uint8List.fromList(utf8.encode(json.encode(payload)));
      final decoded = String.fromCharCodes(messageBytes);
      final data = json.decode(decoded) as Map<String, dynamic>;

      expect(data['notification_type'], 'reblog');
    });

    test('parses mention notification JSON', () {
      final payload = {
        'notification_type': 'mention',
        'title': 'New Mention',
        'body': 'user mentioned you in a post',
      };

      final messageBytes =
          Uint8List.fromList(utf8.encode(json.encode(payload)));
      final decoded = String.fromCharCodes(messageBytes);
      final data = json.decode(decoded) as Map<String, dynamic>;

      expect(data['notification_type'], 'mention');
    });

    test('handles non-JSON push message gracefully', () {
      final messageBytes =
          Uint8List.fromList(utf8.encode('plain text notification'));
      final decoded = String.fromCharCodes(messageBytes);

      dynamic parsedData;
      try {
        parsedData = json.decode(decoded);
      } catch (e) {
        parsedData = null;
      }

      expect(parsedData, null);
      expect(decoded, 'plain text notification');
    });

    test('handles empty push message', () {
      final messageBytes = Uint8List.fromList([]);
      final decoded = String.fromCharCodes(messageBytes);
      expect(decoded, '');
    });

    test('parses notification with alternative type field', () {
      final payload = {
        'type': 'follow_request',
        'title': 'Follow Request',
        'body': 'someone wants to follow you',
      };

      final data = json.decode(json.encode(payload)) as Map<String, dynamic>;
      final notificationType =
          data['notification_type'] ?? data['type'] ?? 'status';
      expect(notificationType, 'follow_request');
    });
  });

  group('Notification type to channel mapping', () {
    String mapTypeToChannel(String type) {
      switch (type) {
        case 'follow':
          return 'follow';
        case 'follow_request':
          return 'follow_request';
        case 'favourite':
          return 'favourite';
        case 'reblog':
          return 'reblog';
        case 'mention':
          return 'mention';
        default:
          return 'status';
      }
    }

    test('follow maps to follow channel', () {
      expect(mapTypeToChannel('follow'), 'follow');
    });

    test('favourite maps to favourite channel', () {
      expect(mapTypeToChannel('favourite'), 'favourite');
    });

    test('reblog maps to reblog channel', () {
      expect(mapTypeToChannel('reblog'), 'reblog');
    });

    test('mention maps to mention channel', () {
      expect(mapTypeToChannel('mention'), 'mention');
    });

    test('unknown type maps to status channel', () {
      expect(mapTypeToChannel('poll'), 'status');
      expect(mapTypeToChannel('unknown'), 'status');
    });
  });

  group('Notification title for type', () {
    String getTitleForType(String type) {
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

    test('all types have correct titles', () {
      expect(getTitleForType('follow'), 'New Follower');
      expect(getTitleForType('follow_request'), 'Follow Request');
      expect(getTitleForType('favourite'), 'Post Liked');
      expect(getTitleForType('reblog'), 'Post Shared');
      expect(getTitleForType('mention'), 'New Mention');
      expect(getTitleForType('poll'), 'Poll Update');
      expect(getTitleForType('other'), 'New Notification');
    });
  });

  group('Endpoint registration data', () {
    test('endpoint URL is correctly formatted', () {
      const endpoint = 'https://push.example.com/up/abc123';
      expect(Uri.parse(endpoint).scheme, 'https');
      expect(Uri.parse(endpoint).host, 'push.example.com');
    });

    test('push subscription data structure is valid', () {
      final subscriptionData = {
        'subscription': {
          'endpoint': 'https://push.example.com/up/abc123',
          'keys': {
            'p256dh': 'BNcRdre...',
            'auth': 'tBHI...',
          },
        },
        'data': {
          'alerts': {
            'follow': true,
            'favourite': true,
            'reblog': true,
            'mention': true,
            'poll': true,
          },
        },
      };

      expect(subscriptionData['subscription'], isA<Map>());
      final sub = subscriptionData['subscription'] as Map<String, dynamic>;
      expect(sub['endpoint'], isNotEmpty);
      expect(sub['keys'], isA<Map>());
    });
  });
}
