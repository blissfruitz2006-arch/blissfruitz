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
  /// Assigns a rider to an order.
  /// 
  /// Updates the order status to 'out_for_delivery' and creates a new record in `delivery_assignments`.
  Future<DeliveryAssignment> assignRider(int orderId, String riderId) async {
    debugPrint('DEBUG: Assigning rider $riderId to order $orderId using RPC');
    try {
      // 1. Call the RPC
      final response = await _supabase.rpc('assign_rider_to_order', params: {
        'p_order_id': orderId,
        'p_rider_id': riderId,
      });
      
      debugPrint('DEBUG: RPC Success: $response');

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
      debugPrint('DEBUG: PostgrestException in RPC: ${e.message} (code: ${e.code})');
      if (e.code == '23505') {
        if (e.message.contains('idx_one_active_delivery')) {
          throw Exception('This rider already has an active delivery.');
        } else if (e.message.contains('idx_one_active_assignment_per_order')) {
          throw Exception('This order is already being handled by another rider.');
        }
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('DEBUG: Error in assignRider: $e');
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


      // Also update the Order status to keep them in sync
      if (status == DeliveryStatus.pickedUp || status == DeliveryStatus.onTheWay) {
        // Find the order_id for this assignment
        final assignment = await _supabase
            .from('delivery_assignments')
            .select('order_id')
            .eq('id', assignmentId)
            .maybeSingle();
        
        if (assignment != null && assignment['order_id'] != null) {
          await _supabase.from('Order').update({
            'orderStatus': 'out_for_delivery',
            'updatedAt': DateTime.now().toIso8601String(),
          }).eq('id', assignment['order_id']);
        }
      }
    } catch (e) {
      throw Exception('Failed to update delivery status: $e');
    }
  }

  /// Uploads a delivery proof image to Supabase Storage.
  Future<String> uploadDeliveryProof(String assignmentId, Uint8List imageBytes) async {
    try {
      final fileName = '$assignmentId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('delivery-proofs').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
      );
      
      return _supabase.storage.from('delivery-proofs').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('DEBUG: Error in uploadDeliveryProof: $e');
      throw Exception('Failed to upload delivery proof: $e');
    }
  }

  /// Confirms delivery using a photo proof.
  /// 
  /// Uses a SECURITY DEFINER RPC to atomically save the proof URL, mark assignment
  /// as delivered, and update the Order status.
  /// Legacy confirmDelivery method - updated to use correct POD flow
  Future<void> confirmDelivery(String assignmentId, String publicUrl) async {
    try {
      final ok = await confirmDeliveryWithPhoto(assignmentId, publicUrl);
      if (!ok) throw Exception('Failed to confirm delivery');
    } catch (e) {
      throw Exception('Failed to confirm delivery: $e');
    }
  }

  Future<bool> confirmDeliveryWithPhoto(String assignmentId, String imageUrl) async {
    try {
      final response = await _supabase.rpc('confirm_delivery', params: {
        'p_assignment_id': assignmentId,
        'p_proof_image_url': imageUrl,
      });

      final result = response as Map<String, dynamic>;

      if (result['success'] != true) {
        debugPrint('Delivery confirmation failed: ${result['error']}');
        return false;
      }

      // Calculate and save earnings after successful delivery
      // Fallback to current auth user if RPC doesn't return rider_id
      final String? riderId = result['rider_id'] ?? _supabase.auth.currentUser?.id;
      if (riderId != null) {
        await calculateAndSaveEarnings(assignmentId, riderId);
      } else {
        debugPrint('Warning: Could not determine rider_id for earnings calculation');
      }

      return true;
    } catch (e) {
      debugPrint('Error in confirmDeliveryWithPhoto: $e');
      throw Exception('Failed to confirm delivery: $e');
    }
  }

  /// Calculates earnings for a delivery and saves it to the database.
  /// 
  /// Logic: Base ₹40 + ₹5 per km bonus (placeholder distance = 5km).
  Future<void> calculateAndSaveEarnings(String assignmentId, String riderId) async {
    try {
      // 1. Fetch delivery settings and order coordinates
      final settings = await _supabase.from('settings_delivery').select().eq('id', 1).single();
      final assignment = await _supabase.from('delivery_assignments').select('order_id, Order(latitude, longitude)').eq('id', assignmentId).single();
      
      final double baseEarnings = (settings['base_earnings'] as num?)?.toDouble() ?? 40.0;
      final double bonusPerKm = (settings['bonus_per_km'] as num?)?.toDouble() ?? 5.0;
      final double minDistance = (settings['min_distance_for_bonus'] as num?)?.toDouble() ?? 0.0;
      final double storeLat = (settings['store_latitude'] as num?)?.toDouble() ?? 22.5726;
      final double storeLng = (settings['store_longitude'] as num?)?.toDouble() ?? 88.3639;

      final orderData = assignment['Order'] as Map<String, dynamic>?;
      final double? orderLat = (orderData?['latitude'] as num?)?.toDouble();
      final double? orderLng = (orderData?['longitude'] as num?)?.toDouble();

      double distanceKm = 5.0; // Default if coordinates are missing
      if (orderLat != null && orderLng != null) {
        distanceKm = _calculateDistance(storeLat, storeLng, orderLat, orderLng);
      }

      double bonusEarnings = 0.0;
      if (distanceKm > minDistance) {
        bonusEarnings = (distanceKm - minDistance) * bonusPerKm;
      }
      
      final double totalEarnings = baseEarnings + bonusEarnings;

      // 2. Insert into delivery_earnings
      await _supabase.from('delivery_earnings').insert({
        'assignment_id': assignmentId,
        'rider_id': riderId,
        'base_earnings': baseEarnings,
        'bonus_earnings': bonusEarnings,
        'total_earnings': totalEarnings,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Update rider's total earnings and delivery count via RPC
      // This RPC should handle the increment of both total_deliveries and total_earnings in the riders table
      await _supabase.rpc('increment_rider_stats', params: {
        'r_id': riderId,
        'earnings_increment': totalEarnings,
      });
      
      debugPrint('DEBUG: Earnings saved successfully for rider $riderId');
    } catch (e) {
      // Log error but don't block the delivery completion flow
      debugPrint('CRITICAL: Error saving earnings for assignment $assignmentId: $e');
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

  /// Watches all assignments for a specific rider.
  Stream<List<DeliveryAssignment>> watchRiderAssignments(String riderId) {
    return _supabase
        .from('delivery_assignments')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .order('assigned_at', ascending: false)
        .map((data) => data.map((json) => DeliveryAssignment.fromJson(json)).toList());
  }

  /// Gets a list of available riders in a specific zone.
  Future<List<Rider>> getAvailableRiders(String zone) async {
    try {
      var query = _supabase.from('riders').select().eq('is_available', true);
      
      if (zone != 'All Zones' && zone.isNotEmpty) {
        query = query.ilike('zone', '%$zone%');
      }

      final response = await query;
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

  /// Calculates the Haversine distance between two coordinates in kilometers.
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
