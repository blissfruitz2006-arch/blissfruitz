import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/banner_model.dart';
import '../models/offer.dart';
import '../models/blog_post.dart';
import '../models/coupon.dart';
import '../models/review.dart';
import 'email_service.dart';
import 'order_service.dart';

class AdminService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  static Future<List<Product>> getAdminProducts() async {
    final response = await _supabase
        .from('Product')
        .select('*, Category(*)')
        .neq('isDeleted', true)
        .order('id', ascending: false);
    
    return (response as List).map((p) {
      return Product.fromJson(p);
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAdminCustomers() async {
    try {
      final response = await _supabase
          .from('User')
          .select('*, Order(total, orderStatus)')
          .order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService.getAdminCustomers error: $e');
      rethrow;
    }
  }

  static Future<void> toggleUserStatus(String supabaseId, bool isActive) async {
    await _supabase
        .from('User')
        .update({'isActive': isActive, 'updatedAt': DateTime.now().toIso8601String()})
        .eq('supabaseId', supabaseId);
  }

  static Future<void> updateUserRole(String supabaseId, String role) async {
    await _supabase
        .from('User')
        .update({'role': role, 'updatedAt': DateTime.now().toIso8601String()})
        .eq('supabaseId', supabaseId);
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final orders = await _supabase
          .from('Order')
          .select('total, orderStatus, createdAt')
          .eq('userId', userId)
          .order('createdAt', ascending: false);
      
      final list = orders as List;
      double totalSpent = 0;
      int activeCount = 0;
      DateTime? lastOrderDate;

      for (final item in list) {
        if (item['orderStatus'] != 'cancelled' && item['orderStatus'] != 'returned') {
          totalSpent += (double.tryParse(item['total']?.toString() ?? '0') ?? 0);
          activeCount++;
          if (lastOrderDate == null && item['createdAt'] != null) {
            try {
              lastOrderDate = DateTime.parse(item['createdAt'].toString());
            } catch (_) {
              debugPrint('Error parsing order createdAt: ${item['createdAt']}');
            }
          }
        }
      }
      
      return {
        'orderCount': list.length,
        'activeOrderCount': activeCount,
        'totalSpent': totalSpent,
        'avgOrderValue': activeCount > 0 ? totalSpent / activeCount : 0.0,
        'lastOrderDate': lastOrderDate?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('AdminService.getUserStats error: $e');
      return {
        'orderCount': 0,
        'activeOrderCount': 0,
        'totalSpent': 0.0,
        'avgOrderValue': 0.0,
        'lastOrderDate': null,
      };
    }
  }

  static Future<void> updateAdminNotes(String supabaseId, String notes) async {
    await _supabase
        .from('User')
        .update({'adminNotes': notes, 'updatedAt': DateTime.now().toIso8601String()})
        .eq('supabaseId', supabaseId);
  }

  static Future<void> deleteUserAccount(String supabaseId) async {
    // Note: This only deletes from the public.User table. 
    // Usually you'd use a service role or edge function to delete from auth.users
    await _supabase.from('User').delete().eq('supabaseId', supabaseId);
  }

  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('Order')
          .select('*, OrderItem(*)')
          .eq('userId', userId)
          .order('createdAt', ascending: false);
      return (response as List).map((o) => Order.fromJson(o)).toList();
    } catch (e) {
      debugPrint('AdminService.getUserOrders error: $e');
      rethrow;
    }
  }

  static Future<List<Order>> getAdminOrders() async {
    try {
      final response = await _supabase
          .from('Order')
          .select('*, OrderItem(*)')
          .order('createdAt', ascending: false);
      
      final orders = (response as List).map((o) => Order.fromJson(o)).toList();
      debugPrint('AdminService: Fetched ${orders.length} orders for admin');
      if (orders.isNotEmpty) {
        debugPrint('AdminService: Order statuses: ${orders.map((o) => o.orderStatus).take(5).toList()}...');
      }
      return orders;
    } catch (e) {
      debugPrint('AdminService.getAdminOrders error: $e');
      rethrow;
    }
  }

  // --- Product CRUD ---
  static Future<void> createProduct(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Product').insert(payload);
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Product').update(payload).eq('id', id);
  }

