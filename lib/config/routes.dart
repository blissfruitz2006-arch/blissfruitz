import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/responsive_scaffold.dart';
import '../screens/public/home_screen.dart';
import '../screens/public/shop_screen.dart';
import '../screens/public/product_detail_screen.dart';
import '../screens/public/cart_screen.dart';
import '../screens/public/checkout_screen.dart';
import '../screens/public/blog_list_screen.dart';
import '../screens/public/blog_detail_screen.dart';
import '../screens/public/contact_screen.dart';
import '../screens/public/profile_screen.dart';
import '../screens/public/order_history_screen.dart';
import '../screens/public/order_tracking_screen.dart';
import '../screens/public/order_tracking_lookup_screen.dart';
import '../screens/public/address_screen.dart';
import '../screens/public/maintenance_screen.dart';
import '../screens/public/order_success_screen.dart';
import '../screens/public/order_failed_screen.dart';
import '../screens/public/settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/admin_layout.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/products/product_list_screen.dart';
import '../screens/admin/products/product_form_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/orders/order_list_screen.dart';
import '../screens/admin/orders/order_detail_screen.dart';
import '../screens/admin/customers/customer_list_screen.dart';
import '../screens/admin/content/banner_manager_screen.dart';
import '../screens/admin/content/offer_manager_screen.dart';
import '../screens/admin/content/blog_manager_screen.dart';
import '../screens/admin/coupons/coupon_manager_screen.dart';
import '../screens/admin/reviews/review_manager_screen.dart';
import '../screens/admin/messages/message_list_screen.dart';
import '../screens/admin/settings/settings_screen.dart';
import '../screens/admin/sticker_generator_screen.dart';
import '../screens/public/static_page_screen.dart';
import './static_content.dart';
import '../screens/public/edit_profile_screen.dart';
import '../screens/public/change_password_screen.dart';
import '../screens/public/faq_screen.dart';

import '../models/product.dart';
import '../services/auth_service.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';

