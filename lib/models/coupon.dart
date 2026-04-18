import 'user_profile.dart';

class Coupon {
  final int id;
  final String code;
  final String? description;
  final String discountType; // 'percent' or 'flat'
  final double discountValue;
  final double? minOrder;
  final double? maxDiscount;
  final bool isActive;
  final DateTime? expiresAt;
  final String audienceSegment;
  final int? segmentMinOrders;
  final int? segmentMaxOrders;
  final int? segmentLoyalMinOrders;
  final int? segmentMaxAccountAgeDays;
  final int? segmentMinAccountAgeDays;
  final DateTime? createdAt;

  const Coupon({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrder,
    this.maxDiscount,
    this.isActive = true,
    this.expiresAt,
    this.audienceSegment = 'all',
    this.segmentMinOrders,
    this.segmentMaxOrders,
    this.segmentLoyalMinOrders,
    this.segmentMaxAccountAgeDays,
    this.segmentMinAccountAgeDays,
    this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      discountType: json['discountType'] as String? ?? 'percent',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      minOrder: (json['minOrder'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      audienceSegment: json['audience_segment'] as String? ?? 'all',
      segmentMinOrders: json['segment_min_orders'] as int?,
      segmentMaxOrders: json['segment_max_orders'] as int?,
      segmentLoyalMinOrders: json['segment_loyal_min_orders'] as int?,
      segmentMaxAccountAgeDays: json['segment_max_account_age_days'] as int?,
      segmentMinAccountAgeDays: json['segment_min_account_age_days'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// Check if the coupon is currently valid (active + not expired)
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }

  /// Calculate the discount amount for a given subtotal
  double calculateDiscount(double subtotal) {
    if (!isValid) return 0;
    if (minOrder != null && subtotal < minOrder!) return 0;

    double discount;
    if (discountType == 'percent') {
      discount = subtotal * (discountValue / 100);
    } else {
      discount = discountValue;
    }

    // Cap at maxDiscount if set
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }

    // Never discount more than the subtotal
    return discount > subtotal ? subtotal : discount;
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrder': minOrder,
        'maxDiscount': maxDiscount,
        'isActive': isActive,
        'expiresAt': expiresAt?.toIso8601String(),
        'audience_segment': audienceSegment,
        'segment_min_orders': segmentMinOrders,
        'segment_max_orders': segmentMaxOrders,
        'segment_loyal_min_orders': segmentLoyalMinOrders,
        'segment_max_account_age_days': segmentMaxAccountAgeDays,
        'segment_min_account_age_days': segmentMinAccountAgeDays,
      };

  /// Check if a user is eligible for this coupon based on their profile and history
  String? getIneligibilityReason(UserProfile? profile, int orderCount) {
    if (!isValid) return 'Coupon is no longer active or has expired';

    switch (audienceSegment) {
      case 'first_timers':
      case 'new_user':
        if (orderCount > 0) return 'This coupon is only for first-time customers';
        break;
      case 'loyal_customers':
        if (segmentLoyalMinOrders != null && orderCount < segmentLoyalMinOrders!) {
          return 'This coupon is for loyal customers with at least $segmentLoyalMinOrders orders';
        }
        break;
      case 'order_count_range':
        if (segmentMinOrders != null && orderCount < segmentMinOrders!) {
          return 'Requires at least $segmentMinOrders previous orders';
        }
        if (segmentMaxOrders != null && orderCount > segmentMaxOrders!) {
          return 'Not applicable for users with more than $segmentMaxOrders orders';
        }
        break;
      case 'account_age_range':
        if (profile == null) return 'Must be logged in to use this coupon';
        if (profile.createdAt != null) {
          final ageDays = DateTime.now().difference(profile.createdAt!).inDays;
          if (segmentMinAccountAgeDays != null && ageDays < segmentMinAccountAgeDays!) {
            return 'Account must be at least $segmentMinAccountAgeDays days old';
          }
          if (segmentMaxAccountAgeDays != null && ageDays > segmentMaxAccountAgeDays!) {
            return 'Account must be less than $segmentMaxAccountAgeDays days old';
          }
        }
        break;
    }

    return null;
  }
}
