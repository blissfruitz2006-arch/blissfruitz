import 'rider.dart';
import 'order.dart';

class DeliveryAssignment {
  final String id; // UUID
  final int orderId;
  final String riderId;
  final DeliveryStatus status;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final String? failReason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? proofImageUrl;
  
  // Optional nested fields for joined queries
  final Rider? rider;
  final Order? order;

  const DeliveryAssignment({
    required this.id,
    required this.orderId,
    required this.riderId,
    this.status = DeliveryStatus.assigned,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.failedAt,
    this.failReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.proofImageUrl,
    this.rider,
    this.order,
  });

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    return DeliveryAssignment(
      id: (json['id'] ?? json['assignment_id']) as String,
      orderId: (json['order_id'] ?? json['orderId']) as int,
      riderId: (json['rider_id'] ?? json['riderId']) as String,
      status: _parseStatus(json['status'] as String?),
      assignedAt: (json['assigned_at'] ?? json['assignedAt']) != null
          ? DateTime.tryParse((json['assigned_at'] ?? json['assignedAt']) as String)
          : null,
      pickedUpAt: (json['picked_up_at'] ?? json['pickedUpAt']) != null
          ? DateTime.tryParse((json['picked_up_at'] ?? json['pickedUpAt']) as String)
          : null,
      deliveredAt: (json['delivered_at'] ?? json['deliveredAt']) != null
          ? DateTime.tryParse((json['delivered_at'] ?? json['deliveredAt']) as String)
          : null,
      failedAt: (json['failed_at'] ?? json['failedAt']) != null
          ? DateTime.tryParse((json['failed_at'] ?? json['failedAt']) as String)
          : null,
      failReason: (json['fail_reason'] ?? json['failReason']) as String?,
      notes: json['notes'] as String?,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']) as String)
          : null,
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.tryParse((json['updated_at'] ?? json['updatedAt']) as String)
          : null,
      proofImageUrl: (json['proof_image_url'] ?? json['proofImageUrl'] ?? json['proof_url']) as String?,
      // Nested joins
      rider: json['riders'] != null ? Rider.fromJson(json['riders']) : null,
      order: _parseOrder(json),
    );
  }

  static Order? _parseOrder(Map<String, dynamic> json) {
    final orderData = json['Order'] ?? json['order'] ?? json['orders'] ?? json['Order_id'];
    if (orderData == null) {
      // If order is null, check if the top level has Order keys (flattened join)
      if (json.containsKey('orderNumber') || json.containsKey('shippingAddress')) {
        return Order.fromJson(json);
      }
      return null;
    }
    
    if (orderData is List) {
      if (orderData.isEmpty) return null;
      return Order.fromJson(orderData.first as Map<String, dynamic>);
    }
    
    return Order.fromJson(orderData as Map<String, dynamic>);
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'rider_id': riderId,
    'status': status.dbValue,
    'assigned_at': assignedAt?.toIso8601String(),
    'picked_up_at': pickedUpAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'failed_at': failedAt?.toIso8601String(),
    'fail_reason': failReason,
    'notes': notes,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'proof_image_url': proofImageUrl,
    if (rider != null) 'riders': rider!.toJson(),
    if (order != null) 'Order': order!.toJson(),
  };

  static DeliveryStatus _parseStatus(String? status) {
    switch (status) {
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'on_the_way':
        return DeliveryStatus.onTheWay;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'failed':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.assigned;
    }
  }


  DeliveryAssignment copyWith({
    String? id,
    int? orderId,
    String? riderId,
    DeliveryStatus? status,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? failedAt,
    String? failReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? proofImageUrl,
    Rider? rider,
    Order? order,
  }) {
    return DeliveryAssignment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      riderId: riderId ?? this.riderId,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failedAt: failedAt ?? this.failedAt,
      failReason: failReason ?? this.failReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      rider: rider ?? this.rider,
      order: order ?? this.order,
    );
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.onTheWay:
        return 'On The Way';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }
}
