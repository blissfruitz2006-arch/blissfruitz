import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/logger_service.dart';

/// A simple client-side rate limiter / throttler to prevent abuse of buttons
/// and API endpoints from the UI.
class RateLimiter {
  static final Map<String, _RateLimitState> _states = {};

  /// Checks if an action is allowed based on the provided limit and window.
  /// [key] is a unique identifier for the action (e.g., 'login', 'register').
  /// [maxAttempts] is the number of allowed attempts in the window.
  /// [window] is the duration after which the attempts reset.
  static bool isAllowed(String key, {int maxAttempts = 5, Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final state = _states[key];

    if (state == null || now.difference(state.startTime) > window) {
      _states[key] = _RateLimitState(startTime: now, attempts: 1);
      return true;
    }

    if (state.attempts >= maxAttempts) {
      LoggerService.logSuspiciousActivity(
        reason: 'Rate limit exceeded for key: $key',
        details: {
          'key': key,
          'attempts': state.attempts,
          'window': window.toString(),
        },
      );
      return false;
    }

    state.attempts++;
    return true;
  }

  /// Gets the remaining wait time for a specific key.
  static Duration getRemainingWaitTime(String key, Duration window) {
    final state = _states[key];
    if (state == null) return Duration.zero;
    
    final remaining = window - DateTime.now().difference(state.startTime);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Resets the rate limit for a specific key (e.g., after a successful login).
  static void reset(String key) {
    _states.remove(key);
  }
}

class _RateLimitState {
  final DateTime startTime;
  int attempts;

  _RateLimitState({required this.startTime, required this.attempts});
}

/// A mixin to add throttling capability to any class (e.g., Providers or Services)
mixin Throttler {
  final Map<String, bool> _isProcessing = {};

  /// Prevents concurrent execution of the same action.
  Future<T?> throttle<T>(String key, Future<T> Function() action) async {
    if (_isProcessing[key] == true) {
      debugPrint('Throttler: Action "$key" is already in progress. Ignoring.');
      return null;
    }

    _isProcessing[key] = true;
    try {
      return await action();
    } finally {
      _isProcessing[key] = false;
    }
  }
}
