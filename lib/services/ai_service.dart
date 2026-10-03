import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  // Supply this only for local testing with --dart-define. Never commit a key.
  static const String _apiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  static Future<String> checkTip(double subtotal, double tip) async {
    if (_apiKey.isEmpty) {
      return 'AI analysis is unavailable because no API key is configured. '
          'Connect this feature to a secure backend before enabling it.';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant that evaluates if a restaurant tip is appropriate based on common standards (15-20%).'
            },
            {
              'role': 'user',
              'content':
                  'I paid a tip of \$$tip on a subtotal of \$$subtotal. Is this a correct or standard amount? Give me a brief evaluation, and check to see if they included the tax as part of the tipping amount.'
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error from AI Service: ${response.statusCode}";
      }
    } catch (e) {
      return "Failed to connect to AI Service: $e";
    }
  }
}
