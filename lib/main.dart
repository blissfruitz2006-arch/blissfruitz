import 'package:url_strategy/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'app.dart';

import 'dart:async';

void main() async {
  // Ensure we catch everything from the start
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('🛑 FLUTTER ERROR: ${details.exception}');
      if (kDebugMode) {
        debugPrint(details.stack.toString());
      }
    };

    if (kIsWeb) {
      setPathUrlStrategy();
    }
    
    // Environment Variables
    try {
      if (SupabaseConfig.supabaseUrl.isEmpty) {
        debugPrint('📦 Loading environment variables from dotenv...');
        await dotenv.load(fileName: "assets/supabase_env.txt");
        SupabaseConfig.setRuntimeValues(
          url: dotenv.get('SUPABASE_URL', fallback: ''),
          key: dotenv.get('SUPABASE_ANON_KEY', fallback: ''),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Dotenv load error: $e');
    }
    
    runApp(
      const ProviderScope(
        child: BlissFruitzApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('🔥 FATAL UNCAUGHT ERROR: $error');
    debugPrint(stack.toString());
  });
}
