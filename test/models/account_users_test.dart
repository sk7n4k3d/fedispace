import 'package:flutter_test/flutter_test.dart';
import 'package:fedispace/models/accountUsers.dart';

void main() {
  group('AccountUsers.fromJson', () {
    test('parses complete data', () {
      final json = {
        'id': '42',
        'username': 'johndoe',
        'display_name': 'John Doe',
        'acct': 'johndoe@pixelfed.social',
        'locked': false,
        'bot': false,
        'avatar': 'https://pixelfed.social/avatars/john.png',
        'header': 'https://pixelfed.social/headers/john.png',
        'followers_count': 200,
        'following_count': 100,
        'statuses_count': 50,
        'note': '<p>Photographer</p>',
        'following': true,
      };

      final user = AccountUsers.fromJson(json);

      expect(user.id, '42');
      expect(user.username, 'johndoe');
      expect(user.displayName, 'John Doe');
      expect(user.acct, 'johndoe@pixelfed.social');
      expect(user.isLocked, false);
      expect(user.isBot, false);
      expect(user.avatarUrl, 'https://pixelfed.social/avatars/john.png');
      expect(user.headerUrl, 'https://pixelfed.social/headers/john.png');
      expect(user.followers_count, 200);
      expect(user.following_count, 100);
      expect(user.statuses_count, 50);
      expect(user.note, '<p>Photographer</p>');
      expect(user.following, true);
    });

    test('handles following as null', () {
      final json = {
        'id': '1',
        'username': 'test',
        'display_name': 'Test',
        'acct': 'test',
        'locked': false,
        'bot': false,
        'avatar': '',
        'header': '',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
        'note': '',
        'following': null,
      };

      final user = AccountUsers.fromJson(json);
      expect(user.following, null);
    });

    test('handles following as false', () {
      final json = {
        'id': '2',
        'username': 'other',
        'display_name': 'Other',
        'acct': 'other',
        'locked': true,
        'bot': true,
        'avatar': '',
        'header': '',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
        'note': '',
        'following': false,
      };

      final user = AccountUsers.fromJson(json);
      expect(user.following, false);
      expect(user.isLocked, true);
      expect(user.isBot, true);
    });

    test('getter aliases work correctly', () {
      final json = {
        'id': '1',
        'username': 'test',
        'display_name': 'Display',
        'acct': 'test',
        'locked': true,
        'bot': true,
        'avatar': 'https://example.com/avatar.png',
        'header': 'https://example.com/header.png',
        'followers_count': 10,
        'following_count': 5,
        'statuses_count': 3,
        'note': 'note',
      };

      final user = AccountUsers.fromJson(json);
      expect(user.display_name, 'Display');
      expect(user.avatar, 'https://example.com/avatar.png');
      expect(user.header, 'https://example.com/header.png');
      expect(user.bot, true);
      expect(user.locked, true);
    });

    test('handles missing following field', () {
      final json = {
        'id': '3',
        'username': 'nofollowing',
        'display_name': 'No Following',
        'acct': 'nofollowing',
        'locked': false,
        'bot': false,
        'avatar': '',
        'header': '',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
        'note': '',
      };

      final user = AccountUsers.fromJson(json);
      expect(user.following, null);
    });
  });
}
