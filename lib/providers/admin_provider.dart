import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/banner_model.dart';
import '../models/offer.dart';
import '../models/blog_post.dart';
import '../models/coupon.dart';
import '../models/review.dart';
import '../services/admin_service.dart';

final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  return AdminService.getAdminProducts();
});

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return AdminService.getAdminStats();
});

final adminOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  return AdminService.getAllOrdersStream();
});

final orderSearchQueryProvider = StateProvider<String>((ref) => '');
final orderStatusFilterProvider = StateProvider<String?>((ref) => null);

final filteredAdminOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(adminOrdersProvider);
  final query = ref.watch(orderSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(orderStatusFilterProvider);

  return ordersAsync.whenData((list) {
    return list.where((order) {
      final orderNumber = (order.orderNumber ?? '').toLowerCase();
      final customerName = (order.shippingName ?? '').toLowerCase();
      final status = order.orderStatus.toLowerCase();

      final matchesQuery = query.isEmpty || 
          orderNumber.contains(query) || 
          customerName.contains(query);
      
      final matchesStatus = statusFilter == null || status == statusFilter.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();
  });
});

final adminCustomersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return AdminService.getAdminCustomersStream();
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');
final customerRoleFilterProvider = StateProvider<String?>((ref) => null);
final customerSortProvider = StateProvider<CustomerSort>((ref) => CustomerSort.newest);

enum CustomerSort { newest, oldest, nameAZ, nameZA, mostSpent, mostOrders }

final selectedCustomersProvider = StateProvider<Set<String>>((ref) => {});

final filteredAdminCustomersProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final customersAsync = ref.watch(adminCustomersProvider);
  final query = ref.watch(customerSearchQueryProvider).toLowerCase();
  final roleFilter = ref.watch(customerRoleFilterProvider);
  final sort = ref.watch(customerSortProvider);

  return customersAsync.whenData((list) {
    var filtered = list.where((user) {
      final name = (user['fullName'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString();
      final isActive = user['isActive'] ?? true;

      final matchesQuery = query.isEmpty || 
          name.contains(query) || 
          email.contains(query) || 
          phone.contains(query);
      
      final matchesRole = roleFilter == null || 
          (roleFilter == 'blocked' ? !isActive : role == roleFilter);

      return matchesQuery && matchesRole;
    }).toList();

    // Sorting
    switch (sort) {
      case CustomerSort.newest:
        filtered.sort((a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()));
        break;
      case CustomerSort.oldest:
        filtered.sort((a, b) => a['createdAt'].toString().compareTo(b['createdAt'].toString()));
        break;
      case CustomerSort.nameAZ:
        filtered.sort((a, b) => (a['fullName'] ?? '').toString().toLowerCase().compareTo((b['fullName'] ?? '').toString().toLowerCase()));
        break;
      case CustomerSort.nameZA:
        filtered.sort((a, b) => (b['fullName'] ?? '').toString().toLowerCase().compareTo((a['fullName'] ?? '').toString().toLowerCase()));
        break;
      case CustomerSort.mostSpent:
        filtered.sort((a, b) {
          final aOrders = a['Order'] as List? ?? [];
          final bOrders = b['Order'] as List? ?? [];
          final aSpent = aOrders.fold<double>(0.0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0.0));
          final bSpent = bOrders.fold<double>(0.0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0.0));
          return bSpent.compareTo(aSpent);
        });
        break;
      case CustomerSort.mostOrders:
        filtered.sort((a, b) {
          final aOrders = (a['Order'] as List? ?? []).length;
          final bOrders = (b['Order'] as List? ?? []).length;
          return bOrders.compareTo(aOrders);
        });
        break;
    }

    return filtered;
  });
});

final adminBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  return AdminService.getAdminBanners();
});

final adminOffersProvider = FutureProvider<List<Offer>>((ref) async {
  return AdminService.getAdminOffers();
});

final adminBlogsProvider = FutureProvider<List<BlogPost>>((ref) async {
  return AdminService.getAdminBlogs();
});

final adminCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  return AdminService.getAdminCoupons();
});

final adminReviewsProvider = FutureProvider<List<Review>>((ref) async {
  return AdminService.getAdminReviews();
});

final adminMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return AdminService.getMessages();
});
