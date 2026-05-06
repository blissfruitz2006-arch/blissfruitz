import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../utils/rate_limiter.dart';

class ContactService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<void> submitMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    // 1. Client-side Throttling
    if (!RateLimiter.isAllowed('contact_message', maxAttempts: 2, window: const Duration(minutes: 30))) {
      throw Exception('You are sending messages too quickly. Please wait a while.');
    }

    // 2. Server-side Rate Limiting
    final isAllowed = await _client.rpc('check_rate_limit', params: {
      'p_indicator': 'contact_$email',
      'p_max_attempts': 3,
      'p_window_minutes': 60,
      'p_block_minutes': 1440, // Block for 24 hours if limit exceeded
    });

    if (isAllowed == false) {
      throw Exception('Spam Protection: You have reached the maximum number of messages for today.');
    }

    try {
      await _client.from('contact_messages').insert({
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      });
      
      // Reset local limit on successful submission
      RateLimiter.reset('contact_message');

      // Attempt to invoke the edge function to send an email notification
      try {
        final response = await _client.functions.invoke(
          'send-email',
          body: {
            'name': name,
            'email': email,
            'subject': subject,
            'message': message,
          },
        );
        
        if (response.status != 200) {
          debugPrint('Email notification failed with status ${response.status}: ${response.data}');
        } else {
          debugPrint('Email notification sent successfully: ${response.data}');
        }
      } catch (emailError) {
        // We catch this to not block the user if only the email notification failed.
        debugPrint('Failed to send email notification (Edge Function error): $emailError');
      }
    } catch (e) {
      debugPrint('ContactService Error: $e');
      rethrow;
    }
  }
}
