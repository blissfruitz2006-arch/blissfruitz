import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_assignment.dart';
import '../models/rider.dart';

/// Service class for handling all delivery-related operations.
class DeliveryService {
  final SupabaseClient _supabase;

  DeliveryService(this._supabase);

  /// Assigns a rider to an order.
  /// 
  /// Updates the order status to 'out_for_delivery', generates a 4-digit OTP,
  /// and creates a new record in `delivery_assignments`.
  Future<DeliveryAssignment> assignRider(int orderId, String riderId) async {
    print('DEBUG: Assigning rider $riderId to order $orderId using RPC');
    try {
      // 1. Generate a 4-digit OTP
      final otp = (1000 + Random().nextInt(9000)).toString();
      print('DEBUG: Generated OTP: $otp');

      // 2. Call the RPC
      final response = await _supabase.rpc('assign_rider_to_order', params: {
        'p_order_id': orderId,
        'p_rider_id': riderId,
        'p_otp_code': otp,
      });
      
      print('DEBUG: RPC Success: $response');

      // 3. Fetch the full assignment details (including joins) because the RPC only returns basic info
      final fullData = await _supabase
          .from('delivery_assignments')
          .select('''
            *,
            riders (*),
            Order (*)
          ''')
          .eq('id', response['id'])
          .single();

      return DeliveryAssignment.fromJson(fullData);
    } on PostgrestException catch (e) {
      print('DEBUG: PostgrestException in RPC: ${e.message} (code: ${e.code})');
      if (e.code == '23505') {
        if (e.message.contains('idx_one_active_delivery')) {
          throw Exception('This rider already has an active delivery.');
        } else if (e.message.contains('idx_one_active_assignment_per_order')) {
          throw Exception('This order is already being handled by another rider.');
        }
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('DEBUG: Error in assignRider: $e');
      throw Exception('Failed to assign rider: $e');
    }
  }

  /// Updates the status of a delivery assignment.
  Future<void> updateDeliveryStatus(String assignmentId, DeliveryStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == DeliveryStatus.pickedUp) {
        updates['picked_up_at'] = DateTime.now().toIso8601String();
      } else if (status == DeliveryStatus.delivered) {
        updates['delivered_at'] = DateTime.now().toIso8601String();
      } else if (status == DeliveryStatus.failed) {
        updates['failed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('delivery_assignments').update(updates).eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to update delivery status: $e');
    }
  }

  /// Confirms delivery using an OTP.
  /// 
  /// If OTP matches, marks the assignment and order as delivered.
  Future<bool> confirmDeliveryWithOtp(String assignmentId, String enteredOtp) async {
    try {
      // 1. Fetch assignment to check OTP
      final assignmentData = await _supabase
          .from('delivery_assignments')
          .select('otp_code, order_id, rider_id')
          .eq('id', assignmentId)
          .single();

      if (assignmentData['otp_code'] != enteredOtp) {
        return false;
      }

      final int orderId = assignmentData['order_id'];
      final String riderId = assignmentData['rider_id'];

      // 2. Mark assignment as delivered
      await updateDeliveryStatus(assignmentId, DeliveryStatus.delivered);

      // 3. Update order status
      await _supabase.from('Order').update({
        'orderStatus': 'delivered',
        'deliveredAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // 4. Calculate and save earnings
      await calculateAndSaveEarnings(assignmentId, riderId);

      return true;
    } catch (e) {
      throw Exception('Failed to confirm delivery: $e');
    }
  }

  /// Calculates earnings for a delivery and saves it to the database.
  /// 
  /// Logic: Base ₹40 + ₹5 per km bonus (placeholder distance = 5km).
  Future<void> calculateAndSaveEarnings(String assignmentId, String riderId) async {
    try {
      const double baseEarnings = 40.0;
      const double distanceKm = 5.0; // Placeholder distance logic
      const double bonusPerKm = 5.0;
      final double bonusEarnings = distanceKm * bonusPerKm;
      final double totalEarnings = baseEarnings + bonusEarnings;

      await _supabase.from('delivery_earnings').insert({
        'assignment_id': assignmentId,
        'rider_id': riderId,
        'base_earnings': baseEarnings,
        'bonus_earnings': bonusEarnings,
        'total_earnings': totalEarnings,
      });

      // Also update rider's total earnings and delivery count
      await _supabase.rpc('increment_rider_stats', params: {
        'r_id': riderId,
        'earnings_increment': totalEarnings,
      });
    } catch (e) {
      // Log error but don't block the delivery completion flow
      debugPrint('Error saving earnings: $e');
    }
  }

  /// Watches the active assignment for a specific rider.
  Stream<DeliveryAssignment?> watchRiderActiveAssignment(String riderId) {
    return _supabase
        .from('delivery_assignments')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .order('assigned_at', ascending: false)
        .map((data) {
          final assignments = data
              .map((json) => DeliveryAssignment.fromJson(json))
              .where((a) => a.status != DeliveryStatus.delivered && a.status != DeliveryStatus.failed)
              .toList();
          return assignments.isEmpty ? null : assignments.first;
        });
  }

  /// Gets a specific assignment for an order.
  Future<DeliveryAssignment?> getOrderAssignment(int orderId) async {
    try {
      final response = await _supabase
          .from('delivery_assignments')
          .select('''
            *,
            riders (*),
            Order (*)
          ''')
          .eq('order_id', orderId)
          .maybeSingle();

      return response != null ? DeliveryAssignment.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get order assignment: $e');
    }
  }

  /// Watches all assignments with optional status filtering.
  Stream<List<DeliveryAssignment>> watchAllAssignments({String? statusFilter}) {
    var query = _supabase.from('delivery_assignments').stream(primaryKey: ['id']);
    
    return query.map((data) {
      var list = data.map((json) => DeliveryAssignment.fromJson(json)).toList();
      if (statusFilter != null) {
        list = list.where((a) => a.status.dbValue == statusFilter).toList();
      }
      return list;
    });
  }

  /// Gets a list of available riders in a specific zone.
  Future<List<Rider>> getAvailableRiders(String zone) async {
    try {
      final response = await _supabase
          .from('riders')
          .select()
          .eq('zone', zone)
          .eq('is_available', true);
      
      return (response as List).map((json) => Rider.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get available riders: $e');
    }
  }

  /// Saves a rating for a rider.
  Future<void> saveRiderRating({
    required int orderId,
    required String riderId,
    required int customerId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _supabase.from('rider_ratings').insert({
        'order_id': orderId,
        'rider_id': riderId,
        'customer_id': customerId,
        'rating': rating,
        'feedback': feedback,
      });

      // Optionally update rider's average rating (could also be done via DB trigger)
      // For now, let's keep it simple and just insert the rating.
    } catch (e) {
      throw Exception('Failed to save rider rating: $e');
    }
  }
}
