import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/rider.dart';
import '../models/delivery_assignment.dart';
import '../services/rider_service.dart';

/// Provider for the RiderService instance
final riderServiceProvider = Provider<RiderService>((ref) {
  return RiderService(SupabaseConfig.client);
});

/// Provider for the current authenticated rider's profile
final riderProfileProvider = FutureProvider.autoDispose<Rider?>((ref) async {
  final service = ref.watch(riderServiceProvider);
  return await service.getCurrentRiderProfile();
});

/// Stream provider for the current rider's assignments
final myAssignmentsProvider = StreamProvider.autoDispose<List<DeliveryAssignment>>((ref) {
  final service = ref.watch(riderServiceProvider);
  return service.getMyAssignmentsStream();
});

/// Provider for all riders (Admin use)
final allRidersProvider = FutureProvider.autoDispose<List<Rider>>((ref) async {
  final service = ref.watch(riderServiceProvider);
  return await service.getAllRiders();
});

/// Provider for a specific assignment's details
final assignmentDetailProvider = FutureProvider.family.autoDispose<DeliveryAssignment?, String>((ref, id) async {
  final assignments = await ref.watch(myAssignmentsProvider.future);
  try {
    return assignments.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});
