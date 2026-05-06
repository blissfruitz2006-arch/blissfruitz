import 'package:flutter_test/flutter_test.dart';
import 'package:blissfruitz/utils/rate_limiter.dart';

void main() {
  group('AuthService Local RateLimiter Tests', () {
    setUp(() {
      // Clear out the rate limiter state before each test
      RateLimiter.reset('login');
      RateLimiter.reset('register');
    });

    test('Allows initial login attempt', () {
      final isAllowed = RateLimiter.isAllowed(
        'login',
        maxAttempts: 5,
        window: const Duration(minutes: 5),
      );
      expect(isAllowed, isTrue);
    });

    test('Blocks after max login attempts exceeded', () {
      // Simulate 5 attempts (the max)
      for (var i = 0; i < 5; i++) {
        RateLimiter.isAllowed(
          'login',
          maxAttempts: 5,
          window: const Duration(minutes: 5),
        );
      }

      // The 6th attempt should be blocked
      final isBlocked = !RateLimiter.isAllowed(
        'login',
        maxAttempts: 5,
        window: const Duration(minutes: 5),
      );
      
      expect(isBlocked, isTrue);
    });

    test('Blocks after max register attempts exceeded', () {
      // Register allows 3 attempts per hour
      for (var i = 0; i < 3; i++) {
        RateLimiter.isAllowed(
          'register',
          maxAttempts: 3,
          window: const Duration(hours: 1),
        );
      }

      // The 4th attempt should be blocked
      final isBlocked = !RateLimiter.isAllowed(
        'register',
        maxAttempts: 3,
        window: const Duration(hours: 1),
      );
      
      expect(isBlocked, isTrue);
    });

    test('Reset clears the limits', () {
      for (var i = 0; i < 5; i++) {
        RateLimiter.isAllowed(
          'login',
          maxAttempts: 5,
          window: const Duration(minutes: 5),
        );
      }

      expect(
        RateLimiter.isAllowed('login', maxAttempts: 5, window: const Duration(minutes: 5)),
        isFalse,
      );

      RateLimiter.reset('login');

      expect(
        RateLimiter.isAllowed('login', maxAttempts: 5, window: const Duration(minutes: 5)),
        isTrue,
      );
    });
  });
}
