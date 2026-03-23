import 'package:flutter_test/flutter_test.dart';
import 'package:fedispace/models/account.dart';

void main() {
  group('Account.fromJson', () {
    test('parses complete account data', () {
      final json = {
        'id': '12345',
        'username': 'testuser',
        'display_name': 'Test User',
        'acct': 'testuser@instance.social',
        'locked': false,
        'bot': false,
        'avatar': 'https://instance.social/avatars/testuser.png',
        'header': 'https://instance.social/headers/testuser.png',
        'followers_count': 150,
        'following_count': 75,
        'statuses_count': 42,
        'note': '<p>Hello world</p>',
      };

      final account = Account.fromJson(json);

      expect(account.id, '12345');
      expect(account.username, 'testuser');
      expect(account.displayName, 'Test User');
      expect(account.acct, 'testuser@instance.social');
      expect(account.isLocked, false);
      expect(account.isBot, false);
      expect(account.avatarUrl, 'https://instance.social/avatars/testuser.png');
      expect(account.headerUrl, 'https://instance.social/headers/testuser.png');
      expect(account.followers_count, 150);
      expect(account.following_count, 75);
      expect(account.statuses_count, 42);
      expect(account.note, '<p>Hello world</p>');
    });

    test('handles null fields with defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'username': null,
        'display_name': null,
        'acct': null,
        'locked': null,
        'bot': null,
        'avatar': null,
        'header': null,
        'followers_count': null,
        'following_count': null,
        'statuses_count': null,
        'note': null,
      };

      final account = Account.fromJson(json);

      expect(account.id, '');
      expect(account.username, '');
      expect(account.displayName, '');
      expect(account.acct, '');
      expect(account.isLocked, false);
      expect(account.isBot, false);
      expect(account.avatarUrl, '');
      expect(account.headerUrl, '');
      expect(account.followers_count, 0);
      expect(account.following_count, 0);
      expect(account.statuses_count, 0);
      expect(account.note, '');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final account = Account.fromJson(json);

      expect(account.id, '');
      expect(account.username, '');
      expect(account.displayName, '');
      expect(account.isLocked, false);
      expect(account.isBot, false);
      expect(account.followers_count, 0);
    });

    test('converts numeric id to string', () {
      final json = {
        'id': 99999,
        'username': 'numericid',
        'display_name': 'Numeric',
        'acct': 'numericid',
        'locked': false,
        'bot': false,
        'avatar': '',
        'header': '',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
        'note': '',
      };

      final account = Account.fromJson(json);
      expect(account.id, '99999');
    });

    test('handles locked and bot account', () {
      final json = {
        'id': '1',
        'username': 'locked_bot',
        'display_name': 'Locked Bot',
        'acct': 'locked_bot',
        'locked': true,
        'bot': true,
        'avatar': '',
        'header': '',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
        'note': '',
      };

      final account = Account.fromJson(json);
      expect(account.isLocked, true);
      expect(account.isBot, true);
    });

    test('getter aliases work correctly', () {
      final json = {
        'id': '1',
        'username': 'test',
        'display_name': 'Display Name',
        'acct': 'test',
        'locked': false,
        'bot': false,
        'avatar': 'https://example.com/avatar.png',
        'header': 'https://example.com/header.png',
        'followers_count': 10,
        'following_count': 20,
        'statuses_count': 5,
        'note': 'bio',
      };

      final account = Account.fromJson(json);
      expect(account.display_name, 'Display Name');
      expect(account.avatar, 'https://example.com/avatar.png');
      expect(account.header, 'https://example.com/header.png');
    });

    test('handles large follower counts', () {
      final json = {
        'id': '1',
        'username': 'popular',
        'display_name': 'Popular User',
        'acct': 'popular',
        'locked': false,
        'bot': false,
        'avatar': '',
        'header': '',
        'followers_count': 1000000,
        'following_count': 500,
        'statuses_count': 50000,
        'note': '',
      };

      final account = Account.fromJson(json);
      expect(account.followers_count, 1000000);
      expect(account.statuses_count, 50000);
    });
  });
}
