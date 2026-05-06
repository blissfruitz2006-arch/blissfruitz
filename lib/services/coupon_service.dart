import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/coupon.dart';

class CouponService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Validate and fetch a coupon by code
  static Future<Coupon?> validateCoupon(String code, {String? userId, String? guestEmail, String? phone}) async {
    final data = await _client
        .from('Coupon')
        .select()
        .ilike('code', code.trim())
        .eq('isActive', true)
        .maybeSingle();

    if (data == null) return null;

    final coupon = Coupon.fromJson(data);
    if (!coupon.isValid) return null;

    // Check if user has already used this coupon
    if (userId != null || guestEmail != null || phone != null) {
      final isUsed = await isCouponUsedByCustomer(
        coupon.code, 
        userId: userId, 
        guestEmail: guestEmail,
        phone: phone,
      );
      if (isUsed) {
        throw Exception('You have already used this coupon code');
      }
    }

    return coupon;
  }

  /// Check if a user (or guest email/phone) has already used a specific coupon code
  static Future<bool> isCouponUsedByCustomer(String couponCode, {String? userId, String? guestEmail, String? phone}) async {
    // Normalize phone for comparison
    String? cleanPhone = phone?.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone != null && cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }

    var query = _client
        .from('Order')
        .select('id')
        .ilike('couponCode', couponCode.trim())
        .not('orderStatus', 'in', '("cancelled", "failed")');

    List<String> conditions = [];
    if (userId != null && userId.isNotEmpty) conditions.add('userId.eq.$userId');
    if (guestEmail != null && guestEmail.isNotEmpty) {
      conditions.add('guestEmail.ilike.${guestEmail.trim()}');
    }
    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      // Check both the exact phone and any phone ending with these 10 digits
      conditions.add('shippingPhone.ilike.%$cleanPhone');
    }

    if (conditions.isEmpty) return false;

    query = query.or(conditions.join(','));

    final response = await query.limit(1).maybeSingle();
    final used = response != null;
    if (used) {
      debugPrint('COUPON_SECURITY: Coupon "$couponCode" already used by customer (ID: $userId, Phone: $cleanPhone)');
    }
    return used;
  }

  /// Get all active coupons (for display)
  static Future<List<Coupon>> getActiveCoupons() async {
    final data = await _client
        .from('Coupon')
        .select()
        .eq('isActive', true)
        .order('createdAt', ascending: false);

    return (data as List).map((e) => Coupon.fromJson(e)).toList();
  }
}

