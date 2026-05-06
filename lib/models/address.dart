class Address {
  final int? id;
  final String? userId;
  final String? label;
  final String fullName;
  final String phone;
  final String line1;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const Address({
    this.id,
    this.userId,
    this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int?,
      userId: json['userId'] as String?,
      label: json['label'] as String?,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      line1: json['line1'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        if (userId != null) 'userId': userId,
        'label': label,
        'fullName': fullName,
        'phone': phone,
        'line1': line1,
        'city': city,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault,
        'latitude': latitude,
        'longitude': longitude,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        ...toInsertJson(),
      };

  /// Formatted single-line display
  String get displayString => '$line1, $city, $state - $pincode';

  Address copyWith({
    int? id,
    String? userId,
    String? label,
    String? fullName,
    String? phone,
    String? line1,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
