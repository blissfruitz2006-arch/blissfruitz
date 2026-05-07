import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import '../config/supabase_config.dart';
import 'logger_service.dart';

class InitializationService {
  static Future<void> initialize() async {
    debugPrint('🚀 Starting BlissFruitz initialization...');
    WidgetsFlutterBinding.ensureInitialized();
    
    // Allow native engine to settle
    await Future.delayed(const Duration(milliseconds: 200));

    // Global Error Handling
    _setupErrorHandling();

    // System UI Optimization
    _setupSystemUI();

    // Database
    try {
      debugPrint('🗄️ Initializing Supabase (Offline persistence enabled)...');
      if (SupabaseConfig.supabaseUrl.isEmpty) {
        debugPrint('⚠️ WARNING: Supabase URL is empty! App will likely crash or fail to load data.');
      }
      await SupabaseConfig.initialize();
      debugPrint('✅ Supabase initialized.');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // If we are offline, we can still proceed if auth is cached
      if (e.toString().contains('SocketException')) {
        debugPrint('ℹ️ Offline mode detected during Supabase initialization.');
      } else {
        rethrow;
      }
    }

    // Firebase (Push Notifications)
    if (!kIsWeb) {
      try {
        debugPrint('🔥 Initializing Firebase...');
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized.');
      } catch (e) {
        debugPrint('⚠️ Firebase initialization skipped: $e');
        debugPrint('ℹ️ App will continue without push notifications.');
      }
    }
    
    debugPrint('🏁 Initialization complete. Offline mode ready.');
  }

  static void _setupErrorHandling() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      LoggerService.logError(
        details.exceptionAsString(),
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      LoggerService.logError(
        error.toString(),
        stackTrace: stack,
      );
      return true;
    };
  }

  static void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
