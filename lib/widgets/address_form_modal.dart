import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/address_service.dart';
import '../models/address.dart';

class AddressFormModal extends ConsumerStatefulWidget {
  final Address? address;
  final Function(Address address, String? email)? onSave;

  const AddressFormModal({super.key, this.address, this.onSave});

  @override
  ConsumerState<AddressFormModal> createState() => _AddressFormModalState();
}

class _AddressFormModalState extends ConsumerState<AddressFormModal> {
  final _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();
  
  // Controllers for filling data from location
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  late String _label = 'Home';
  bool _isDefault = false;
  bool _loading = false;
  bool _locating = false;
  double? _latitude;
  double? _longitude;
  
  // Default center if no location (e.g., center of India)
  LatLng _mapCenter = const LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.address?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _emailController = TextEditingController(text: '');
    _line1Controller = TextEditingController(text: widget.address?.line1 ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _pincodeController = TextEditingController(text: widget.address?.pincode ?? '');
    
    if (widget.address != null) {
      _label = widget.address!.label ?? 'Home';
      _isDefault = widget.address!.isDefault;
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
      if (_latitude != null && _longitude != null) {
        _mapCenter = LatLng(_latitude!, _longitude!);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locating = true);
    try {
      // 1. Check Service
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw 'Location services are disabled.';
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          debugPrint('Geolocator service check not ready, assuming enabled on web.');
        } else {
          rethrow;
        }
      }

      // 2. Check Permissions
      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw 'Location permissions are denied';
        }
        if (permission == LocationPermission.deniedForever) throw 'Location permissions are permanently denied';
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          debugPrint('Geolocator permission check not ready, trying direct fetch.');
        } else {
          rethrow;
        }
      }

      // 3. Get Position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      _updateLocation(LatLng(position.latitude, position.longitude));
      
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('MissingPluginException')) {
          msg = "Location service not ready. Please refresh the page or restart the app.";
        } else if (msg.contains('TimeoutException') || msg.contains('time limit')) {
          msg = "Location request timed out. Please try again or pick on map.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Manual', 
            textColor: Colors.white,
            onPressed: () {} // Just dismiss
          ),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _updateLocation(LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _mapCenter = point;
    });
    _mapController.move(point, 15);
    _reverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      // Use Nominatim API as it works on Web and Mobile without native plugins
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'BlissfruitzApp/1.0',
        'Accept-Language': 'en-US,en;q=0.5',
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          setState(() {
            _line1Controller.text = _formatStreet(address);
            _cityController.text = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '';
            _stateController.text = address['state'] ?? '';
            _pincodeController.text = address['postcode'] ?? '';
          });
          return;
        }
      }
      
      // Fallback
      if (!kIsWeb) {
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            setState(() {
              _line1Controller.text = "${place.street ?? ''}, ${place.subLocality ?? ''}".replaceAll(RegExp(r'^,\s*'), '');
              _cityController.text = place.locality ?? '';
              _stateController.text = place.administrativeArea ?? '';
              _pincodeController.text = place.postalCode ?? '';
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  String _formatStreet(Map address) {
    final List<String> parts = [];
    if (address['house_number'] != null) parts.add(address['house_number']);
    if (address['road'] != null) parts.add(address['road']);
    if (address['suburb'] != null) parts.add(address['suburb']);
    return parts.join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = ref.read(userProfileProvider).valueOrNull;
      if (user == null) {
        Navigator.pop(context);
        return;
      }
      
      final addr = Address(
        id: widget.address?.id,
        userId: user.id,
        label: _label,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        line1: _line1Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (widget.address == null) {
        await AddressService.addAddress(addr);
      } else {
        await AddressService.updateAddress(addr);
      }
      widget.onSave?.call(addr, _emailController.text.trim().isEmpty ? null : _emailController.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _loading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait while we save your address...')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.address == null ? 'Add New Address' : 'Edit Address',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Map Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _mapCenter,
                                initialZoom: 15.0,
                                onTap: (_, point) => _updateLocation(point),
                                onPositionChanged: (position, hasGesture) {
                                  if (hasGesture) {
                                    // Debounce reverse geocoding to avoid rate limits
                                    setState(() {
                                      _latitude = position.center.latitude;
                                      _longitude = position.center.longitude;
                                    });
                                  }
                                },
                                onMapEvent: (event) {
                                  if (event is MapEventMoveEnd) {
                                    _reverseGeocode(event.camera.center.latitude, event.camera.center.longitude);
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: isDark 
                                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                    : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.blissfruitz.app',
                                ),
                                if (_latitude != null && _longitude != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(_latitude!, _longitude!),
                                        width: 80,
                                        height: 80,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
                                                ],
                                              ),
                                              child: const Text('Deliver here', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                            const Icon(Icons.location_on, color: AppTheme.error, size: 40),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Column(
                                children: [
                                  FloatingActionButton.small(
                                    heroTag: 'locate_bt',
                                    onPressed: _locating ? null : _getCurrentLocation,
                                    backgroundColor: Colors.white,
                                    child: _locating 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.my_location, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    heroTag: 'zoom_in',
                                    onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.add, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    heroTag: 'zoom_out',
                                    onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.remove, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                            ),
                            // Center Marker Overlay
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 35),
                                child: Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 40),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)],
                                ),
                                child: const Text(
                                  'Drag map or tap to pick your precise delivery location',
                                  style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Label Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Home', 'Office', 'Other'].map((l) {
                        final selected = _label == l;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(l),
                            selected: selected,
                            onSelected: (_) => setState(() => _label = l),
                            selectedColor: AppTheme.primary,
                            labelStyle: TextStyle(color: selected ? Colors.white : null),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildField('Full Name', _fullNameController),
                    if (ref.read(userProfileProvider).valueOrNull == null)
                      _buildField('Email', _emailController, keyboard: TextInputType.emailAddress),
                    _buildField('Phone Number', _phoneController, keyboard: TextInputType.phone),
                    _buildField('Address Line 1', _line1Controller),
                    Row(
                      children: [
                        Expanded(child: _buildField('City', _cityController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Pincode', _pincodeController, keyboard: TextInputType.number)),
                      ],
                    ),
                    _buildField('State', _stateController),
                    
                    SwitchListTile.adaptive(
                      title: const Text('Set as default address'),
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeTrackColor: AppTheme.primary,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppTheme.primary,
                      ),
                      child: _loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Address', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildField(String label, TextEditingController controller, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.beVietnamPro(fontSize: 14),
        ),
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
