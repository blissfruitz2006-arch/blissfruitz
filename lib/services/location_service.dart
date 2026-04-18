import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rider_location.dart';

/// Service for handling rider location tracking and broadcasting.
class LocationService {
  final SupabaseClient _supabase;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  LocationService(this._supabase);

  /// Requests location permissions from the user.
  /// 
  /// Throws an exception if permission is denied or service is disabled.
  Future<void> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
  }

  /// Starts real-time broadcasting of rider's location to Supabase.
  /// 
  /// Uses Geolocator.getPositionStream for battery-efficient, smooth updates.
  void startBroadcasting(String riderId) {
    _positionSubscription?.cancel();
    
    // Set rider as available initially
    _supabase.from('riders').update({
      'is_available': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', riderId).then((_) => debugPrint('Rider $riderId is now online'));

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update only if moved 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        _lastPosition = position;
        try {
          await _supabase.from('riders').update({
            'current_latitude': position.latitude,
            'current_longitude': position.longitude,
            'last_location_update': DateTime.now().toIso8601String(),
          }).eq('id', riderId);
          debugPrint('Broadcasted movement: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          debugPrint('Error broadcasting position: $e');
        }
      },
      onError: (e) {
        debugPrint('Location stream error: $e. Using last known location: ${_lastPosition?.latitude}');
      },
    );
  }

  /// Updates the availability status of a rider.
  Future<void> updateAvailability(String riderId, bool isAvailable) async {
    try {
      await _supabase.from('riders').update({
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', riderId);
      
      if (!isAvailable) {
        stopBroadcasting(riderId);
      }
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  /// Stops broadcasting location and sets rider availability to false.
  Future<void> stopBroadcasting(String riderId) async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      await _supabase.from('riders').update({
        'is_available': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', riderId);
      debugPrint('Stopped broadcasting for rider $riderId');
    } catch (e) {
      debugPrint('Error stopping broadcast: $e');
    }
  }

  /// Watches a specific rider's location in real-time.
  Stream<RiderLocation?> watchRiderLocation(String riderId) {
    return _supabase
        .from('riders')
        .stream(primaryKey: ['id'])
        .eq('id', riderId)
        .map((data) {
          if (data.isEmpty) return null;
          final json = data.first;
          if (json['current_latitude'] == null) return null;
          
          return RiderLocation(
            riderId: json['id'],
            lat: (json['current_latitude'] as num).toDouble(),
            lng: (json['current_longitude'] as num).toDouble(),
            heading: 0.0, // Default if not tracked separately
            updatedAt: DateTime.tryParse(json['last_location_update'] ?? '') ?? DateTime.now(),
          );
        });
  }
}
