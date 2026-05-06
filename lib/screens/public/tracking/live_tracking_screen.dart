import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../models/delivery_assignment.dart';
import '../../../models/rider.dart';
import '../../../providers/delivery_provider.dart';
import '../../../providers/location_provider.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  const LiveTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _confettiController;
  bool _isDelivered = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleStatusUpdate(DeliveryStatus status, DeliveryAssignment assignment) {
    if (status == DeliveryStatus.delivered && !_isDelivered) {
      setState(() => _isDelivered = true);
      _confettiController.forward().then((_) {
        if (mounted) {
          context.go('/order-success?orderId=${widget.orderId}');
        }
      });
    }
  }

  Future<void> _callRider(String? phone) async {
    if (phone == null) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentAsync = ref.watch(orderAssignmentProvider(widget.orderId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: assignmentAsync.when(
        data: (assignment) {
          if (assignment == null) {
            return const Center(child: Text('Tracking information not available yet.'));
          }

          // Trigger navigation if delivered
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleStatusUpdate(assignment.status, assignment));

          final riderId = assignment.riderId;
          final riderLocationAsync = ref.watch(riderLocationProvider(riderId));
          final rider = assignment.rider;
          final order = assignment.order;

          final customerPos = LatLng(order?.latitude ?? 12.9716, order?.longitude ?? 77.5946);
          
          return Stack(
            children: [
              // Map View
              riderLocationAsync.when(
                data: (loc) {
                  final riderPos = loc != null ? LatLng(loc.lat, loc.lng) : customerPos;
                  
                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: riderPos,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark 
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [riderPos, customerPos],
                            color: cs.primary.withValues(alpha: 0.5),
                            strokeWidth: 4,
                            // strokePattern: StrokePattern.dotted(), // Available in some versions of flutter_map
                            borderColor: cs.primary.withValues(alpha: 0.3),
                            borderStrokeWidth: 1,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // Destination Marker
                          Marker(
                            point: customerPos,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
                          ),
                          // Rider Marker
                          Marker(
                            point: riderPos,
                            width: 60,
                            height: 60,
                            child: _riderMarker(cs),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading location: $e')),
              ),

              // Top Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: cs.surface,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Bottom Sheet (Persistent)
              Align(
                alignment: Alignment.bottomCenter,
                child: _bottomPanel(assignment, rider, cs, isDark),
              ),

              // Confetti Overlay
              if (_isDelivered)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ConfettiPainter(_confettiController.value),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _riderMarker(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 2)],
      ),
      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _bottomPanel(DeliveryAssignment assignment, Rider? rider, ColorScheme cs, bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  rider?.fullName != null && rider!.fullName.isNotEmpty 
                      ? rider.fullName.substring(0, 1).toUpperCase() 
                      : 'R',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider?.fullName ?? 'Assigning Rider...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(rider?.vehicleType ?? 'Delivery Partner', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(assignment.status, cs),
                  const SizedBox(height: 4),
                  Text('ETA: 15-20 mins', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                ],
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callRider(rider?.phone),
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call Delivery Partner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(DeliveryStatus status, ColorScheme cs) {
    Color color;
    String label;
    switch (status) {
      case DeliveryStatus.assigned: color = Colors.blue; label = 'Assigned'; break;
      case DeliveryStatus.pickedUp: color = Colors.orange; label = 'Picked Up'; break;
      case DeliveryStatus.onTheWay: color = Colors.purple; label = 'On the Way'; break;
      case DeliveryStatus.delivered: color = Colors.green; label = 'Delivered'; break;
      default: color = Colors.grey; label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.pink, Colors.orange];
    
    for (int i = 0; i < 50; i++) {
      final p = (progress + (i / 50)) % 1.0;
      final x = (i * 137.5) % size.width;
      final y = p * size.height;
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawCircle(Offset(x, y), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

