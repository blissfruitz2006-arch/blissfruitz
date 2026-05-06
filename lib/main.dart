import 'package:url_strategy/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  
  // Environment Variables
  // Prefer --dart-define (compile-time, secure for production builds)
  // Fallback to dotenv file for local development convenience
  if (SupabaseConfig.supabaseUrl.isEmpty) {
    try {
      debugPrint('📦 Loading environment variables from dotenv...');
      await dotenv.load(fileName: "supabase_env.txt");
      SupabaseConfig.setRuntimeValues(
        url: dotenv.get('SUPABASE_URL', fallback: ''),
        key: dotenv.get('SUPABASE_ANON_KEY', fallback: ''),
      );
      debugPrint('✅ Environment variables loaded from dotenv.');
    } catch (e) {
      debugPrint('⚠️ No dotenv file found (expected in production): $e');
    }
  } else {
    debugPrint('✅ Environment variables loaded from --dart-define.');
  }
  
  runApp(
    const ProviderScope(
      child: BlissFruitzApp(),
    ),
  );
}
