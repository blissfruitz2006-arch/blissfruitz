import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/rate_limiter.dart';
import '../config/static_content.dart';

/// Service for handling AI-related requests using NVIDIA NIM API.
class AIService {
  static final String _baseUrl = "https://integrate.api.nvidia.com/v1";
  static String get _apiKey => const String.fromEnvironment('NVIDIA_API_KEY').isNotEmpty 
      ? const String.fromEnvironment('NVIDIA_API_KEY') 
      : dotenv.get('NVIDIA_API_KEY', fallback: '');
  static String get _model => dotenv.get('NVIDIA_MODEL', fallback: 'meta/llama-3.1-8b-instruct');

  /// Ensures that environment variables are loaded if not already.
  static Future<void> _ensureLoaded() async {
    if (_apiKey.isEmpty) {
      try {
        await dotenv.load(fileName: "assets/supabase_env.txt");
      } catch (e) {
        debugPrint('AIService: assets/supabase_env.txt not found/empty. Trying fallback...');
        try {
          await dotenv.load(fileName: "assets/env_config.txt");
        } catch (_) {}
      }
    }
  }

  /// Generates a response from the AI based on a list of messages (history).
  static Future<String> chatWithAI({
    required List<Map<String, String>> messages,
  }) async {
    await _ensureLoaded();
    // Abuse protection: Limit to 10 AI requests per 5 minutes per user session
    const String rateLimitKey = 'ai_chat';
    const int maxAttempts = 10;
    const Duration window = Duration(minutes: 5);

    if (!RateLimiter.isAllowed(rateLimitKey, maxAttempts: maxAttempts, window: window)) {
      final wait = RateLimiter.getRemainingWaitTime(rateLimitKey, window);
      throw Exception(
        'Chat limit reached. Please wait ${wait.inMinutes} minutes and ${wait.inSeconds % 60} seconds before trying again.'
      );
    }

    if (_apiKey.isEmpty || _apiKey == 'null' || _apiKey == '') {
      throw Exception('NVIDIA_API_KEY is not configured in the build environment. Please check your GitHub Secrets.');
    }

    try {
      debugPrint('AIService: Sending request to NVIDIA NIM ($_model)');

      // Construct system prompt with BlissFruitz business context
      final systemPrompt = '''
You are the "BlissFruitz Support Assistant," a friendly and professional AI help bot for the BlissFruitz e-commerce app.
BlissFruitz is a premium platform for fresh, seasonal, and exotic organic fruits (mangoes, berries, citrus, etc.).

Key Business Details:
- Slogan: "Nature's Sweetness, Delivered to Your Doorstep."
- Delivery: Express delivery in 20 minutes to 2 hours for local zones. Orders before 2 PM are usually same-day.
- Sourcing: Certified organic farms, tested for pesticides.
- Returns: Perishable items only refundable if quality is compromised at delivery (report within 24 hours with photos).
- Contact: support@blissfruitz.com or the "Contact Us" form in the app.
- Payment: COD and Online (Razorpay).

Your Tone:
- Professional yet warm and helpful.
- Concise and direct.
- If you don't know something specific about a customer's order, ask them to check "My Orders" or contact support@blissfruitz.com.

Safety Guardrails:
- Do not provide medical advice.
- Do not discuss topics unrelated to BlissFruitz or fresh fruits.
- Always be polite.

${StaticContent.terms}
''';

      final List<Map<String, String>> fullMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': fullMessages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        final error = jsonDecode(response.body);
        debugPrint('AIService API Error: ${response.body}');
        throw Exception(error['message'] ?? 'Failed to get response from AI');
      }
    } catch (e) {
      debugPrint('AIService Exception: $e');
      // Showing the raw error to help the user identify why it's failing
      rethrow;
    }
  }

  /// Original method maintained for backward compatibility (if used elsewhere)
  static Future<String> generateContent({
    required String prompt,
    String? context,
  }) async {
    return chatWithAI(messages: [
      if (context != null) {'role': 'user', 'content': 'Context: $context'},
      {'role': 'user', 'content': prompt},
    ]);
  }
}