// Keys moved outside to persist across provider re-evaluations
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    // Refresh the router when auth state or maintenance status changes
    refreshListenable: Listenable.merge([
      AuthService.onAuthStateChange.asRefreshListenable(),
      _ProviderListenable(ref, userProfileProvider),
      _ProviderListenable(ref, maintenanceSettingsProvider),
    ]),
    redirect: (context, state) {
      final isLoggedIn = AuthService.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isMaintenanceRoute = state.matchedLocation == '/maintenance';

      // 1. Check Maintenance Mode (Highest Priority)
      final maintenanceState = ref.read(maintenanceSettingsProvider);
      final isMaintenanceEnabled = maintenanceState.valueOrNull?.enabled ?? false;

      // Check if current user is admin to bypass maintenance
      final isAdmin = ref.read(isAdminProvider);

      if (isMaintenanceEnabled && !isAdmin) {
        if (!isMaintenanceRoute && !state.matchedLocation.startsWith('/login')) {
          return '/maintenance';
        }
      } else if (!isMaintenanceEnabled && isMaintenanceRoute) {
        return '/';
      }

      // 2. Security: Protect admin routes
      final profileAsync = ref.read(userProfileProvider);
      
      // If we are on an admin route, we must ensure the user IS an admin
      if (isAdminRoute) {
        if (profileAsync.isLoading) return null; // Wait for profile
        if (!isAdmin) {
          return isLoggedIn ? '/' : '/login';
        }
      }

      // 3. Protected customer routes
      if (!isLoggedIn && (state.matchedLocation == '/checkout' || state.matchedLocation == '/profile')) {
        return '/login';
      }

      // 4. Logged in users shouldn't see login/register
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      // Admin routes - ShellRoute provides the sidebar/layout
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (context, state) => '/admin/dashboard',
          ),
          GoRoute(
            name: 'admin-dashboard',
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            name: 'admin-analytics',
            path: '/admin/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            name: 'admin-products',
            path: '/admin/products',
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/admin/products/new',
            builder: (context, state) {
              final product = state.extra as Product?;
              return ProductFormScreen(product: product);
            },
          ),
          GoRoute(
            path: '/admin/products/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final product = state.extra as Product?;
              return ProductFormScreen(product: product, productId: id);
            },
          ),
          GoRoute(
            name: 'admin-orders',
            path: '/admin/orders',
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return OrderListScreen(initialFilter: filter);
            },
          ),
          GoRoute(
            path: '/admin/orders/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
            name: 'admin-customers',
            path: '/admin/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            name: 'admin-sticker-generator',
            path: '/admin/sticker-generator',
            builder: (context, state) => const StickerGeneratorScreen(),
          ),
          GoRoute(
            name: 'admin-banners',
            path: '/admin/banners',
            builder: (context, state) => const BannerManagerScreen(),
          ),
          GoRoute(
            name: 'admin-offers',
            path: '/admin/offers',
            builder: (context, state) => const OfferManagerScreen(),
          ),
          GoRoute(
            name: 'admin-blogs',
            path: '/admin/blogs',
            builder: (context, state) => const BlogManagerScreen(),
          ),
          GoRoute(
            name: 'admin-coupons',
            path: '/admin/coupons',
            builder: (context, state) => const CouponManagerScreen(),
          ),
          GoRoute(
            name: 'admin-reviews',
            path: '/admin/reviews',
            builder: (context, state) => const ReviewManagerScreen(),
          ),
          GoRoute(
            name: 'admin-messages',
            path: '/admin/messages',
            builder: (context, state) => const MessageListScreen(),
          ),
          GoRoute(
            name: 'admin-settings',
            path: '/admin/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Shell route wraps all public pages with responsive scaffold
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildPageTransition(
              context: context,
              state: state,
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/shop',
            pageBuilder: (context, state) => _buildPageTransition(
              context: context,
              state: state,
              child: const ShopScreen(),
            ),
          ),
          GoRoute(
            path: '/product/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return ProductDetailScreen(slug: slug);
            },
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _buildPageTransition(
              context: context,
              state: state,
              child: const CartScreen(),
            ),
          ),
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/blog',
            builder: (context, state) => const BlogListScreen(),
          ),
          GoRoute(
            path: '/blog/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return BlogDetailScreen(slug: slug);
            },
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildPageTransition(
              context: context,
              state: state,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const PublicSettingsScreen(),
          ),
          GoRoute(
            path: '/order-history',
            builder: (context, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/addresses',
            builder: (context, state) => const AddressScreen(),
          ),
          GoRoute(
            path: '/order-success',
            builder: (context, state) {
              final orderId = state.uri.queryParameters['orderId'];
              return OrderSuccessScreen(orderId: orderId ?? '');
            },
          ),
          GoRoute(
            path: '/order-failed',
            builder: (context, state) {
              final error = state.uri.queryParameters['error'];
              return OrderFailedScreen(error: error);
            },
          ),
          GoRoute(
            path: '/order-tracking/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrderTrackingScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/track',
            builder: (context, state) => const OrderTrackingLookupScreen(),
          ),
          GoRoute(
            path: '/settings/edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/settings/change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/settings/faq',
            builder: (context, state) => const FAQScreen(),
          ),

          GoRoute(
            path: '/login',
            pageBuilder: (context, state) => _buildPageTransition(
              context: context,
              state: state,
              child: const LoginScreen(),
            ),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (context, state) => _buildPageTransition(
              context: context,
              state: state,
              child: const RegisterScreen(),
            ),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) => const StaticPageScreen(
              title: 'Terms & Conditions',
              content: StaticContent.terms,
            ),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const StaticPageScreen(
              title: 'Privacy Policy',
              content: StaticContent.privacy,
            ),
          ),
          GoRoute(
            path: '/shipping',
            builder: (context, state) => const StaticPageScreen(
              title: 'Shipping Info',
              content: StaticContent.shipping,
            ),
          ),
          GoRoute(
            path: '/returns',
            builder: (context, state) => const StaticPageScreen(
              title: 'Returns Policy',
              content: StaticContent.returns,
            ),
          ),
        ],
      ),
    ],
  );
});

// Helper for premium page transitions
CustomTransitionPage<T> _buildPageTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Premium fade + subtle scale for Android-optimized feel
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCirc),
          ),
          child: child,
        ),
      );
    },
  );
}

// Listenable that reacts to a Riverpod Provider
class _ProviderListenable extends ChangeNotifier {
  _ProviderListenable(Ref ref, ProviderBase provider) {
    ref.listen(provider, (_, _) => notifyListeners());
  }
}

// Extension to convert Stream/AsyncValue to Listenable for GoRouter
extension AuthStreamExtension on Stream<AuthState> {
  Listenable asRefreshListenable() {
    final notifier = ValueNotifier<AuthState?>(null);
    listen((state) => notifier.value = state);
    return notifier;
  }
}
