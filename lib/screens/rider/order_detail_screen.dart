import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/delivery_assignment.dart';
import '../../models/rider.dart';
import '../../providers/delivery_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final DeliveryAssignment assignment;
  const OrderDetailScreen({super.key, required this.assignment});
  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late DeliveryAssignment _assignment;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
  }

  Future<void> _updateStatus(DeliveryStatus newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final service = ref.read(deliveryServiceProvider);
      await service.updateDeliveryStatus(_assignment.id, newStatus);
      setState(() => _assignment = _assignment.copyWith(status: newStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${_assignment.statusLabel}'),
          backgroundColor: const Color(0xFF059669),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.error));
    } finally { if (mounted) setState(() => _isUpdating = false); }
  }

  Future<void> _launchMaps() async {
    final order = _assignment.order;
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
    final phone = _assignment.order?.shippingPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showOtpSheet() {
    final otpCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Icon(Icons.verified_user_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text('Enter Delivery OTP', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text('Ask the customer for the 4-digit code', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            Pinput(
              controller: otpCtrl,
              length: 4,
              defaultPinTheme: PinTheme(
                width: 60, height: 60,
                textStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: cs.onSurface),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceContainerLow : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 60, height: 60,
                textStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: cs.primary),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceContainerLow : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () async {
                if (otpCtrl.text.length != 4) return;
                Navigator.pop(ctx);
                setState(() => _isUpdating = true);
                try {
                  final service = ref.read(deliveryServiceProvider);
                  final ok = await service.confirmDeliveryWithOtp(_assignment.id, otpCtrl.text);
                  if (ok) {
                    setState(() => _assignment = _assignment.copyWith(status: DeliveryStatus.delivered));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Delivery confirmed!'), backgroundColor: Color(0xFF059669)));
                      Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context); });
                    }
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Try again.'), backgroundColor: AppTheme.error));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.error));
                } finally { if (mounted) setState(() => _isUpdating = false); }
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Verify & Complete'),
            )),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final order = _assignment.order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_assignment.orderId}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              _statusBanner(cs),
              const SizedBox(height: 16),
              _orderCard(order, isDark, cs),
              const SizedBox(height: 12),
              _customerCard(order, isDark, cs),
              const SizedBox(height: 12),
              _mapPlaceholder(isDark, cs),
              const SizedBox(height: 20),
              _actionButtons(cs),
              const SizedBox(height: 24),
            ]),
    );
  }

  Widget _statusBanner(ColorScheme cs) {
    Color bg;
    switch (_assignment.status) {
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
        Text(_assignment.statusLabel, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: bg)),
        const Spacer(),
        if (_assignment.assignedAt != null) Text(_formatTime(_assignment.assignedAt!), style: TextStyle(fontSize: 12, color: bg.withValues(alpha: 0.7))),
      ]),
    );
  }

  IconData _statusIcon() {
    switch (_assignment.status) {
      case DeliveryStatus.assigned: return Icons.assignment_rounded;
      case DeliveryStatus.pickedUp: return Icons.inventory_2_rounded;
      case DeliveryStatus.onTheWay: return Icons.delivery_dining_rounded;
      case DeliveryStatus.delivered: return Icons.check_circle_rounded;
      default: return Icons.error_outline_rounded;
    }
  }

  Widget _orderCard(dynamic order, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Summary', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 12),
        _infoRow('Order ID', '#${_assignment.orderId}', cs),
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
    final status = _assignment.status;
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
          onPressed: _showOtpSheet,
          icon: const Icon(Icons.verified_rounded),
          label: const Text('Confirm Delivery (OTP)'),
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
