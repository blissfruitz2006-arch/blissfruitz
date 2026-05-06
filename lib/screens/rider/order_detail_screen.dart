import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/delivery_assignment.dart';
import '../../models/rider.dart';
import '../../providers/delivery_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final DeliveryAssignment? assignment;
  
  const OrderDetailScreen({
    super.key, 
    this.orderId,
    this.assignment,
  });
  
  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  DeliveryAssignment? _assignment;
  bool _isLoading = false;
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
      final found = assignments.where((a) => 
        a.id == widget.orderId || a.orderId.toString() == widget.orderId
      ).firstOrNull;
      
      if (mounted) {
        setState(() => _assignment = found);
      }
    } catch (e) {
      debugPrint('Error loading assignment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(DeliveryStatus newStatus) async {
    if (_isUpdating || _assignment == null) return;
    setState(() => _isUpdating = true);
    try {
      final service = ref.read(deliveryServiceProvider);
      final id = _assignment?.id;
      if (id == null) return;
      await service.updateDeliveryStatus(id, newStatus);
      if (mounted) {
        setState(() => _assignment = _assignment?.copyWith(status: newStatus));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${_assignment!.statusLabel}'),
          backgroundColor: const Color(0xFF059669),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.error));
    } finally { if (mounted) setState(() => _isUpdating = false); }
  }

  Future<void> _launchMaps() async {
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

  Future<void> _callCustomer() async {
    if (_assignment == null) return;
    final phone = _assignment!.order?.shippingPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _showPhotoConfirmationSheet() async {
    if (_assignment == null) return;
    final picker = ImagePicker();
    XFile? pickedFile;
    Uint8List? imageBytes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Icon(Icons.camera_alt_rounded, size: 48, color: cs.primary),
                const SizedBox(height: 12),
                Text('Delivery Confirmation', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 6),
                Text('Take a picture of the delivery as proof', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  )
                else
                  GestureDetector(
                    onTap: () async {
                      pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (pickedFile != null) {
                        final bytes = await pickedFile!.readAsBytes();
                        setModalState(() {
                          imageBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceContainerLow : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.3), style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 40, color: cs.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('Click to Take Photo', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: imageBytes == null ? null : () async {
                    Navigator.pop(ctx);
                    setState(() => _isUpdating = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      final service = ref.read(deliveryServiceProvider);
                      
                      final id = _assignment?.id;
                      if (id == null) return;
                      
                      // 1. Upload the image
                      final imageUrl = await service.uploadDeliveryProof(id, imageBytes!);
                      
                      // 2. Confirm delivery with image URL
                      final ok = await service.confirmDeliveryWithPhoto(id, imageUrl);
                      
                      if (ok) {
                        setState(() => _assignment = _assignment?.copyWith(status: DeliveryStatus.delivered));
                        if (mounted) {
                          messenger.showSnackBar(const SnackBar(content: Text('🎉 Delivery confirmed with photo!'), backgroundColor: Color(0xFF059669)));
                          Future.delayed(const Duration(seconds: 1), () { if (mounted) navigator.pop(); });
                        }
                      } else {
                        if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Failed to confirm delivery. Try again.'), backgroundColor: AppTheme.error));
                      }
                    } catch (e) {
                      if (mounted) messenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.error));
                    } finally { if (mounted) setState(() => _isUpdating = false); }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Confirm & Complete'),
                )),
                const SizedBox(height: 12),
                if (imageBytes != null)
                  TextButton(
                    onPressed: () => setModalState(() => imageBytes = null),
                    child: const Text('Retake Photo'),
                  ),
              ]),
            );
          }
        );
      },
    );
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

    return Scaffold(
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              children: [
                // Custom Header with Back Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHigh,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Order #${_assignment!.orderId}',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _statusBanner(cs),
                const SizedBox(height: 16),
                _orderCard(order, isDark, cs),
                const SizedBox(height: 12),
                _customerCard(order, isDark, cs),
                const SizedBox(height: 12),
                _mapPlaceholder(isDark, cs),
                const SizedBox(height: 20),
                _actionButtons(cs),
              ],
            ),
    );
  }

  Widget _statusBanner(ColorScheme cs) {
    final assignment = _assignment!;
    Color bg;
    switch (assignment.status) {
      case DeliveryStatus.assigned: bg = const Color(0xFF3B82F6); break;
      case DeliveryStatus.pickedUp: bg = const Color(0xFFF59E0B); break;
      case DeliveryStatus.onTheWay: bg = const Color(0xFF8B5CF6); break;
      case DeliveryStatus.delivered: bg = const Color(0xFF059669); break;
      default: bg = AppTheme.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: bg.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(_statusIcon(), color: bg, size: 22),
        const SizedBox(width: 10),
        Text(assignment.statusLabel, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: bg)),
        const Spacer(),
        if (assignment.assignedAt != null) Text(_formatTime(assignment.assignedAt!), style: TextStyle(fontSize: 12, color: bg.withValues(alpha: 0.7))),
      ]),
    );
  }

  IconData _statusIcon() {
    final assignment = _assignment!;
    switch (assignment.status) {
      case DeliveryStatus.assigned: return Icons.assignment_rounded;
      case DeliveryStatus.pickedUp: return Icons.inventory_2_rounded;
      case DeliveryStatus.onTheWay: return Icons.delivery_dining_rounded;
      case DeliveryStatus.delivered: return Icons.check_circle_rounded;
      default: return Icons.error_outline_rounded;
    }
  }

  Widget _orderCard(dynamic order, bool isDark, ColorScheme cs) {
    final assignment = _assignment!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Summary', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 12),
        _infoRow('Order ID', '#${assignment.orderId}', cs),
        _infoRow('Items', '${order?.items.length ?? 0} items', cs),
        _infoRow('Total', '₹${(order?.total ?? 0).toStringAsFixed(2)}', cs, bold: true),
        _infoRow('Payment', order?.paymentLabel ?? 'N/A', cs),
      ]),
    );
  }

  Widget _customerCard(dynamic order, bool isDark, ColorScheme cs) {
    final addr = [order?.shippingAddress, order?.shippingCity, order?.shippingState, order?.shippingPincode].where((s) => s != null && s.isNotEmpty).join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Customer Details', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 12),
        _infoRow('Name', order?.shippingName ?? 'N/A', cs),
        Row(children: [
          Text('Phone', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          GestureDetector(
            onTap: _callCustomer,
            child: Row(children: [
              Icon(Icons.phone_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text(order?.shippingPhone ?? 'N/A', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.location_on_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(addr.isNotEmpty ? addr : 'No address', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
        ]),
      ]),
    );
  }

  Widget _mapPlaceholder(bool isDark, ColorScheme cs) {
    return GestureDetector(
      onTap: _launchMaps,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceContainerLow : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.map_rounded, size: 40, color: cs.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text('Tap to open in Google Maps', style: TextStyle(fontSize: 13, color: cs.primary)),
        ])),
      ),
    );
  }

  Widget _actionButtons(ColorScheme cs) {
    final status = _assignment!.status;
    if (status == DeliveryStatus.delivered || status == DeliveryStatus.failed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
          const SizedBox(width: 8),
          Text('Delivery Completed', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
        ]),
      );
    }

    return Column(children: [
      if (status == DeliveryStatus.assigned)
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _updateStatus(DeliveryStatus.pickedUp),
          icon: const Icon(Icons.inventory_2_rounded),
          label: const Text('Mark as Picked Up'),
        )),
      if (status == DeliveryStatus.pickedUp) ...[
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () { _updateStatus(DeliveryStatus.onTheWay); },
          icon: const Icon(Icons.delivery_dining_rounded),
          label: const Text('Start Delivery'),
        )),
        const SizedBox(height: 10),
      ],
      if (status == DeliveryStatus.pickedUp || status == DeliveryStatus.onTheWay) ...[
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _launchMaps,
          icon: const Icon(Icons.navigation_rounded),
          label: const Text('Navigate to Customer'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )),
        const SizedBox(height: 10),
      ],
      if (status == DeliveryStatus.onTheWay)
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _showPhotoConfirmationSheet,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Confirm Delivery (Photo)'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
        )),
    ]);
  }

  Widget _infoRow(String label, String val, ColorScheme cs, {bool bold = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)), const Spacer(),
      Text(val, style: GoogleFonts.outfit(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: bold ? cs.primary : cs.onSurface)),
    ]));
  }

  String _formatTime(DateTime dt) {
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')}';
  }
}

