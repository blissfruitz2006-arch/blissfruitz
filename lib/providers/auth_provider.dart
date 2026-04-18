import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Provides the AuthService instance
final authServiceProvider = Provider((ref) => AuthService());

/// Provides the current Supabase auth user state
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.onAuthStateChange;
});

/// Provides the current user's profile from our custom User table
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  (ref) => UserProfileNotifier(ref),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final Ref ref;
  StreamSubscription<AuthState>? _authSub;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen for auth changes and auto-refresh profile
    _authSub = AuthService.onAuthStateChange.listen((authState) {
      if (authState.session != null) {
        loadProfile();
      } else {
        state = const AsyncValue.data(null);
      }
    });

    // Initial load
    if (AuthService.isLoggedIn) {
      loadProfile();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadProfile() async {
    try {
      if (!AuthService.isLoggedIn) {
        state = const AsyncValue.data(null);
        return;
      }
      state = const AsyncValue.loading();
      final profile = await AuthService.syncAuthUser();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> deactivateAccount() async {
    final supabaseId = AuthService.currentUser?.id;
    if (supabaseId == null) return;
    await AuthService.deactivateAccount(supabaseId);
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    final currentProfile = state.valueOrNull;
    if (currentProfile == null) return;

    final supabaseId = AuthService.currentUser?.id;
    if (supabaseId == null) return;

    await AuthService.updateUserProfile(
      supabaseId: supabaseId,
      fullName: fullName,
      phone: phone,
      address: address,
      avatarUrl: avatarUrl,
    );
    await loadProfile();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

/// Convenience provider: whether the user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.valueOrNull != null;
});

/// Convenience provider: whether the user is an admin
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.valueOrNull?.role == 'admin';
});
