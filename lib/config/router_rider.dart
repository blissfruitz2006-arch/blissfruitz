import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

// Models
import '../models/delivery_assignment.dart';

// Widgets
import '../widgets/responsive_scaffold.dart';

// Screens
import '../screens/auth/login_screen.dart';
import '../screens/rider/rider_home_screen.dart';
import '../screens/rider/order_detail_screen.dart';
import '../screens/rider/navigation_screen.dart';
import '../screens/rider/earnings_screen.dart';
import '../screens/rider/rider_profile_screen.dart';

/// A [Listenable] that notifies listeners whenever the provided [stream] emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}



final riderRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/rider/home',
    refreshListenable: Listenable.merge([
      Supabase.instance.client.auth.onAuthStateChange.asRefreshListenable(),
      _ProviderListenable(ref, userProfileProvider),
    ]),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final user = session?.user;
      
      // Read the profile state
      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.valueOrNull;
      
      // Determine role with fallback hierarchy
      String role = profile?.role ?? 
                     user?.appMetadata['role'] ?? 
                     user?.userMetadata?['role'] ?? 
                     ''; // Default to empty while loading
      
      if (user != null) {
        debugPrint('Rider Router: User: ${user.email}, Role in DB/Meta: $role, Profile Loading: ${profileAsync.isLoading}');
      }

      // 1. If we have a profile error (e.g. blocking logic triggered), redirect to login
      if (profileAsync.hasError) {
        final error = profileAsync.error.toString();
        debugPrint('Rider Router: Profile Error detected: $error');
        if (error.toLowerCase().contains('customer')) {
          return '/auth/login?error=customer_not_allowed';
        }
        if (error.toLowerCase().contains('rider')) {
          return '/auth/login?error=rider_not_allowed';
        }
        return '/auth/login?error=auth_error';
      }

      final bool isLoggingIn = state.uri.path == '/auth/login';

      // 2. Not logged in → /auth/login
      if (session == null) {
        return isLoggingIn ? null : '/auth/login';
      }

      // 3. Logged in but profile is still loading (and no role in metadata)
      if (role.isEmpty && profileAsync.isLoading) {
        debugPrint('Rider Router: Waiting for profile/role identification...');
        return null; 
      }
      
      // If still empty after loading, we might have a problem
      if (role.isEmpty) {
        debugPrint('Rider Router: No role identified after loading. Redirecting to login.');
        return '/auth/login?error=unknown_role';
      }

      // 4. Logged in + role is NOT 'rider' → back to /auth/login + show error
      if (role != 'rider' && role != 'admin') {
        if (!isLoggingIn) {
          debugPrint('Rider Router: Blocking non-rider user. Role: $role');
          return '/auth/login?error=rider_only';
        }
        return null;
      }

      // 5. Logged in + role = 'rider' + on /auth/login → /rider/home
      if (isLoggingIn && (role == 'rider' || role == 'admin')) {
        return '/rider/home';
      }

      return null;
    },
    routes: [
      // AUTH
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // RIDER - Wrapped in ShellRoute for Header & Navigation
      ShellRoute(
        builder: (context, state, child) => ResponsiveScaffold(state: state, child: child),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, _) => '/rider/home',
          ),
          GoRoute(
            path: '/home',
            redirect: (_, _) => '/rider/home',
          ),
          GoRoute(
            path: '/cart',
            redirect: (_, _) => '/rider/home',
          ),
          GoRoute(
            path: '/profile',
            redirect: (_, _) => '/rider/profile',
          ),
          GoRoute(
            path: '/earnings',
            redirect: (_, _) => '/rider/earnings',
          ),
          GoRoute(
            name: 'rider-home',
            path: '/rider/home',
            builder: (context, state) => const RiderHomeScreen(),
          ),
          GoRoute(
            name: 'rider-order-detail',
            path: '/rider/order/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final assignment = state.extra as DeliveryAssignment?;
              return OrderDetailScreen(orderId: id, assignment: assignment);
            },
          ),
          GoRoute(
            name: 'rider-navigate',
            path: '/rider/navigate',
            builder: (context, state) {
              final assignment = state.extra as DeliveryAssignment?;
              final orderId = state.uri.queryParameters['orderId'];
              return NavigationScreen(orderId: orderId, assignment: assignment);
            },
          ),
          GoRoute(
            name: 'rider-earnings',
            path: '/rider/earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            name: 'rider-profile',
            path: '/rider/profile',
            builder: (context, state) => const RiderProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

// For backward compatibility or external access if needed
GoRouter get riderRouter => throw UnimplementedError('Use ref.watch(riderRouterProvider) instead');

class _ProviderListenable extends ChangeNotifier {
  _ProviderListenable(Ref ref, ProviderBase provider) {
    ref.listen(provider, (_, _) => notifyListeners());
  }
}
