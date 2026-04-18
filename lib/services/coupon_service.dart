import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/coupon.dart';

class CouponService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Validate and fetch a coupon by code
  static Future<Coupon?> validateCoupon(String code, {int? userId, String? guestEmail, String? phone}) async {
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
  static Future<bool> isCouponUsedByCustomer(String couponCode, {int? userId, String? guestEmail, String? phone}) async {
    var query = _client
        .from('Order')
        .select('id')
        .ilike('couponCode', couponCode.trim())
        .not('orderStatus', 'eq', 'cancelled');

    List<String> conditions = [];
    if (userId != null) conditions.add('"userId".eq.$userId');
    if (guestEmail != null) conditions.add('guestEmail.eq.$guestEmail');
    if (phone != null && phone.isNotEmpty) {
      // Clean phone number (remove spaces, etc if needed, but assuming standard format)
      conditions.add('shippingPhone.eq.$phone');
    }

    if (conditions.isEmpty) return false;

    query = query.or(conditions.join(','));

    final response = await query.limit(1).maybeSingle();

    return response != null;
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

