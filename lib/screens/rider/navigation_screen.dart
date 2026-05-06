import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/delivery_assignment.dart';
import '../../models/rider.dart';
import '../../providers/delivery_provider.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final DeliveryAssignment? assignment;
  const NavigationScreen({super.key, this.orderId, this.assignment});
  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  DeliveryAssignment? _assignment;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (widget.assignment != null) {
      _assignment = widget.assignment;
      _isLoading = false;
    } else if (widget.orderId != null) {
      _loadAssignment();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAssignment() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await ref.read(myAssignmentsProvider.future);
      final found = assignments.where((a) => a.orderId.toString() == widget.orderId).firstOrNull;
      setState(() {
        _assignment = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openInMaps() async {
    if (_assignment == null) return;
    final order = _assignment!.order;
    final lat = order?.latitude;
    final lng = order?.longitude;
    final addr = order?.shippingAddress ?? '';

    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else if (addr.isNotEmpty) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(addr)}');
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No delivery address available')));
      return;
    }
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _cycleStatus() async {
    if (_isUpdating || _assignment == null) return;

    DeliveryStatus? next;
    switch (_assignment!.status) {
      case DeliveryStatus.assigned:
        next = DeliveryStatus.pickedUp;
        break;
      case DeliveryStatus.pickedUp:
        next = DeliveryStatus.onTheWay;
        break;
      case DeliveryStatus.onTheWay:
        next = DeliveryStatus.delivered;
        break;
      default:
        return;
    }

    setState(() => _isUpdating = true);
    try {
      final service = ref.read(deliveryServiceProvider);
      final id = _assignment?.id;
      if (id == null) return;
      await service.updateDeliveryStatus(id, next);
      if (mounted) {
        setState(() => _assignment = _assignment?.copyWith(status: next));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status → ${_assignment!.statusLabel}'),
          backgroundColor: const Color(0xFF059669),
        ));
        if (next == DeliveryStatus.delivered) {
          Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context); });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Not Found')),
        body: const Center(child: Text('Could not load order details.')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final order = _assignment!.order;

    final addr = [
      order?.shippingAddress,
      order?.shippingCity,
      order?.shippingState,
      order?.shippingPincode,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    // Status theming
    Color statusBg;
    Color statusFg;
    String nextLabel;
    IconData nextIcon;
    switch (_assignment!.status) {
      case DeliveryStatus.assigned:
        statusBg = const Color(0xFF3B82F6);
        statusFg = Colors.white;
        nextLabel = 'Mark Picked Up';
        nextIcon = Icons.inventory_2_rounded;
        break;
      case DeliveryStatus.pickedUp:
        statusBg = const Color(0xFFF59E0B);
        statusFg = Colors.white;
        nextLabel = 'Start Delivery';
        nextIcon = Icons.delivery_dining_rounded;
        break;
      case DeliveryStatus.onTheWay:
        statusBg = const Color(0xFF8B5CF6);
        statusFg = Colors.white;
        nextLabel = 'Mark Delivered';
        nextIcon = Icons.check_circle_rounded;
        break;
      case DeliveryStatus.delivered:
        statusBg = const Color(0xFF059669);
        statusFg = Colors.white;
        nextLabel = 'Completed';
        nextIcon = Icons.done_all_rounded;
        break;
      default:
        statusBg = AppTheme.error;
        statusFg = Colors.white;
        nextLabel = 'Failed';
        nextIcon = Icons.error_outline_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Status chip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: statusBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusBg.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(nextIcon, color: statusBg, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _assignment!.statusLabel,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: statusBg),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order ID
              Text(
                'Order #${_assignment!.orderId}',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),

              const Spacer(),

              // Address prominently displayed
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_on_rounded, color: cs.primary, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Delivery Address',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      addr.isNotEmpty ? addr : 'No address provided',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface, height: 1.4),
                    ),
                    if (order?.shippingName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        order?.shippingName ?? '',
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Open in Maps button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.navigation_rounded, size: 22),
                  label: const Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // FAB for cycling status
      floatingActionButton: (_assignment!.status != DeliveryStatus.delivered && _assignment!.status != DeliveryStatus.failed)
          ? FloatingActionButton.extended(
              onPressed: _isUpdating ? null : _cycleStatus,
              backgroundColor: statusBg,
              foregroundColor: statusFg,
              icon: _isUpdating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(nextIcon),
              label: Text(nextLabel, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

