import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/responsive_scaffold.dart';
import '../screens/public/home_screen.dart';
import '../screens/public/shop_screen.dart';
import '../screens/public/product_detail_screen.dart';
import '../screens/public/cart_screen.dart';
import '../screens/public/checkout_screen.dart';
import '../screens/public/order_success_screen.dart';
import '../screens/public/order_failed_screen.dart';
import '../screens/public/blog_list_screen.dart';
import '../screens/public/blog_detail_screen.dart';
import '../screens/public/contact_screen.dart';
import '../screens/public/profile_screen.dart';
import '../screens/public/order_history_screen.dart';
import '../screens/public/order_tracking_screen.dart';
import '../screens/public/order_tracking_lookup_screen.dart';
import '../screens/public/address_screen.dart';
import '../screens/public/maintenance_screen.dart';
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
import '../screens/admin/sticker_generator_screen.dart';
import '../screens/admin/settings/admin_settings_screen.dart';
import '../screens/admin/riders/rider_list_screen.dart';
import '../screens/admin/riders/add_rider_screen.dart';
import '../screens/admin/riders/assign_rider_screen.dart';
import '../screens/public/static_page_screen.dart';
import './static_content.dart';
import '../screens/public/edit_profile_screen.dart';
import '../screens/public/change_password_screen.dart';
import '../screens/public/faq_screen.dart';
import '../screens/rider/rider_home_screen.dart';
import '../screens/rider/order_detail_screen.dart' as rider;
import '../screens/rider/navigation_screen.dart';
import '../screens/rider/earnings_screen.dart';
import '../screens/rider/rider_profile_screen.dart';
import '../screens/public/tracking/live_tracking_screen.dart';
import '../screens/public/delivery_area_screen.dart';
import '../screens/public/chat_screen.dart';

import '../models/product.dart';
import '../services/auth_service.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../config/flavor_config.dart';
import '../models/delivery_assignment.dart';

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
      final matchedLocation = state.matchedLocation;
      final isLoggingIn = matchedLocation == '/login';
      final isRegistering = matchedLocation == '/register';
      final isAuthRoute = isLoggingIn || isRegistering || matchedLocation == '/forgot-password';
      final isRiderRoute = matchedLocation.startsWith('/rider');
      final isAdminRoute = matchedLocation.startsWith('/admin');
      final isMaintenanceRoute = matchedLocation == '/maintenance';

      // 1. Maintenance Mode
      final maintenanceState = ref.read(maintenanceSettingsProvider);
      final isMaintenanceEnabled = maintenanceState.valueOrNull?.enabled ?? false;

      // Profile and Roles
      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.valueOrNull;
      final isAdmin = profile?.role == 'admin';
      final isRider = profile?.role == 'rider';

      if (isMaintenanceEnabled && !isAdmin) {
        if (!isMaintenanceRoute && !isAuthRoute) return '/maintenance';
      } else if (!isMaintenanceEnabled && isMaintenanceRoute) {
        return '/';
      }

      // 2. Auth protection
      if (!isLoggedIn) {
        if (isRiderRoute || isAdminRoute || matchedLocation == '/profile' || matchedLocation == '/checkout') {
          return '/login';
        }
        return null;
      }

      // 3. Security: Role protection
      if (isLoggedIn && FlavorConfig.isCustomer && isRider) {
        if (profileAsync.isLoading) return null;
        AuthService.signOut();
        return '/login?error=rider_not_allowed';
      }

      if (isAdminRoute && !isAdmin) {
        if (profileAsync.isLoading) return null;
        return '/';
      }

      if (isRiderRoute && !isRider && !isAdmin) {
        if (profileAsync.isLoading) return null;
        return '/';
      }

      // 4. Already logged in redirect from auth routes
      if (isAuthRoute) {
        if (profileAsync.isLoading) return null;
        if (isAdmin) return '/admin/dashboard';
        if (isRider) return '/rider/home';
        return '/';
      }

      // 5. Protect Customer routes from Riders
      if (isRider && !isRiderRoute && !isAuthRoute && !isMaintenanceRoute) {
        // Exclude static pages if riders should see them (terms, privacy, etc.)
        final isStaticRoute = matchedLocation == '/terms' || 
                             matchedLocation == '/privacy' || 
                             matchedLocation == '/shipping' || 
                             matchedLocation == '/returns';
        if (!isStaticRoute) {
          return '/rider/home';
        }
      }

      // 6. Root Redirect (Initial entry)
      if (matchedLocation == '/') {
        if (isAdmin) return '/admin/dashboard';
        if (isRider) return '/rider/home';
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
            name: 'admin-settings',
            path: '/admin/settings',
            builder: (context, state) => const AdminSettingsScreen(),
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
            name: 'admin-riders',
            path: '/admin/riders',
            builder: (context, state) => const RiderListScreen(),
          ),
          GoRoute(
            name: 'admin-add-rider',
            path: '/admin/riders/new',
            builder: (context, state) => const AddRiderScreen(),
          ),
          GoRoute(
            name: 'admin-assign-rider',
            path: '/admin/riders/assign/:orderId',
            builder: (context, state) {
              final idStr = state.pathParameters['orderId']!;
              return AssignRiderScreen(orderId: int.parse(idStr));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      // Shell route wraps all public pages with responsive scaffold
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffold(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            redirect: (context, state) => '/',
          ),
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
          // Local SEO: Neighborhood delivery landing pages
          GoRoute(
            path: '/delivery/:area',
            builder: (context, state) {
              final area = state.pathParameters['area']!;
              return DeliveryAreaScreen(area: area);
            },
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
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
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
            path: '/track/:orderId',
            builder: (context, state) {
              final id = state.pathParameters['orderId']!;
              return LiveTrackingScreen(orderId: int.parse(id));
            },
          ),
          GoRoute(
            path: '/live-tracking/:id',
            redirect: (context, state) => '/track/${state.pathParameters['id']}',
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
          GoRoute(
            path: '/rider',
            redirect: (context, state) {
              if (state.matchedLocation == '/rider') return '/rider/home';
              return null;
            },
          ),
          GoRoute(
            name: 'rider-home',
            path: '/rider/home',
            builder: (context, state) => const RiderHomeScreen(),
          ),
          GoRoute(
            name: 'rider-order-detail',
            path: '/rider/orders/:id',
            builder: (context, state) {
              final assignment = state.extra as DeliveryAssignment?;
              final id = state.pathParameters['id'];
              return rider.OrderDetailScreen(
                assignment: assignment,
                orderId: id,
              );
            },
          ),
          GoRoute(
            name: 'rider-navigation',
            path: '/rider/navigate/:id',
            builder: (context, state) {
              final assignment = state.extra as DeliveryAssignment?;
              final id = state.pathParameters['id'];
              return NavigationScreen(
                assignment: assignment,
                orderId: id,
              );
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

