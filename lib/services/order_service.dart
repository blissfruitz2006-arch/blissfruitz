import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/order.dart';
import '../models/cart.dart';
import 'email_service.dart';

class OrderService {
  static final _client = SupabaseConfig.client;

  /// Create a new order from the current cart
  static Future<Order> createOrder({
    int? userId,
    String? guestEmail,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
    String? notes,
    required double subtotal,
    required double shippingAmount,
    required double discountAmount,
    required double total,
    String? couponCode,
    required String paymentMethod,
    required List<CartItem> items,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Generate order number
      final orderNumber =
          'BF-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

      // Insert the order
      final orderData = await _client
          .from('Order')
          .insert({
            'orderNumber': orderNumber,
            'userId': userId,
            'guestEmail': guestEmail,
            'shippingName': shippingName,
            'shippingPhone': shippingPhone,
            'shippingAddress': shippingAddress,
            'shippingCity': shippingCity,
            'shippingState': shippingState,
            'shippingPincode': shippingPincode,
            'notes': notes,
            'subtotal': subtotal,
            'shippingAmount': shippingAmount,
            'discountAmount': discountAmount,
            'total': total,
            'couponCode': couponCode,
            'orderStatus': 'pending',
            'paymentStatus': 'pending',
            'paymentMethod': paymentMethod,
            'latitude': latitude,
            'longitude': longitude,
            if (latitude != null && longitude != null)
              'locationLink': 'https://www.google.com/maps?q=$latitude,$longitude',
            'updatedAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderData['id'] as int;

      // Insert order items
      final orderItems = items.map((item) => {
            'orderId': orderId,
            'productId': item.product.id,
            'name': item.product.name,
            'price': item.product.price,
            'quantity': item.quantity,
          }).toList();

      await _client.from('OrderItem').insert(orderItems);

      final order = Order.fromJson(orderData);
      
      // Send order confirmation email asynchronously
      EmailService.sendOrderConfirmation(order);

      return order;
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }

  /// Get orders for a specific user
  static Future<List<Order>> getUserOrders(int userId) async {
    final data = await _client
        .from('Order')
        .select('*, OrderItem(*)')
        .eq('userId', userId)
        .order('createdAt', ascending: false);

    return (data as List).map((e) => Order.fromJson(e)).toList();
  }

  /// Get a single order by ID
  static Future<Order?> getOrderById(int orderId) async {
    final data = await _client
        .from('Order')
        .select('*, OrderItem(*)')
        .eq('id', orderId)
        .maybeSingle();

    if (data != null) {
      return Order.fromJson(data);
    }
    return null;
  }

  /// Get order by order number and contact (for secure guest tracking)
  static Future<Order?> trackOrder(String orderNumber, String contact) async {
    try {
      final response = await _client.rpc('track_order', params: {
        'p_order_number': orderNumber,
        'p_contact': contact,
      });

      if (response != null) {
        final data = Map<String, dynamic>.from(response);
        final orderMap = Map<String, dynamic>.from(data['order']);
        final itemsList = List<Map<String, dynamic>>.from(data['items']);
        
        // Inject items into order map for fromJson to handle
        orderMap['OrderItem'] = itemsList;
        
        return Order.fromJson(orderMap);
      }
      return null;
    } catch (e) {
      debugPrint('OrderService.trackOrder error: $e');
      rethrow;
    }
  }

  /// Update order payment status (after Razorpay callback)
  static Future<void> updatePaymentStatus({
    required int orderId,
    required String paymentStatus,
    String? orderStatus,
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    final Map<String, dynamic> updates = {
      'paymentStatus': paymentStatus,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (orderStatus != null) {
      updates['orderStatus'] = orderStatus;
    }

    await _client.from('Order').update(updates).eq('id', orderId);
  }

  static Future<int> getUserOrderCount(int userId) async {
    try {
      final response = await _client
          .from('Order')
          .select('id')
          .eq('userId', userId)
          .neq('orderStatus', 'cancelled');
      
      return (response as List).length;
    } catch (e) {
      debugPrint('OrderService.getUserOrderCount error: $e');
      return 0;
    }
  }

  /// Cancel an order and restore stock using server-side RPC
  static Future<void> cancelOrder(int orderId, String reason) async {
    try {
      debugPrint('OrderService: Cancelling order $orderId with reason: $reason');
      final response = await _client.rpc('cancel_order_v1', params: {
        'p_order_id': orderId,
        'p_reason': reason,
      });

      debugPrint('OrderService: RPC response: $response');
      
      if (response == null) {
        throw 'No response from server during cancellation.';
      }

      // Handle both raw bool return or Map result
      if (response is bool) {
        if (!response) throw 'Server refused order cancellation.';
        return;
      }
      
      if (response is Map) {
        final result = Map<String, dynamic>.from(response);
        if (result['success'] != true) {
          throw result['message'] ?? 'Failed to cancel order: ${result['error'] ?? 'Unknown error'}';
        }
        return;
      }

      // If we're here, we got something unexpected but maybe it worked if no error thrown
      debugPrint('OrderService: Unexpected response type: ${response.runtimeType}');
    } catch (e) {
      debugPrint('OrderService: Error in cancelOrder: $e');
      if (e is String) rethrow;
      rethrow;
    }
  }

  /// Request a return for an order
  static Future<void> requestReturn(int orderId, String reason, {String? notes}) async {
    try {
      final response = await _client.rpc('request_order_action_v1', params: {
        'p_order_id': orderId,
        'p_action': 'return',
        'p_reason': reason,
        'p_notes': notes,
      });

      if (response != null) {
        final result = Map<String, dynamic>.from(response);
        if (result['success'] != true) {
          throw result['message'] ?? 'Failed to request return';
        }
      }
    } catch (e) {
      debugPrint('OrderService.requestReturn error: $e');
      rethrow;
    }
  }

  /// Request a replacement for an order
  static Future<void> requestReplacement(int orderId, String reason, {String? notes}) async {
    try {
      final response = await _client.rpc('request_order_action_v1', params: {
        'p_order_id': orderId,
        'p_action': 'replacement',
        'p_reason': reason,
        'p_notes': notes,
      });

      if (response != null) {
        final result = Map<String, dynamic>.from(response);
        if (result['success'] != true) {
          throw result['message'] ?? 'Failed to request replacement';
        }
      }
    } catch (e) {
      debugPrint('OrderService.requestReplacement error: $e');
      rethrow;
    }
  }

  /// Admin: Handle return/replacement request
  static Future<void> handleRequestResponse({
    required int orderId,
    required String status,
    String? adminNotes,
  }) async {
    await _client.from('Order').update({
      'orderStatus': status,
      'adminNotes': adminNotes,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Get a stream of a single order
  static Stream<Order?> getOrderStream(int orderId) {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .asyncMap((data) async {
          if (data.isEmpty) return null;
          return await getOrderById(orderId);
        });
  }

  /// Get a stream of orders for a user
  static Stream<List<Order>> getUserOrdersStream(int userId) {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .eq('userId', userId)
        .asyncMap((data) async {
          return await getUserOrders(userId);
        });
  }

  /// Get a stream of all orders (for admin)
  static Stream<List<Order>> getAllOrdersStream() {
    return _client
        .from('Order')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final orders = await _client
              .from('Order')
              .select('*, OrderItem(*)')
              .order('createdAt', ascending: false);
          return (orders as List).map((o) => Order.fromJson(o)).toList();
        });
  }
}
