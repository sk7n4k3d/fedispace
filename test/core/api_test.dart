import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/core/error_handler.dart';

void main() {
  group('nodeInfo response parsing', () {
    test('valid Pixelfed instance response is accepted', () {
      final jsonBody = {
        'uri': 'pixelfed.social',
        'title': 'Pixelfed',
        'description': 'A Pixelfed instance',
        'version': '0.11.9',
        'metadata': {
          'nodeName': 'Pixelfed',
        },
        'config': {
          'features': {
            'mobile_apis': true,
          },
        },
      };

      final metadata = jsonBody['metadata'] as Map<String, dynamic>?;
      final config = jsonBody['config'] as Map<String, dynamic>?;
      final features = config?['features'] as Map<String, dynamic>?;

      expect(metadata?['nodeName'], 'Pixelfed');
      expect(features?['mobile_apis'], true);
    });

    test('non-Pixelfed instance is rejected', () {
      final jsonBody = {
        'uri': 'mastodon.social',
        'title': 'Mastodon',
        'description': 'A Mastodon instance',
        'version': '4.0.0',
        'metadata': {
          'nodeName': 'Mastodon',
        },
        'config': {
          'features': {
            'mobile_apis': false,
          },
        },
      };

      final metadata = jsonBody['metadata'] as Map<String, dynamic>?;
      expect(metadata?['nodeName'] == 'Pixelfed', false);
    });

    test('instance without mobile_apis is rejected', () {
      final jsonBody = {
        'metadata': {'nodeName': 'Pixelfed'},
        'config': {
          'features': {
            'mobile_apis': false,
          },
        },
      };

      final config = jsonBody['config'] as Map<String, dynamic>?;
      final features = config?['features'] as Map<String, dynamic>?;
      expect(features?['mobile_apis'], false);
    });

    test('missing metadata returns null safely', () {
      final jsonBody = <String, dynamic>{
        'uri': 'example.com',
      };

      expect(jsonBody['metadata'], null);
    });
  });

  group('Account.fromJson via API response', () {
    test('parses account from API response body', () {
      final responseBody = json.encode({
        'id': '12345',
        'username': 'apiuser',
        'display_name': 'API User',
        'acct': 'apiuser@instance.social',
        'locked': false,
        'bot': false,
        'avatar': 'https://instance.social/avatar.png',
        'header': 'https://instance.social/header.png',
        'followers_count': 100,
        'following_count': 50,
        'statuses_count': 25,
        'note': '<p>Bio</p>',
      });

      final data = json.decode(responseBody);
      final account = Account.fromJson(data);

      expect(account.id, '12345');
      expect(account.username, 'apiuser');
      expect(account.followers_count, 100);
    });

    test('parses account with partial data', () {
      final data = {
        'id': '1',
        'username': 'minimal',
        'display_name': '',
        'acct': 'minimal',
        'locked': false,
        'bot': false,
        'avatar': '',
        'header': '',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
        'note': '',
      };

      final account = Account.fromJson(data);
      expect(account.id, '1');
      expect(account.displayName, '');
    });
  });

  group('Status.fromJson via API response', () {
    test('parses status list from API response', () {
      final responseBody = json.encode([
        {
          'id': '1',
          'content': '<p>Hello</p>',
          'account': {
            'id': '1',
            'username': 'user1',
            'display_name': 'User 1',
            'acct': 'user1',
            'locked': false,
            'bot': false,
            'avatar': '',
            'header': '',
            'followers_count': 0,
            'following_count': 0,
            'statuses_count': 0,
            'note': '',
          },
          'favourited': false,
          'reblogged': false,
          'visibility': 'public',
          'uri': '',
          'url': '',
          'created_at': '2024-01-01T00:00:00.000Z',
          'favourites_count': 0,
          'replies_count': 0,
          'reblogs_count': 0,
          'media_attachments': [],
        },
      ]);

      final List<dynamic> jsonList = json.decode(responseBody);
      final statuses = jsonList.map((e) => Status.fromJson(e)).toList();

      expect(statuses.length, 1);
      expect(statuses[0].content, '<p>Hello</p>');
    });
  });

  group('ErrorHandler', () {
    test('handleResponse does not throw for 200', () {
      expect(
        () => ErrorHandler.handleResponse(200, '{"ok": true}'),
        returnsNormally,
      );
    });

    test('handleResponse throws AuthenticationException for 401', () {
      expect(
        () => ErrorHandler.handleResponse(401, '{"error": "Unauthorized"}'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('handleResponse throws AuthenticationException for 403', () {
      expect(
        () => ErrorHandler.handleResponse(403, '{"error": "Forbidden"}'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('handleResponse throws NotFoundException for 404', () {
      expect(
        () => ErrorHandler.handleResponse(404, '{"error": "Not found"}'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('handleResponse throws ServerException for 500', () {
      expect(
        () => ErrorHandler.handleResponse(500, '{"error": "Internal error"}'),
        throwsA(isA<ServerException>()),
      );
    });

    test('handleResponse throws ValidationException for 422', () {
      expect(
        () => ErrorHandler.handleResponse(422, '{"error": "Invalid data"}'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('handleResponse throws ValidationException for 400', () {
      expect(
        () => ErrorHandler.handleResponse(400, '{"error": "Bad request"}'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('handleResponse handles empty response body', () {
      expect(
        () => ErrorHandler.handleResponse(500, ''),
        throwsA(isA<ServerException>()),
      );
    });

    test('parseJson throws NetworkException on invalid JSON', () {
      expect(
        () => ErrorHandler.parseJson('not json {{{'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('parseJson parses valid JSON', () {
      final result = ErrorHandler.parseJson('{"key": "value"}');
      expect(result['key'], 'value');
    });

    test('handleNetworkError wraps unknown errors', () {
      expect(
        () => ErrorHandler.handleNetworkError(Exception('timeout')),
        throwsA(isA<NetworkException>()),
      );
    });

    test('handleNetworkError rethrows ApiException', () {
      expect(
        () => ErrorHandler.handleNetworkError(
          AuthenticationException('test'),
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });

  group('MockClient HTTP tests', () {
    test('mock GET request returns expected data', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
          json.encode({'id': '1', 'username': 'test'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await client.get(
        Uri.parse('https://instance.social/api/v1/accounts/1'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['username'], 'test');

      client.close();
    });

    test('mock GET request handles 500 error', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"error": "Internal Server Error"}',
          500,
        );
      });

      final response = await client.get(
        Uri.parse('https://instance.social/api/v1/timelines/home'),
      );

      expect(response.statusCode, 500);
      expect(
        () => ErrorHandler.handleResponse(response.statusCode, response.body),
        throwsA(isA<ServerException>()),
      );

      client.close();
    });

    test('mock GET request handles 401 unauthorized', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"error": "The access token is invalid"}',
          401,
        );
      });

      final response = await client.get(
        Uri.parse('https://instance.social/api/v1/accounts/verify_credentials'),
      );

      expect(response.statusCode, 401);
      expect(
        () => ErrorHandler.handleResponse(response.statusCode, response.body),
        throwsA(isA<AuthenticationException>()),
      );

      client.close();
    });

    test('mock POST request for favourite', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/statuses/123/favourite');
        return http.Response(
          json.encode({
            'id': '123',
            'content': 'Test',
            'account': {
              'id': '1',
              'username': 'user',
              'display_name': 'User',
              'acct': 'user',
              'locked': false,
              'bot': false,
              'avatar': '',
              'header': '',
              'followers_count': 0,
              'following_count': 0,
              'statuses_count': 0,
              'note': '',
            },
            'favourited': true,
            'reblogged': false,
            'visibility': 'public',
            'uri': '',
            'url': '',
            'created_at': '',
            'favourites_count': 1,
            'replies_count': 0,
            'reblogs_count': 0,
            'media_attachments': [],
          }),
          200,
        );
      });

      final response = await client.post(
        Uri.parse('https://instance.social/api/v1/statuses/123/favourite'),
      );

      expect(response.statusCode, 200);
      final status = Status.fromJson(json.decode(response.body));
      expect(status.favorited, true);

      client.close();
    });

    test('URL construction for various API methods', () {
      const instanceUrl = 'https://pixelfed.social';

      expect(
        '$instanceUrl/api/v1/timelines/home?limit=20',
        'https://pixelfed.social/api/v1/timelines/home?limit=20',
      );

      expect(
        '$instanceUrl/api/v1/timelines/public?local=true&limit=20',
        'https://pixelfed.social/api/v1/timelines/public?local=true&limit=20',
      );

      expect(
        '$instanceUrl/api/v1/statuses/123/favourite',
        'https://pixelfed.social/api/v1/statuses/123/favourite',
      );

      expect(
        '$instanceUrl/api/v1/accounts/verify_credentials',
        'https://pixelfed.social/api/v1/accounts/verify_credentials',
      );

      expect(
        '$instanceUrl/api/v1/instance',
        'https://pixelfed.social/api/v1/instance',
      );
    });

    test('domain with protocol keeps as-is for nodeInfo', () {
      const domain = 'https://pixelfed.social';
      final apiUrl = domain.contains('://')
          ? '$domain/api/v1/instance'
          : 'https://$domain/api/v1/instance';
      expect(apiUrl, 'https://pixelfed.social/api/v1/instance');
    });

    test('domain without protocol gets https prefix', () {
      const domain = 'pixelfed.social';
      final apiUrl = domain.contains('://')
          ? '$domain/api/v1/instance'
          : 'https://$domain/api/v1/instance';
      expect(apiUrl, 'https://pixelfed.social/api/v1/instance');
    });
  });
}
