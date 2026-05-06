import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/order.dart';
import '../models/cart.dart';
import 'email_service.dart';
import 'coupon_service.dart';

class OrderService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Create a new order from the current cart
  static Future<Order> createOrder({
    String? userId,
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
      // Final coupon usage check
      if (couponCode != null && couponCode.isNotEmpty) {
        final isUsed = await CouponService.isCouponUsedByCustomer(
          couponCode,
          userId: userId,
          guestEmail: guestEmail,
          phone: shippingPhone,
        );
        if (isUsed) {
          throw Exception('The coupon code "$couponCode" has already been used by you.');
        }
      }

      // Generate order number with millisecond and microsecond components to ensure uniqueness
      final now = DateTime.now();
      final orderNumber =
          'BF-${now.millisecondsSinceEpoch.toString().substring(4)}-${(100 + (now.microsecond % 900))}';

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
            'orderStatus': paymentMethod == 'cod' ? 'placed' : 'pending',
            'paymentStatus': 'pending',
            'paymentMethod': paymentMethod,
            'latitude': latitude,
            'longitude': longitude,
            'locationLink': latitude != null && longitude != null
              ? 'https://www.google.com/maps?q=$latitude,$longitude'
              : null,
            'items': items.map((i) => {
              'productId': i.product.id,
              'name': i.product.name,
              'price': i.product.price,
              'quantity': i.quantity,
            }).toList(),
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderData['id'] as int;
      debugPrint('Order created with ID: $orderId');

      // Insert order items
      final orderItems = items.map((item) => {
            'orderId': orderId,
            'productId': item.product.id,
            'name': item.product.name,
            'price': item.product.price,
            'quantity': item.quantity,
            'totalPrice': item.product.price * item.quantity,
          }).toList();

      await _client.from('OrderItem').insert(orderItems);
      debugPrint('Order items inserted for order: $orderId');

      // Create full order object including items for confirmation email and success screen
      final order = Order.fromJson({
        ...orderData,
        'OrderItem': items.map((i) => {
          'productId': i.product.id,
          'name': i.product.name,
          'price': i.product.price,
          'quantity': i.quantity,
          'totalPrice': i.product.price * i.quantity,
          'Product': i.product.toJson(),
        }).toList(),
      });
      
      // Send order confirmation email asynchronously only for COD
      // For online payments, we send it after payment success in updatePaymentStatus
      if (paymentMethod == 'cod') {
        EmailService.sendOrderConfirmation(order).catchError((e) {
          debugPrint('Silent error sending confirmation email: $e');
        });
      }

      return order;
    } catch (e) {
      debugPrint('CRITICAL: Error placing order: $e');
      rethrow;
    }
  }

  /// Get orders for a specific user
  static Future<List<Order>> getUserOrders(String userId) async {
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

  /// Create a Razorpay Order ID securely via Edge Function
  static Future<String?> createRazorpayOrder({
    required int amountInPaise,
    required String receipt,
  }) async {
    debugPrint('Creating Razorpay Order securely...');
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': amountInPaise,
          'receipt': receipt,
        },
      );
      
      if (res.status == 200) {
        debugPrint('Razorpay Order created successfully.');
        return res.data['id'] as String;
      } else {
        debugPrint('Failed to create Razorpay Order: ${res.data}');
        return null;
      }
    } catch (e) {
      debugPrint('createRazorpayOrder error: $e');
      return null;
    }
  }

  /// Securely verify payment signature via Edge Function
  static Future<bool> verifyPaymentSignature({
    required int orderId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    debugPrint('Verifying payment signature for order $orderId securely...');
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'verify-razorpay',
        body: {
          'order_id': orderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
        },
      );
      
      if (res.status == 200) {
        debugPrint('Payment signature verified successfully by Edge Function.');
        return true;
      } else {
        debugPrint('Payment verification failed: ${res.data}');
        return false;
      }
    } catch (e) {
      debugPrint('verifyPaymentSignature error: $e');
      return false;
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
    debugPrint('Updating payment status for order $orderId to $paymentStatus via RPC');
    
    try {
      final response = await _client.rpc('update_order_payment_v1', params: {
        'p_order_id': orderId,
        'p_payment_status': paymentStatus,
        'p_order_status': orderStatus,
        'p_razorpay_payment_id': razorpayPaymentId,
        'p_razorpay_order_id': razorpayOrderId,
      });

      if (response != null) {
        final result = Map<String, dynamic>.from(response);
        if (result['success'] == true) {
          debugPrint('Successfully updated payment status for order $orderId');
        } else {
          debugPrint('Failed to update payment status: ${result['message']}');
        }
      }
    } catch (e) {
      debugPrint('Error calling update_order_payment_v1: $e');
      // Fallback to direct update (may fail due to RLS but better than nothing)
      final Map<String, dynamic> updates = {
        'paymentStatus': paymentStatus,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpayOrderId': razorpayOrderId,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (orderStatus != null) updates['orderStatus'] = orderStatus;
      await _client.from('Order').update(updates).eq('id', orderId);
    }

    // Send confirmation email now that payment is confirmed
    if (paymentStatus == 'paid') {
      try {
        final fullOrder = await getOrderById(orderId);
        if (fullOrder != null) {
          EmailService.sendOrderConfirmation(fullOrder).catchError((e) {
            debugPrint('Error sending confirmation email after payment: $e');
          });
        }
      } catch (e) {
        debugPrint('Failed to send confirmation email after payment: $e');
      }
    }
  }

  static Future<int> getUserOrderCount(String? userId) async {
    if (userId == null) return 0;
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
  static Stream<List<Order>> getUserOrdersStream(String userId) {
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

  /// Get delivery info (rider assignment + proof image) for an order
  static Future<Map<String, dynamic>?> getDeliveryInfo(int orderId, {String? contact}) async {
    try {
      final data = await _client
          .from('delivery_assignments')
          .select('*, rider:riders(*)')
          .eq('order_id', orderId)
          .maybeSingle();

      if (data == null) return null;

      final rider = data['rider'] as Map<String, dynamic>?;
      return {
        'rider_name': rider?['full_name'] ?? 'Rider',
        'rider_phone': rider?['phone'],
        'proof_image_url': data['proof_image_url'],
        'status': data['status'],
      };
    } catch (e) {
      debugPrint('OrderService.getDeliveryInfo error: $e');
      return null;
    }
  }
}
