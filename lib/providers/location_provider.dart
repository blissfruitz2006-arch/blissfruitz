import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/rider_location.dart';
import '../services/location_service.dart';

/// Provider for the location service instance
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(SupabaseConfig.client);
});

/// Stream provider for tracking a specific rider's location in real-time
final riderLocationProvider = StreamProvider.family<RiderLocation?, String>((ref, riderId) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.watchRiderLocation(riderId);
});

final riderAvailabilityProvider = StreamProvider.family<bool, String>((ref, riderId) {
  return SupabaseConfig.client
      .from('riders')
      .stream(primaryKey: ['id'])
      .eq('id', riderId)
      .map((data) => data.isEmpty ? false : (data.first['is_available'] as bool? ?? false));
});

/// State provider for toggling rider's online/offline status
/// This maintains the local UI state before persisting to the service
final isRiderOnlineProvider = StateProvider.autoDispose<bool>((ref) {
  // Ideally initialized from the current rider's profile, but defaults to false
  return false;
});

/// Async provider to handle the side effect of toggling availability
final toggleAvailabilityProvider = FutureProvider.family.autoDispose<void, bool>((ref, isOnline) async {
  final service = ref.watch(locationServiceProvider);
  final riderId = SupabaseConfig.client.auth.currentUser?.id;
  
  if (riderId != null) {
    await service.updateAvailability(riderId, isOnline);
    // Update local state
    ref.read(isRiderOnlineProvider.notifier).state = isOnline;
  }
});
