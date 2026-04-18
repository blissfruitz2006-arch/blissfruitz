import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/rider.dart';
import '../models/delivery_assignment.dart';

class RiderService {
  final SupabaseClient _supabase;

  RiderService(this._supabase);

  /// Get current authenticated rider profile
  Future<Rider?> getCurrentRiderProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('riders')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return Rider.fromJson(response);
    } catch (e) {
      debugPrint('RiderService.getCurrentRiderProfile error: $e');
      return null;
    }
  }

  /// Update rider profile
  Future<void> updateRiderProfile(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('riders')
        .update(data)
        .eq('id', userId);
  }

  /// Get assignments for current rider
  Future<List<DeliveryAssignment>> getMyAssignments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('delivery_assignments')
          .select('*, Order(*, OrderItem(*)), riders(*)')
          .eq('rider_id', userId)
          .order('assigned_at', ascending: false);
      
      return (response as List).map((a) => DeliveryAssignment.fromJson(a)).toList();
    } catch (e) {
      debugPrint('RiderService.getMyAssignments error: $e');
      return [];
    }
  }

  /// Get stream of current rider's assignments
  Stream<List<DeliveryAssignment>> getMyAssignmentsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('delivery_assignments')
        .stream(primaryKey: ['id'])
        .eq('rider_id', userId)
        .asyncMap((_) => getMyAssignments());
  }

  // --- Admin Methods ---

  /// Get all riders for admin
  Future<List<Rider>> getAllRiders() async {
    try {
      final response = await _supabase
          .from('riders')
          .select()
          .order('full_name');
      
      return (response as List).map((r) => Rider.fromJson(r)).toList();
    } catch (e) {
      debugPrint('RiderService.getAllRiders error: $e');
      return [];
    }
  }

  /// Create a new rider (Admin only)
  /// This creates an auth user and a rider record
  Future<void> registerRider({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? zone,
    String? vehicleType,
  }) async {
    try {
      // 1. Create auth user
      // We use a secondary client to avoid signing out the current admin session.
      // We provide a NoopStorage to avoid "asyncStorage != null" assertion errors
      // caused by the default PKCE flow in newer Supabase SDKs.
      final tempClient = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
        authOptions: AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          pkceAsyncStorage: _NoopStorage(),
        ),
      );

      final authResponse = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final userId = authResponse.user?.id;
      if (userId == null) throw Exception('Failed to create authentication account');

      // 2. Create rider record in public.riders
      await _supabase.from('riders').insert({
        'id': userId,
        'full_name': fullName,
        'phone': phone,
        'zone': zone,
        'vehicle_type': vehicleType,
        'is_available': false,
      });

      // 3. Create user profile in public.User (if exists)
      // This ensures they can log in to the main app if needed
      try {
        await _supabase.from('User').upsert({
          'supabaseId': userId,
          'email': email,
          'fullName': fullName,
          'role': 'rider',
          'isActive': true,
          'updatedAt': DateTime.now().toIso8601String(),
        }, onConflict: 'email');
      } catch (e) {
        debugPrint('RiderService.registerRider User table sync failed (non-critical): $e');
      }

    } catch (e) {
      debugPrint('RiderService.registerRider error: $e');
      rethrow;
    }
  }
}

/// A simple storage implementation that does nothing.
/// Used for secondary Supabase clients to satisfy SDK requirements without
/// impacting the main application's persistent session.
class _NoopStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
