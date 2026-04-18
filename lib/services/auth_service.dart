import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../utils/rate_limiter.dart';
import 'logger_service.dart';

class AuthService {
  static final _client = SupabaseConfig.client;

  /// Get the current Supabase auth user
  static User? get currentUser => _client.auth.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Listen for auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Sign in with email + password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // 1. Client-side Throttling (Immediate feedback)
    if (!RateLimiter.isAllowed('login', maxAttempts: 5, window: const Duration(minutes: 5))) {
      final wait = RateLimiter.getRemainingWaitTime('login', const Duration(minutes: 5));
      throw Exception('Too many login attempts (local). Please wait ${wait.inMinutes}m ${wait.inSeconds % 60}s.');
    }

    // 2. Server-side Throttling (Persistent protection)
    final isAllowed = await _checkServerSideRateLimit(
      indicator: 'login_$email',
      maxAttempts: 5,
      windowMinutes: 15,
      blockMinutes: 30,
    );
    
    if (!isAllowed) {
      await LoggerService.logSuspiciousActivity(
        reason: 'Brute-force attempt blocked by server',
        details: {'email': email, 'action': 'login'},
      );
      throw Exception('Security Block: Too many attempts. Access for this email is temporarily restricted for 30 minutes.');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Log Success
      await LoggerService.logAuth(email: email, success: true);
      
      // Reset limit on success
      RateLimiter.reset('login');
      return response;
    } catch (e) {
      // Log Failure
      await LoggerService.logAuth(email: email, success: false, errorCode: e.toString());
      rethrow;
    }
  }

  /// Register new user with email + password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    // Local check
    if (!RateLimiter.isAllowed('register', maxAttempts: 3, window: const Duration(hours: 1))) {
      final wait = RateLimiter.getRemainingWaitTime('register', const Duration(hours: 1));
      throw Exception('Too many account creation attempts. Please wait ${wait.inMinutes} minutes.');
    }

    // Server-side check (indicator is email to prevent spamming many accounts from same IP or vice versa)
    final isAllowed = await _checkServerSideRateLimit(
      indicator: 'register_$email',
      maxAttempts: 2,
      windowMinutes: 60,
      blockMinutes: 120,
    );
    
    if (!isAllowed) {
      throw Exception('Account creation limit reached. Please try again later.');
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'username': username,
      },
    );

    // Profile sync only if session is available (email confirmed or auto-confirm)
    if (response.user != null && response.session != null) {
      await LoggerService.logEvent(
        event: 'account_created',
        message: 'New user registered: $email',
        metadata: {'email': email},
      );
      RateLimiter.reset('register');
      await syncAuthUser(user: response.user);
    } else if (response.user != null) {
      // User created but needs email confirmation
      await LoggerService.logEvent(
        event: 'account_created_pending',
        message: 'New user registered (pending confirmation): $email',
        metadata: {'email': email},
      );
      RateLimiter.reset('register');
      // Still attempt to sync the user profile even without a session
      // This ensures the record exists in our custom table
      try {
        await syncAuthUser(user: response.user);
      } catch (e) {
        debugPrint('Post-registration sync (pre-confirmation) failed: $e');
      }
    }

    return response;
  }

  /// Sign in with Google (OAuth)
  static Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'blissfruitz://login-callback',
    );
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update password (after reset link)
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch the user profile from our custom User table
  static Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // 1. Try by supabaseId
      var data = await _client
          .from('User')
          .select()
          .eq('supabaseId', user.id)
          .maybeSingle();

      // 2. Fallback to email if not found by ID yet
      if (data == null && user.email != null) {
        data = await _client
            .from('User')
            .select()
            .eq('email', user.email!)
            .maybeSingle();
      }

      if (data != null) {
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deactivate user account
  static Future<void> deactivateAccount(String supabaseId) async {
    await _client.from('User').update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('supabaseId', supabaseId);
    await signOut();
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String supabaseId,
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    await _client.from('User').update(updates).eq('supabaseId', supabaseId);
  }

  /// Upload profile image
  static Future<String> uploadProfileImage(String supabaseId, Uint8List bytes) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = '$supabaseId/$fileName';

    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
    );
    
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Synchronize Supabase Auth user with our custom User table
  static Future<UserProfile> syncAuthUser({User? user}) async {
    final finalUser = user ?? currentUser;
    if (finalUser == null) throw Exception('No user logged in');

    final userId = finalUser.id;
    final email = finalUser.email!;
    final metadata = finalUser.userMetadata ?? {};

    try {
      // Prepare updates
      final updates = {
        'supabaseId': userId,
        'email': email,
        'fullName': metadata['full_name'] ?? metadata['name'] ?? '',
        'username': metadata['user_name'] ?? email.split('@')[0],
        'avatarUrl': metadata['avatar_url'] ?? metadata['picture'],
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Find existing record to preserve role
      var existing = await _client.from('User').select().eq('supabaseId', userId).maybeSingle();
      existing ??= await _client.from('User').select().eq('email', email).maybeSingle();

      if (existing != null) {
        updates['role'] = existing['role'] ?? 'customer';
      } else {
        updates['role'] = 'customer';
      }

      final data = await _client.from('User').upsert(updates, onConflict: 'email').select().single();
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('AuthService: Profile sync failed: $e');
      rethrow;
    }
  }

  /// Check if the current user is an admin
  static Future<bool> isAdmin() async {
    final profile = await getUserProfile();
    return profile?.role == 'admin';
  }

  /// Helper for server-side rate limiting
  static Future<bool> _checkServerSideRateLimit({
    required String indicator,
    required int maxAttempts,
    required int windowMinutes,
    required int blockMinutes,
  }) async {
    try {
      final result = await _client.rpc('check_rate_limit', params: {
        'p_indicator': indicator,
        'p_max_attempts': maxAttempts,
        'p_window_minutes': windowMinutes,
        'p_block_minutes': blockMinutes,
      });
      return result as bool;
    } catch (e) {
      // In case of RPC failure, we fall back to allowing (fail-open) 
      // but log the error so we can fix the infrastructure
      debugPrint('AuthService: Rate limit RPC failed: $e');
      return true; 
    }
  }
}