  static Future<void> deleteProduct(int id) async {
    await _supabase.from('Product').update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> toggleProductActive(int id, bool isActive) async {
    await _supabase.from('Product').update({'isActive': isActive}).eq('id', id);
  }

  // --- Order Management ---
  static Future<void> updateOrderStatus(int id, String status) async {
    if (status == 'cancelled') {
      try {
        debugPrint('AdminService: Admin cancelling order $id');
        // Use the RPC to ensure stock is restored and state is handled correctly
        final response = await _supabase.rpc('cancel_order_v1', params: {
          'p_order_id': id,
          'p_reason': 'Cancelled by Admin',
        });
        
        debugPrint('AdminService: RPC response: $response');

        // Check RPC success (similar to OrderService)
        bool success = false;
        if (response is bool) {
          success = response;
        } else if (response is Map) {
          success = response['success'] == true;
        }

        if (success) {
          // If it was already paid, the RPC might need to be followed by refund status update
          final orderData = await _supabase.from('Order').select('paymentStatus').eq('id', id).single();
          if (orderData['paymentStatus'] == 'paid') {
            await _supabase.from('Order').update({
              'paymentStatus': 'refund_pending',
              'updatedAt': DateTime.now().toIso8601String(),
            }).eq('id', id);
          }
          return;
        } else {
          debugPrint('AdminService: RPC reported failure, falling back to simple update');
        }
      } catch (e) {
        debugPrint('AdminService.updateOrderStatus (cancel) error: $e');
        // Fallback to simple update if RPC fails
      }
    }
    
    final updates = {
      'orderStatus': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status == 'delivered') {
      updates['deliveredAt'] = DateTime.now().toIso8601String();
    }
    
    await _supabase.from('Order').update(updates).eq('id', id);

    // Send status update emails
    try {
      final order = await OrderService.getOrderById(id);
      if (order != null) {
        if (status == 'shipped') {
          EmailService.sendOrderShipped(order);
        } else if (status == 'delivered' || status == 'completed') {
          EmailService.sendOrderCompletedWithInvoice(order);
        }
      }
    } catch (e) {
      debugPrint('AdminService.updateOrderStatus email trigger error: $e');
    }
  }

  static Future<void> updateOrderPaymentStatus(int id, String status) async {
    await _supabase.from('Order').update({
      'paymentStatus': status,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> updateOrderTracking(int id, String trackingNum, String locationLink) async {
    await _supabase.from('Order').update({
      'trackingNumber': trackingNum,
      'locationLink': locationLink,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', id);

    // After updating tracking, send a shipped notification
    try {
      final order = await OrderService.getOrderById(id);
      if (order != null && order.orderStatus == 'shipped') {
        EmailService.sendOrderShipped(order);
      }
    } catch (e) {
      debugPrint('AdminService.updateOrderTracking email trigger error: $e');
    }
  }

  // --- Banner CRUD ---
  static Future<List<BannerModel>> getAdminBanners() async {
    final response = await _supabase.from('Banner').select().order('sortOrder');
    return (response as List).map((b) => BannerModel.fromJson(b)).toList();
  }

  static Future<void> createBanner(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Banner').insert(payload);
  }

  static Future<void> updateBanner(int id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Banner').update(payload).eq('id', id);
  }

  static Future<void> deleteBanner(int id) async {
    await _supabase.from('Banner').delete().eq('id', id);
  }

  // --- Offer CRUD ---
  static Future<List<Offer>> getAdminOffers() async {
    final response = await _supabase.from('Offer').select().order('sort_order');
    return (response as List).map((o) => Offer.fromJson(o)).toList();
  }

  static Future<void> createOffer(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Offer').insert(payload);
  }

  static Future<void> updateOffer(int id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Offer').update(payload).eq('id', id);
  }

  static Future<void> deleteOffer(int id) async {
    await _supabase.from('Offer').delete().eq('id', id);
  }

  // --- Blog CRUD ---
  static Future<List<BlogPost>> getAdminBlogs() async {
    final response = await _supabase.from('BlogPost').select().order('createdAt', ascending: false);
    return (response as List).map((b) => BlogPost.fromJson(b)).toList();
  }

  static Future<void> createBlog(Map<String, dynamic> data) async {
    await _supabase.from('BlogPost').insert(data);
  }

  static Future<void> updateBlog(int id, Map<String, dynamic> data) async {
    await _supabase.from('BlogPost').update(data).eq('id', id);
  }

  static Future<void> deleteBlog(int id) async {
    await _supabase.from('BlogPost').delete().eq('id', id);
  }

  // --- Coupon CRUD ---
  static Future<List<Coupon>> getAdminCoupons() async {
    final response = await _supabase.from('Coupon').select().order('createdAt', ascending: false);
    return (response as List).map((c) => Coupon.fromJson(c)).toList();
  }

  static Future<void> createCoupon(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Coupon').insert(payload);
  }

  static Future<void> updateCoupon(int id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('Coupon').update(payload).eq('id', id);
  }

  static Future<void> deleteCoupon(int id) async {
    await _supabase.from('Coupon').delete().eq('id', id);
  }

  // --- Review CRUD ---
  static Future<List<Review>> getAdminReviews() async {
    final response = await _supabase.from('Review').select('*, Product(name)').order('createdAt', ascending: false);
    return (response as List).map((r) => Review.fromJson(r)).toList();
  }

  static Future<void> toggleReviewApproval(int id, bool approved) async {
    await _supabase.from('Review').update({'approved': approved}).eq('id', id);
  }

  static Future<void> deleteReview(int id) async {
    await _supabase.from('Review').delete().eq('id', id);
  }


  // --- Messages ---
  static Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final response = await _supabase
          .from('contact_messages')
          .select()
          .order('createdAt', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService.getMessages error: $e');
      rethrow;
    }
  }

  static Future<void> markMessageRead(int id, bool isRead) async {
    await _supabase.from('contact_messages').update({'isRead': isRead}).eq('id', id);
  }

  static Future<String> uploadImageBytes(String bucket, String fileName, dynamic bytes, String mimeType) async {
    await _supabase.storage.from(bucket).uploadBinary(
      fileName, 
      bytes, 
      fileOptions: FileOptions(contentType: mimeType, upsert: true)
    );
    return '$bucket/$fileName';
  }

  static String getPublicUrl(String pathOrBucket, [String? optionalPath]) {
    final input = pathOrBucket.trim();
    if (input.isEmpty) return '';
    
    if (input.startsWith('http') || 
        input.contains('://') || 
        input.startsWith('//') || 
        input.startsWith('data:') ||
        input.contains('.supabase.co/storage/v1/object/public/')) {
      if (input.startsWith('//')) return 'https:$input';
      return input;
    }
    
    if (optionalPath != null && optionalPath.isNotEmpty) {
      String bucket = input;
      String filePath = optionalPath.trim();
      
      if (filePath.startsWith('$bucket/')) {
        filePath = filePath.substring(bucket.length + 1);
      }
      
      try {
        return _supabase.storage.from(bucket).getPublicUrl(filePath);
      } catch (_) {
        return filePath;
      }
    }
    
    final parts = input.split('/');
    if (parts.length >= 2) {
      final bucket = parts[0];
      final filePath = parts.sublist(1).join('/');
      
      if (bucket.isNotEmpty && !bucket.contains('.') && !bucket.contains(':')) {
        try {
          return _supabase.storage.from(bucket).getPublicUrl(filePath);
        } catch (_) {
          return input;
        }
      }
    }
    
    return input;
  }

  static Future<void> processRefund(int id, String? refundId) async {
    await _supabase.from('Order').update({
      'paymentStatus': 'refunded',
      'orderStatus': 'cancelled',
      'refundId': refundId,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> updateOrderRequestStatus(int id, String status, String? adminNotes) async {
    await _supabase.from('Order').update({
      'orderStatus': status,
      'adminNotes': adminNotes,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Get a stream of all orders for Admin
  static Stream<List<Order>> getAllOrdersStream() {
    return _supabase
        .from('Order')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          return await getAdminOrders();
        });
  }

  /// Bulk toggle user status
  static Future<void> bulkUpdateCustomerStatus(List<String> ids, bool isActive) async {
    await _supabase
        .from('User')
        .update({
          'isActive': isActive, 
          'updatedAt': DateTime.now().toIso8601String()
        })
        .inFilter('supabaseId', ids);
  }

  /// Bulk delete users (Note: Careful with foreign key constraints)
  static Future<void> bulkDeleteCustomers(List<String> ids) async {
    await _supabase.from('User').delete().inFilter('supabaseId', ids);
  }

  /// Get a stream of all customers for Admin
  static Stream<List<Map<String, dynamic>>> getAdminCustomersStream() {
    return _supabase
        .from('User')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getAdminCustomers());
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final orders = await _supabase.from('Order').select('total, orderStatus');
      final products = await _supabase.from('Product').select('id').neq('isDeleted', true);
      final customers = await _supabase.from('User').select('id');

      double totalRevenue = 0;
      int totalOrders = (orders as List).length;
      
      for (final order in orders) {
        if (order['orderStatus'] != 'cancelled' && order['orderStatus'] != 'failed') {
          totalRevenue += (double.tryParse(order['total']?.toString() ?? '0') ?? 0);
        }
      }

      return {
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'total_products': (products as List).length,
        'total_customers': (customers as List).length,
      };
    } catch (e) {
      debugPrint('AdminService.getAdminStats error: $e');
      return {
        'total_revenue': 0.0,
        'total_orders': 0,
        'total_products': 0,
        'total_customers': 0,
      };
    }
  }

  // --- Category Management ---
  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('Category')
        .insert(data)
        .select()
        .single();
    return response;
  }
}
