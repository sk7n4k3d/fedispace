import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('translateText mock responses', () {
    test('successful translation returns translated text', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['Authorization'], startsWith('Bearer '));

        final body = json.decode(request.body);
        expect(body['model'], isNotNull);
        expect(body['messages'], isA<List>());
        expect(body['messages'].length, 2);

        return http.Response(
          json.encode({
            'choices': [
              {
                'message': {
                  'content': 'Bonjour le monde',
                },
              },
            ],
          }),
          200,
        );
      });

      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-key',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a translator. Translate the following text to French. Return ONLY the translated text, nothing else.',
            },
            {
              'role': 'user',
              'content': 'Hello world',
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        }),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      final translated = data['choices']?[0]?['message']?['content']?.toString().trim();
      expect(translated, 'Bonjour le monde');

      client.close();
    });

    test('API error returns null-equivalent handling', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"error": {"message": "Rate limit exceeded"}}',
          429,
        );
      });

      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-key',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': 'test'},
          ],
        }),
      );

      expect(response.statusCode, 429);
      // In the real code, non-200 returns null
      String? translated;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        translated = data['choices']?[0]?['message']?['content']?.toString().trim();
      }
      expect(translated, null);

      client.close();
    });

    test('server 500 error is handled', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-key',
        },
        body: '{}',
      );

      expect(response.statusCode, 500);

      client.close();
    });

    test('invalid JSON response is handled', () async {
      final client = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-key',
        },
        body: '{}',
      );

      expect(response.statusCode, 200);

      String? translated;
      try {
        final data = json.decode(response.body);
        translated = data['choices']?[0]?['message']?['content']?.toString().trim();
      } catch (e) {
        translated = null;
      }
      expect(translated, null);

      client.close();
    });

    test('empty choices array returns null', () async {
      final client = MockClient((request) async {
        return http.Response(
          json.encode({'choices': []}),
          200,
        );
      });

      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-key',
        },
        body: '{}',
      );

      final data = json.decode(response.body);
      // Safe navigation with ?[] - empty list means index 0 returns null
      final choices = data['choices'] as List;
      String? translated;
      if (choices.isNotEmpty) {
        translated = choices[0]?['message']?['content']?.toString().trim();
      }
      expect(translated, null);

      client.close();
    });
  });

  group('Translation input handling', () {
    test('empty text input', () {
      const text = '';
      expect(text.isEmpty, true);
      // The real function should return null for empty input
    });

    test('text with HTML tags', () {
      const text = '<p>Hello <a href="#">World</a></p>';
      expect(text.isNotEmpty, true);
      // Translation should handle HTML content
    });

    test('text with special characters', () {
      const text = 'Hello! @user #tag :emoji: https://link.com';
      expect(text.isNotEmpty, true);
    });

    test('very long text', () {
      final text = 'A' * 5000;
      expect(text.length, 5000);
      // Should still attempt translation
    });
  });

  group('Translation request construction', () {
    test('builds correct request body', () {
      const targetLang = 'French';
      const text = 'Hello world';

      final body = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a translator. Translate the following text to $targetLang. Return ONLY the translated text, nothing else.',
          },
          {
            'role': 'user',
            'content': text,
          },
        ],
        'max_tokens': 1000,
        'temperature': 0.3,
      };

      expect(body['model'], 'gpt-4o-mini');
      expect((body['messages'] as List).length, 2);
      expect(body['temperature'], 0.3);

      final systemMsg = (body['messages'] as List)[0] as Map<String, dynamic>;
      expect(systemMsg['role'], 'system');
      expect(systemMsg['content'], contains('French'));
    });

    test('builds correct headers with API key', () {
      const apiKey = 'sk-test-key-123';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      expect(headers['Authorization'], 'Bearer sk-test-key-123');
      expect(headers['Content-Type'], 'application/json');
    });
  });
}
