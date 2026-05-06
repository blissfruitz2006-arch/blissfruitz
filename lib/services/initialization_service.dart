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
    
    // Global Error Handling
    _setupErrorHandling();

    // System UI Optimization
    _setupSystemUI();

    // Environment variables are now loaded in main()



    // Database
    try {
      debugPrint('🗄️ Initializing Supabase...');
      await SupabaseConfig.initialize();
      debugPrint('✅ Supabase initialized.');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      rethrow; // Re-throw to prevent app from proceeding in a broken state
    }

    // Firebase (Push Notifications)
    if (!kIsWeb) {
      try {
        debugPrint('🔥 Initializing Firebase...');
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized.');
      } catch (e) {
        debugPrint('⚠️ Firebase initialization failed: $e');
        // Firebase failure is usually non-fatal for core app flow
      }
    }
    
    debugPrint('🏁 Initialization complete.');
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
