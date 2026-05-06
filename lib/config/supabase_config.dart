import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
export 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthChangeEvent, AuthState;

class SupabaseConfig {
  // Use --dart-define for compile-time injection (secure, not bundled in assets)
  // Fallback to env for local development convenience
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get storageBaseUrl => '$supabaseUrl/storage/v1/object/public';

  // Runtime values loaded from dotenv (fallback for dev)
  static String _runtimeUrl = '';
  static String _runtimeKey = '';

  static String get effectiveUrl =>
      supabaseUrl.isNotEmpty ? supabaseUrl : _runtimeUrl;
  static String get effectiveKey =>
      supabaseAnonKey.isNotEmpty ? supabaseAnonKey : _runtimeKey;

  /// Set runtime values from dotenv (called from main.dart for dev convenience)
  static void setRuntimeValues({required String url, required String key}) {
    _runtimeUrl = url;
    _runtimeKey = key;
  }

  static Future<void> initialize() async {
    final url = effectiveUrl.trim();
    final key = effectiveKey.trim();

    // Remove trailing slash if present to prevent 404 on auth endpoints
    final normalizedUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    debugPrint('🗄️ Initializing Supabase with URL: $normalizedUrl');

    if (normalizedUrl.isEmpty || key.isEmpty) {
      throw Exception(
        'Supabase environment variables NOT found. '
        'Use --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
        'or provide a .env file for development.',
      );
    }

    await Supabase.initialize(url: normalizedUrl, anonKey: key);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
