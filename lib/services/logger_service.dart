import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

enum LogLevel { info, warning, error, critical }

class LoggerService {
  static SupabaseClient? get _supabase {
    try {
      return SupabaseConfig.client;
    } catch (_) {
      return null;
    }
  }

  /// Logs a security or system event to Supabase for audit purposes.
  static Future<void> logEvent({
    required String event,
    required String message,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? metadata,
  }) async {
    final user = AuthService.currentUser;
    final Map<String, dynamic> logData = {
      'event': event,
      'message': message,
      'level': level.name,
      'userId': user?.id,
      'userEmail': user?.email,
      'ipAddress': kIsWeb ? 'web_client' : 'mobile_client',
      'metadata': {
        ...?metadata,
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': DateTime.now().toIso8601String(),
        'debug': kDebugMode,
      },
    };

    try {
      // Print to console for development
      debugPrint('LOG [${level.name.toUpperCase()}]: $event - $message');

      // Save to Supabase
      final client = _supabase;
      if (client != null) {
        await client.from('audit_logs').insert(logData);
      }
    } catch (e) {
      debugPrint('LoggerService Error: Failed to save log: $e');
      // We don't rethrow here to prevent logger failure from breaking the app
    }
  }


  /// Logs an informational message
  static Future<void> logInfo(String message, {Map<String, dynamic>? metadata}) async {
    await logEvent(
      event: 'info',
      message: message,
      level: LogLevel.info,
      metadata: metadata,
    );
  }

  /// Logs a warning message
  static Future<void> logWarning(String message, {Map<String, dynamic>? metadata}) async {
    await logEvent(
      event: 'warning',
      message: message,
      level: LogLevel.warning,
      metadata: metadata,
    );
  }

  /// Specialized log for authentication attempts
  static Future<void> logAuth({
    required String email,
    required bool success,
    String? errorCode,
  }) async {
    await logEvent(
      event: success ? 'auth_success' : 'auth_failure',
      message: success ? 'User logged in successfully' : 'Login failed for $email',
      level: success ? LogLevel.info : LogLevel.warning,
      metadata: {
        'email': email,
        'errorCode': errorCode,
      },
    );
  }

  /// Specialized log for API or System errors
  static Future<void> logError(String caughtError, {StackTrace? stackTrace}) async {
    await logEvent(
      event: 'system_error',
      message: caughtError,
      level: LogLevel.error,
      metadata: {
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
  }

  /// Logs unusual traffic or behavior patterns
  static Future<void> logSuspiciousActivity({
    required String reason,
    Map<String, dynamic>? details,
  }) async {
    await logEvent(
      event: 'suspicious_activity',
      message: 'Suspicious behavior detected: $reason',
      level: LogLevel.critical,
      metadata: details,
    );
  }
}
