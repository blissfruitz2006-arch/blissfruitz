import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/delivery_assignment.dart';
import '../models/rider.dart';
import '../services/delivery_service.dart';

/// Provider for the delivery service instance
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService(SupabaseConfig.client);
});

/// Stream provider watching a specific rider's active assignment
final activeAssignmentProvider = StreamProvider.family.autoDispose<DeliveryAssignment?, String>((ref, riderId) {
  final service = ref.watch(deliveryServiceProvider);
  return service.watchRiderActiveAssignment(riderId);
});

/// Future provider fetching available riders for administrative assignment
final availableRidersProvider = FutureProvider.family.autoDispose<List<Rider>, String>((ref, zone) async {
  final service = ref.watch(deliveryServiceProvider);
  return await service.getAvailableRiders(zone);
});

/// Stream provider for all assignments (Admin view)
final allAssignmentsProvider = StreamProvider.autoDispose<List<DeliveryAssignment>>((ref) {
  final service = ref.watch(deliveryServiceProvider);
  // Default to all assignments, status filtering can be added via family if needed
  return service.watchAllAssignments();
});

/// Provider for a status-filtered assignment list
final filteredAssignmentsProvider = StreamProvider.family.autoDispose<List<DeliveryAssignment>, String?>((ref, status) {
  final service = ref.watch(deliveryServiceProvider);
  return service.watchAllAssignments(statusFilter: status);
});

/// Stream provider for watching a specific assignment by order ID
final orderAssignmentProvider = StreamProvider.family.autoDispose<DeliveryAssignment?, int>((ref, orderId) {
  return SupabaseConfig.client
      .from('delivery_assignments')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .map((data) => data.isEmpty ? null : DeliveryAssignment.fromJson(data.first));
});

/// Future provider to get full assignment details including rider info
final orderAssignmentFutureProvider = FutureProvider.family.autoDispose<DeliveryAssignment?, int>((ref, orderId) async {
  final service = ref.watch(deliveryServiceProvider);
  return await service.getOrderAssignment(orderId);
});

/// Stream provider for counting active riders (Online)
final activeRiderCountProvider = StreamProvider.autoDispose<int>((ref) {
  return SupabaseConfig.client
      .from('riders')
      .stream(primaryKey: ['id'])
      .eq('is_available', true)
      .map((data) => data.length);
});

/// Stream provider for counting "Out for Delivery" assignments
final outForDeliveryCountProvider = StreamProvider.autoDispose<int>((ref) {
  return SupabaseConfig.client
      .from('delivery_assignments')
      .stream(primaryKey: ['id'])
      .map((data) {
        return data.where((json) {
          final status = json['status'] as String;
          return status != 'delivered' && status != 'failed';
        }).length;
      });
});

/// Stream provider for all assignments for the current rider
final myAssignmentsProvider = StreamProvider.autoDispose<List<DeliveryAssignment>>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(deliveryServiceProvider);
  return service.watchRiderAssignments(user.id);
});
