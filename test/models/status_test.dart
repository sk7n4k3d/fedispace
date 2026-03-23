import 'package:flutter_test/flutter_test.dart';
import 'package:fedispace/models/status.dart';


void main() {
  final baseAccount = {
    'id': '1',
    'username': 'testuser',
    'display_name': 'Test User',
    'acct': 'testuser',
    'locked': false,
    'bot': false,
    'avatar': 'https://example.com/avatar.png',
    'header': 'https://example.com/header.png',
    'followers_count': 10,
    'following_count': 5,
    'statuses_count': 3,
    'note': '',
  };

  group('Status.fromJson', () {
    test('parses complete status data', () {
      final json = {
        'id': '100',
        'content': '<p>Hello Fediverse!</p>',
        'account': baseAccount,
        'favourited': true,
        'reblogged': false,
        'visibility': 'public',
        'uri': 'https://instance.social/statuses/100',
        'url': 'https://instance.social/@testuser/100',
        'in_reply_to_id': null,
        'in_reply_to_account_id': null,
        'muted': false,
        'sensitive': false,
        'spoiler_text': '',
        'language': 'en',
        'created_at': '2024-01-15T12:00:00.000Z',
        'favourites_count': 5,
        'replies_count': 2,
        'reblogs_count': 1,
        'media_attachments': [],
      };

      final status = Status.fromJson(json);

      expect(status.id, '100');
      expect(status.content, '<p>Hello Fediverse!</p>');
      expect(status.account.username, 'testuser');
      expect(status.favorited, true);
      expect(status.reblogged, false);
      expect(status.visibility, 'public');
      expect(status.favourites_count, 5);
      expect(status.replies_count, 2);
      expect(status.reblogs_count, 1);
      expect(status.created_at, '2024-01-15T12:00:00.000Z');
    });

    test('parses status with media attachments', () {
      final json = {
        'id': '200',
        'content': 'Photo post',
        'account': baseAccount,
        'favourited': false,
        'reblogged': false,
        'visibility': 'public',
        'uri': '',
        'url': '',
        'in_reply_to_id': null,
        'in_reply_to_account_id': null,
        'muted': false,
        'sensitive': false,
        'spoiler_text': '',
        'language': 'en',
        'created_at': '2024-01-15T12:00:00.000Z',
        'favourites_count': 0,
        'replies_count': 0,
        'reblogs_count': 0,
        'media_attachments': [
          {
            'id': 'media1',
            'type': 'image',
            'url': 'https://example.com/image.jpg',
            'preview_url': 'https://example.com/preview.jpg',
            'blurhash': 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          },
        ],
      };

      final status = Status.fromJson(json);

      expect(status.hasMediaAttachments, true);
      expect(status.attach, 'https://example.com/image.jpg');
      expect(status.preview_url, 'https://example.com/preview.jpg');
      expect(status.blurhash, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj');
      expect(status.attachement.length, 1);
    });

    test('handles empty media attachments', () {
      final json = {
        'id': '300',
        'content': 'Text only',
        'account': baseAccount,
        'media_attachments': [],
        'favourited': false,
        'reblogged': false,
        'visibility': 'public',
        'uri': '',
        'url': '',
        'created_at': '',
        'favourites_count': 0,
        'replies_count': 0,
        'reblogs_count': 0,
      };

      final status = Status.fromJson(json);

      expect(status.hasMediaAttachments, false);
      expect(status.attach, '');
      expect(status.preview_url, '');
      expect(status.getFirstMedia(), null);
      expect(status.getAllMedia(), isEmpty);
    });

    test('handles null fields with defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'content': null,
        'account': baseAccount,
        'favourited': null,
        'reblogged': null,
        'visibility': null,
        'uri': null,
        'url': null,
        'in_reply_to_id': null,
        'in_reply_to_account_id': null,
        'muted': null,
        'sensitive': null,
        'spoiler_text': null,
        'language': null,
        'created_at': null,
        'favourites_count': null,
        'replies_count': null,
        'reblogs_count': null,
        'media_attachments': null,
      };

      final status = Status.fromJson(json);

      expect(status.id, '');
      expect(status.content, '');
      expect(status.favorited, false);
      expect(status.reblogged, false);
      expect(status.visibility, 'public');
      expect(status.muted, false);
      expect(status.sensitive, false);
    });

    test('parses reply status', () {
      final json = {
        'id': '400',
        'content': 'This is a reply',
        'account': baseAccount,
        'in_reply_to_id': '100',
        'in_reply_to_account_id': '1',
        'favourited': false,
        'reblogged': false,
        'visibility': 'public',
        'uri': '',
        'url': '',
        'muted': false,
        'sensitive': false,
        'spoiler_text': '',
        'language': 'en',
        'created_at': '',
        'favourites_count': 0,
        'replies_count': 0,
        'reblogs_count': 0,
        'media_attachments': [],
      };

      final status = Status.fromJson(json);
      expect(status.in_reply_to_id, '100');
      expect(status.in_reply_to_account_id, '1');
    });

    test('parses sensitive status with spoiler', () {
      final json = {
        'id': '500',
        'content': 'Sensitive content',
        'account': baseAccount,
        'sensitive': true,
        'spoiler_text': 'Content warning',
        'favourited': false,
        'reblogged': false,
        'visibility': 'unlisted',
        'uri': '',
        'url': '',
        'created_at': '',
        'favourites_count': 0,
        'replies_count': 0,
        'reblogs_count': 0,
        'media_attachments': [],
      };

      final status = Status.fromJson(json);
      expect(status.sensitive, true);
      expect(status.spoiler_text, 'Content warning');
      expect(status.visibility, 'unlisted');
    });

    test('extracts avatar and acct from account data', () {
      final json = {
        'id': '600',
        'content': '',
        'account': baseAccount,
        'favourited': false,
        'reblogged': false,
        'visibility': 'public',
        'uri': '',
        'url': '',
        'created_at': '',
        'favourites_count': 0,
        'replies_count': 0,
        'reblogs_count': 0,
        'media_attachments': [],
      };

      final status = Status.fromJson(json);
      expect(status.avatar, 'https://example.com/avatar.png');
      expect(status.acct, 'testuser');
    });

    test('multiple media attachments', () {
      final json = {
        'id': '700',
        'content': 'Gallery post',
        'account': baseAccount,
        'favourited': false,
        'reblogged': false,
        'visibility': 'public',
        'uri': '',
        'url': '',
        'created_at': '',
        'favourites_count': 0,
        'replies_count': 0,
        'reblogs_count': 0,
        'media_attachments': [
          {
            'id': 'm1',
            'url': 'https://example.com/img1.jpg',
            'preview_url': 'https://example.com/preview1.jpg',
            'blurhash': 'LEHV6nWB2yk8',
          },
          {
            'id': 'm2',
            'url': 'https://example.com/img2.jpg',
            'preview_url': 'https://example.com/preview2.jpg',
            'blurhash': 'LGF5}+Yk^6#M',
          },
        ],
      };

      final status = Status.fromJson(json);
      expect(status.hasMediaAttachments, true);
      expect(status.attachement.length, 2);
      expect(status.getAllMedia().length, 2);
      expect(status.attach, 'https://example.com/img1.jpg');
    });
  });

  group('Status.empty', () {
    test('creates empty status with default values', () {
      final status = Status.empty();
      expect(status.id, '');
      expect(status.content, '');
      expect(status.favorited, false);
      expect(status.reblogged, false);
      expect(status.attachement, isEmpty);
    });
  });

  group('Status.toJson', () {
    test('serializes status to json map', () {
      final json = {
        'id': '100',
        'content': 'Test',
        'account': baseAccount,
        'favourited': true,
        'reblogged': false,
        'visibility': 'public',
        'uri': 'uri',
        'url': 'url',
        'in_reply_to_id': null,
        'in_reply_to_account_id': null,
        'muted': false,
        'sensitive': false,
        'spoiler_text': '',
        'language': 'en',
        'created_at': '2024-01-01',
        'favourites_count': 1,
        'replies_count': 0,
        'reblogs_count': 0,
        'media_attachments': [],
      };

      final status = Status.fromJson(json);
      final serialized = status.toJson();

      expect(serialized['id'], '100');
      expect(serialized['content'], 'Test');
      expect(serialized['favorited'], true);
      expect(serialized['visibility'], 'public');
    });
  });

  group('userFromJson', () {
    test('parses list of statuses from JSON string', () {
      const jsonString = '[{"id":"1","content":"Post 1","account":{"id":"1","username":"u1","display_name":"U1","acct":"u1","locked":false,"bot":false,"avatar":"","header":"","followers_count":0,"following_count":0,"statuses_count":0,"note":""},"favourited":false,"reblogged":false,"visibility":"public","uri":"","url":"","created_at":"","favourites_count":0,"replies_count":0,"reblogs_count":0,"media_attachments":[]},{"id":"2","content":"Post 2","account":{"id":"2","username":"u2","display_name":"U2","acct":"u2","locked":false,"bot":false,"avatar":"","header":"","followers_count":0,"following_count":0,"statuses_count":0,"note":""},"favourited":true,"reblogged":false,"visibility":"unlisted","uri":"","url":"","created_at":"","favourites_count":3,"replies_count":1,"reblogs_count":0,"media_attachments":[]}]';

      final statuses = userFromJson(jsonString);
      expect(statuses.length, 2);
      expect(statuses[0].id, '1');
      expect(statuses[1].id, '2');
      expect(statuses[1].favourites_count, 3);
    });
  });
}
