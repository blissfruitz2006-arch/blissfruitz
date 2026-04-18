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
  final String? otpCode;
  
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
    this.otpCode,
    this.rider,
    this.order,
  });

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    return DeliveryAssignment(
      id: json['id'] as String,
      orderId: json['order_id'] as int,
      riderId: json['rider_id'] as String,
      status: _parseStatus(json['status'] as String?),
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      failedAt: json['failed_at'] != null
          ? DateTime.tryParse(json['failed_at'] as String)
          : null,
      failReason: json['fail_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      otpCode: json['otp_code'] as String?,
      // Nested joins
      rider: json['riders'] != null ? Rider.fromJson(json['riders']) : null,
      order: json['Order'] != null ? Order.fromJson(json['Order']) : null,
    );
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
    'otp_code': otpCode,
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
    String? otpCode,
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
      otpCode: otpCode ?? this.otpCode,
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
