// Robust Order model for BlissFruitz Admin

import 'package:flutter/material.dart';

class Order {
  final int? id;
  final String? orderNumber;
  final String? userId;
  final String? guestEmail;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPincode;
  final String? notes;
  final double subtotal;
  final double shippingAmount;
  final double discountAmount;
  final double total;
  final String? couponCode;
  final String orderStatus;
  final String paymentStatus;
  final String? paymentMethod;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? trackingNumber;
  final String? locationLink;
  final double? latitude;
  final double? longitude;
  final String? refundStatus;
  final String? cancelReason;
  final String? refundId;
  final String? returnReason;
  final String? returnNotes;
  final String? replacementReason;
  final String? replacementNotes;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? riderId;
  final List<OrderItem> items;

  const Order({
    this.id,
    this.orderNumber,
    this.userId,
    this.guestEmail,
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
    this.shippingCity,
    this.shippingState,
    this.shippingPincode,
    this.notes,
    this.subtotal = 0,
    this.shippingAmount = 0,
    this.discountAmount = 0,
    this.total = 0,
    this.couponCode,
    this.orderStatus = 'pending',
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.trackingNumber,
    this.locationLink,
    this.latitude,
    this.longitude,
    this.refundStatus,
    this.cancelReason,
    this.refundId,
    this.returnReason,
    this.returnNotes,
    this.replacementReason,
    this.replacementNotes,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.riderId,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['OrderItem'] as List?;
    return Order(
      id: json['id'] as int?,
      orderNumber: json['orderNumber'] as String?,
      userId: json['userId'] as String?,
      guestEmail: json['guestEmail'] as String?,
      shippingName: json['shippingName'] as String?,
      shippingPhone: json['shippingPhone'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      shippingCity: json['shippingCity'] as String?,
      shippingState: json['shippingState'] as String?,
      shippingPincode: json['shippingPincode'] as String?,
      notes: json['notes'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingAmount: (json['shippingAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      couponCode: json['couponCode'] as String?,
      orderStatus: json['orderStatus'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      locationLink: json['locationLink'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      refundStatus: json['refundStatus'] as String?,
      cancelReason: json['cancelReason'] as String?,
      refundId: json['refundId'] as String?,
      returnReason: json['returnReason'] as String?,
      returnNotes: json['returnNotes'] as String?,
      replacementReason: json['replacementReason'] as String?,
      replacementNotes: json['replacementNotes'] as String?,
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      riderId: json['rider_id'] as String?,
      items: itemsList != null
          ? itemsList.map((e) => OrderItem.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toInsertJson() => {
        if (userId != null) 'userId': userId,
        if (guestEmail != null) 'guestEmail': guestEmail,
        'shippingName': shippingName,
        'shippingPhone': shippingPhone,
        'shippingAddress': shippingAddress,
        'shippingCity': shippingCity,
        'shippingState': shippingState,
        'shippingPincode': shippingPincode,
        if (notes != null) 'notes': notes,
        'subtotal': subtotal,
        'shippingAmount': shippingAmount,
        'discountAmount': discountAmount,
        'total': total,
        if (couponCode != null) 'couponCode': couponCode,
        'orderStatus': orderStatus,
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
        'latitude': latitude,
        'longitude': longitude,
        'locationLink': latitude != null && longitude != null 
            ? 'https://www.google.com/maps?q=$latitude,$longitude' 
            : locationLink,
        if (refundStatus != null) 'refundStatus': refundStatus,
        if (cancelReason != null) 'cancelReason': cancelReason,
        if (refundId != null) 'refundId': refundId,
        if (returnReason != null) 'returnReason': returnReason,
        if (returnNotes != null) 'returnNotes': returnNotes,
        if (replacementReason != null) 'replacementReason': replacementReason,
        if (replacementNotes != null) 'replacementNotes': replacementNotes,
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (riderId != null) 'rider_id': riderId,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
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
        'orderStatus': orderStatus,
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'trackingNumber': trackingNumber,
        'locationLink': locationLink,
        'latitude': latitude,
        'longitude': longitude,
        'refundStatus': refundStatus,
        'cancelReason': cancelReason,
        'refundId': refundId,
        'returnReason': returnReason,
        'returnNotes': returnNotes,
        'replacementReason': replacementReason,
        'replacementNotes': replacementNotes,
        'adminNotes': adminNotes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'rider_id': riderId,
        'OrderItem': items.map((e) => e.toJson()).toList(),
      };

  Order copyWith({
    int? id,
    String? orderNumber,
    String? userId,
    String? guestEmail,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
    String? shippingCity,
    String? shippingState,
    String? shippingPincode,
    String? notes,
    double? subtotal,
    double? shippingAmount,
    double? discountAmount,
    double? total,
    String? couponCode,
    String? orderStatus,
    String? paymentStatus,
    String? paymentMethod,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? trackingNumber,
    String? locationLink,
    double? latitude,
    double? longitude,
    String? refundStatus,
    String? cancelReason,
    String? refundId,
    String? returnReason,
    String? returnNotes,
    String? replacementReason,
    String? replacementNotes,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? riderId,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      guestEmail: guestEmail ?? this.guestEmail,
      shippingName: shippingName ?? this.shippingName,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingPincode: shippingPincode ?? this.shippingPincode,
      notes: notes ?? this.notes,
      subtotal: subtotal ?? this.subtotal,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      couponCode: couponCode ?? this.couponCode,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      locationLink: locationLink ?? this.locationLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      refundStatus: refundStatus ?? this.refundStatus,
      cancelReason: cancelReason ?? this.cancelReason,
      refundId: refundId ?? this.refundId,
      returnReason: returnReason ?? this.returnReason,
      returnNotes: returnNotes ?? this.returnNotes,
      replacementReason: replacementReason ?? this.replacementReason,
      replacementNotes: replacementNotes ?? this.replacementNotes,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      riderId: riderId ?? this.riderId,
      items: items ?? this.items,
    );
  }

  /// Formatted status label
  String get statusLabel {
    switch (orderStatus) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'return_requested':
        return 'Return Requested';
      case 'return_approved':
        return 'Return Approved';
      case 'return_rejected':
        return 'Return Rejected';
      case 'returned':
        return 'Returned';
      case 'replacement_requested':
        return 'Replacement Requested';
      case 'replacement_approved':
        return 'Replacement Approved';
      case 'replacement_rejected':
        return 'Replacement Rejected';
      case 'replaced':
        return 'Replaced';
      case 'refund_requested':
        return 'Refund Requested';
      case 'refund_approved':
        return 'Refund Approved';
      case 'refund_rejected':
        return 'Refund Rejected';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'failed':
        return 'Failed';
      default:
        return orderStatus;
    }
  }

  /// Color for status badges
  Color get statusColor {
    switch (orderStatus) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'return_requested':
      case 'replacement_requested':
      case 'refund_requested':
        return Colors.amber;
      case 'return_approved':
      case 'replacement_approved':
      case 'refund_approved':
        return Colors.green;
      case 'return_rejected':
      case 'replacement_rejected':
      case 'refund_rejected':
        return Colors.red;
      case 'returned':
      case 'replaced':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get paymentLabel {
    switch (paymentStatus) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'refund_pending':
        return 'Refund Pending';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus;
    }
  }

  /// Icon for status
  IconData get statusIcon {
    switch (orderStatus) {
      case 'pending':
        return Icons.timer_outlined;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.sync_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'return_requested':
      case 'replacement_requested':
      case 'refund_requested':
        return Icons.assignment_return_outlined;
      case 'return_approved':
      case 'replacement_approved':
      case 'refund_approved':
        return Icons.assignment_turned_in_outlined;
      case 'return_rejected':
      case 'replacement_rejected':
      case 'refund_rejected':
        return Icons.assignment_late_outlined;
      case 'returned':
      case 'replaced':
        return Icons.backspace_outlined;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Check if the order can be cancelled
  bool get canCancel {
    const cancellableStatuses = ['pending', 'confirmed', 'processing'];
    return cancellableStatuses.contains(orderStatus);
  }

  /// Check if the order can request return or replacement (7-day window)
  bool get canRequestReturnOrReplacement {
    if (orderStatus != 'delivered' || deliveredAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(deliveredAt!);
    return difference.inDays <= 7;
  }

  /// Check if order is in a "final" state for returns
  bool get isReturnOrReplacementProcessed {
    const processedStatuses = ['returned', 'replaced', 'return_rejected', 'replacement_rejected', 'refund_approved', 'refund_rejected'];
    return processedStatuses.contains(orderStatus);
  }

  /// Time remaining for return/replacement window as a string
  String get returnWindowRemaining {
    if (orderStatus != 'delivered' || deliveredAt == null) return '';
    final now = DateTime.now();
    final deadline = deliveredAt!.add(const Duration(days: 7));
    final difference = deadline.difference(now);
    
    if (difference.isNegative) return 'Window Closed';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} left';
    } else {
      return 'Expires soon';
    }
  }
}

class OrderItem {
  final int? id;
  final int? orderId;
  final int? productId;
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    this.id,
    this.orderId,
    this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      productId: json['productId'] as int?,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}
