import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/flavor_config.dart';
import '../models/user_profile.dart';
import '../utils/rate_limiter.dart';
import 'logger_service.dart';

class AuthService {
  @visibleForTesting
  static SupabaseClient? mockClient;

  static SupabaseClient get _client => mockClient ?? SupabaseConfig.client;

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
      debugPrint('AuthService: Attempting sign in for $email...');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('AuthService: Sign in successful for $email');
      // Log Success
      await LoggerService.logAuth(email: email, success: true);
      
      // Reset limit on success
      RateLimiter.reset('login');
      return response;
    } on AuthException catch (e) {
      debugPrint('AuthService: AuthException during sign in: ${e.message} (Status: ${e.statusCode})');
      // Log Failure
      await LoggerService.logAuth(email: email, success: false, errorCode: e.toString());
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected error during sign in: $e');
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
    } catch (e) {
      debugPrint('Error in getUserProfile: $e');
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
    final email = finalUser.email ?? '';
    if (email.isEmpty) throw Exception('User email is required for sync');
    final metadata = finalUser.userMetadata ?? {};
    final appMetadata = finalUser.appMetadata;
    
    debugPrint('AuthService: Syncing user $email (ID: $userId). Current Flavor: ${FlavorConfig.flavor}');

    try {
      // 1. Determine the source-of-truth role
      // --- ROLE IDENTIFICATION HIERARCHY ---
      String? identifiedRole;
      debugPrint('AuthService: Starting role identification for $email');
      debugPrint('AuthService: AppMetadata: $appMetadata');
      debugPrint('AuthService: UserMetadata: $metadata');

      // Helper to parse role from various formats (String or List)
      String? parseRole(dynamic roleData) {
        if (roleData == null) return null;
        if (roleData is List) {
          return roleData.isNotEmpty ? roleData.first.toString().toLowerCase() : null;
        }
        return roleData.toString().toLowerCase();
      }

      // A. Check app_metadata (most secure, set by admin/triggers)
      identifiedRole = parseRole(appMetadata['role']);
      if (identifiedRole != null) {
        debugPrint('AuthService: [STEP A] Identified role from app_metadata: $identifiedRole');
      }

      // B. Check user_metadata (fallback)
      if (identifiedRole == null || identifiedRole == 'customer') {
        final metaRole = parseRole(metadata['role']);
        if (metaRole != null) {
          identifiedRole = metaRole;
          debugPrint('AuthService: [STEP B] Identified role from user_metadata: $identifiedRole');
        }
      }

      // C. Check 'riders' table (Strong check for riders)
      // Even if we identified as 'customer' or null above, we MUST check if they exist in riders table
      // as that table is the source of truth for rider status.
      if (identifiedRole != 'rider' && identifiedRole != 'admin') {
        try {
          debugPrint('AuthService: [STEP C] Querying riders table for ID: $userId');
          final riderRecord = await _client
              .from('riders')
              .select('id')
              .eq('id', userId)
              .maybeSingle();
          
          if (riderRecord != null) {
            identifiedRole = 'rider';
            debugPrint('AuthService: [STEP C] FOUND in riders table. Overriding to RIDER.');
          } else {
            debugPrint('AuthService: [STEP C] Not found in riders table.');
          }
        } catch (e) {
          debugPrint('AuthService: [STEP C] Riders table check failed: $e');
        }
      }

      // D. Check existing 'User' table record
      if (identifiedRole == null || identifiedRole == 'customer') {
        try {
          debugPrint('AuthService: [STEP D] Querying User table for ID: $userId');
          var existing = await _client
              .from('User')
              .select('role')
              .eq('supabaseId', userId)
              .maybeSingle();
          
          if (existing == null && email.isNotEmpty) {
            debugPrint('AuthService: [STEP D] Querying User table by email: $email');
            existing = await _client
                .from('User')
                .select('role')
                .ilike('email', email.toLowerCase())
                .maybeSingle();
          }
          
          if (existing != null && existing['role'] != null) {
            identifiedRole = parseRole(existing['role']);
            debugPrint('AuthService: [STEP D] Identified role from User table: $identifiedRole');
          } else {
            debugPrint('AuthService: [STEP D] Not found in User table or role is null.');
          }
        } catch (e) {
          debugPrint('AuthService: [STEP D] User table check failed: $e');
        }
      }

      // Final fallback
      final String finalRole = identifiedRole ?? 'customer';
      debugPrint('AuthService: FINAL IDENTIFIED ROLE: $finalRole');
      debugPrint('AuthService: Current App Flavor: ${FlavorConfig.flavor} (isCustomer: ${FlavorConfig.isCustomer}, isRider: ${FlavorConfig.isRider})');


      // 2. Prepare updates for the User table
      final updates = {
        'supabaseId': userId,
        'email': email,
        'fullName': metadata['full_name'] ?? metadata['name'] ?? '',
        'username': metadata['user_name'] ?? email.split('@')[0],
        'avatarUrl': metadata['avatar_url'] ?? metadata['picture'],
        'role': finalRole,
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 3. Upsert into User table
      debugPrint('AuthService: Upserting user record with role: $finalRole');
      final data = await _client.from('User').upsert(updates, onConflict: 'email').select().single();
      
      // 4. Update Auth Metadata to match (essential for Router redirects)
      // Only update if it's different to avoid unnecessary network calls
      if (metadata['role'] != finalRole) {
        debugPrint('AuthService: Updating Auth Metadata role to: $finalRole');
        try {
          await _client.auth.updateUser(UserAttributes(data: {'role': finalRole}));
        } catch (e) {
          debugPrint('AuthService: Failed to update auth metadata: $e');
          // Non-critical, continue
        }
      }

      // 5. SECURITY BLOCKING (Persistent)
      // Check if the user's role is permitted in this application flavor
      // Admins are permitted in both for management/testing.
      if (finalRole != 'admin') {
        if (FlavorConfig.isCustomer && finalRole == 'rider') {
          debugPrint('AuthService: SECURITY BLOCK! Rider detected in Customer App. Email: $email');
          // We sign out here to prevent the session from persisting in a blocked state
          await _client.auth.signOut();
          throw Exception('RIDER_NOT_ALLOWED: Riders cannot access the customer application.');
        }
        
        if (FlavorConfig.isRider && finalRole == 'customer') {
          debugPrint('AuthService: SECURITY BLOCK! Customer detected in Rider App. Email: $email');
          // We sign out here to prevent the session from persisting in a blocked state
          await _client.auth.signOut();
          throw Exception('CUSTOMER_NOT_ALLOWED: Customers cannot access the rider application.');
        }
      }

      debugPrint('AuthService: Sync successful for $email as $finalRole');
      return UserProfile.fromJson(data);
    } on AuthException catch (e) {
      debugPrint('AuthService: AuthException during profile sync: ${e.message} (Status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Profile sync failed with unexpected error: $e');
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

/// Extension to convert Supabase Auth State stream to a Listenable for GoRouter
extension AuthStreamExtension on Stream<AuthState> {
  Listenable asRefreshListenable() {
    final notifier = _DisposableValueNotifier<AuthState?>(null);
    final subscription = listen((state) => notifier.value = state);
    notifier._subscription = subscription;
    return notifier;
  }
}

/// ValueNotifier that cancels its stream subscription on dispose
class _DisposableValueNotifier<T> extends ValueNotifier<T> {
  _DisposableValueNotifier(super.value);
  
  dynamic _subscription;
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

