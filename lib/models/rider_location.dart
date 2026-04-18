class RiderLocation {
  final String riderId;
  final double lat;
  final double lng;
  final double heading;
  final DateTime updatedAt;

  const RiderLocation({
    required this.riderId,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.updatedAt,
  });

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    // Handle both old and new keys for compatibility
    return RiderLocation(
      riderId: (json['id'] ?? json['rider_id']) as String,
      lat: (json['current_latitude'] ?? json['lat'] as num).toDouble(),
      lng: (json['current_longitude'] ?? json['lng'] as num).toDouble(),
      heading: (json['heading'] as num? ?? 0.0).toDouble(),
      updatedAt: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'] as String)
          : json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': riderId,
    'current_latitude': lat,
    'current_longitude': lng,
    'heading': heading,
    'last_location_update': updatedAt.toIso8601String(),
  };

  RiderLocation copyWith({
    String? riderId,
    double? lat,
    double? lng,
    double? heading,
    DateTime? updatedAt,
  }) {
    return RiderLocation(
      riderId: riderId ?? this.riderId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      heading: heading ?? this.heading,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
