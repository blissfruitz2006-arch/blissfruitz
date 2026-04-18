class UserProfile {
  final int id;
  final String? username;
  final String? email;
  final String? googleId;
  final String? supabaseId;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    this.username,
    this.email,
    this.googleId,
    this.supabaseId,
    this.fullName,
    this.phone,
    this.address,
    this.avatarUrl,
    this.role = 'customer',
    this.isActive = true,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String?,
      email: json['email'] as String?,
      googleId: json['googleId'] as String?,
      supabaseId: json['supabaseId'] as String?,
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
