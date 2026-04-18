enum DeliveryStatus { assigned, pickedUp, onTheWay, delivered, failed }

extension DeliveryStatusX on DeliveryStatus {
  String get dbValue {
    switch (this) {
      case DeliveryStatus.pickedUp: return 'picked_up';
      case DeliveryStatus.onTheWay: return 'on_the_way';
      case DeliveryStatus.delivered: return 'delivered';
      case DeliveryStatus.failed: return 'failed';
      default: return 'assigned';
    }
  }
}

class Rider {
  final String id; // UUID from auth.users
  final String fullName;
  final String? phone;
  final String? vehicleType;
  final String? zone;
  final bool isAvailable;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final int totalDeliveries;
  final double totalEarnings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;

  const Rider({
    required this.id,
    required this.fullName,
    this.phone,
    this.vehicleType,
    this.zone,
    this.isAvailable = false,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    this.createdAt,
    this.updatedAt,
    this.fcmToken,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown Rider',
      phone: json['phone'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      zone: json['zone'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.tryParse(json['last_location_update'] as String)
          : null,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      fcmToken: json['fcm_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'vehicle_type': vehicleType,
    'zone': zone,
    'is_available': isAvailable,
    'current_latitude': currentLatitude,
    'current_longitude': currentLongitude,
    'last_location_update': lastLocationUpdate?.toIso8601String(),
    'total_deliveries': totalDeliveries,
    'total_earnings': totalEarnings,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'fcm_token': fcmToken,
  };

  Rider copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? vehicleType,
    String? zone,
    bool? isAvailable,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    int? totalDeliveries,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
  }) {
    return Rider(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      zone: zone ?? this.zone,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
