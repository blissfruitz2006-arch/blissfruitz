import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/invoice_service.dart';
import '../../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final orderId = int.tryParse(widget.orderId) ?? 0;
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Title(
      title: 'Track Order | Blissfruitz',
      color: AppTheme.primary,
      child: Scaffold(
        body: orderAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading order details...'),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(orderDetailsProvider(orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (order) {
            if (order == null) {
              return const Center(child: Text('Order not found.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(order),
                  const SizedBox(height: 12),
                  if (order.orderStatus == 'cancelled' || 
                      order.paymentStatus == 'refund_pending' || 
                      order.paymentStatus == 'refunded' ||
                      order.orderStatus.contains('return') ||
                      order.orderStatus.contains('replace') ||
                      order.orderStatus.contains('refund'))
                    _buildRefundAlert(order),
                  const SizedBox(height: 32),
                  _buildTrackingTimeline(order),
                  const SizedBox(height: 32),
                  if (order.trackingNumber != null || order.locationLink != null)
                    _buildTrackingDetails(order),
                  const SizedBox(height: 32),
                  _buildShippingInfo(order),
                  const SizedBox(height: 32),
                  if (order.orderStatus == 'pending' || order.orderStatus == 'confirmed')
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _isProcessing ? null : () => _showCancelDialog(order),
                        icon: _isProcessing 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error))
                          : const Icon(Icons.cancel_outlined, color: AppTheme.error),
                        label: Text(
                          _isProcessing ? 'Cancelling...' : 'Cancel Order', 
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppTheme.error.withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                    ),
                  if (order.orderStatus == 'pending' || order.orderStatus == 'confirmed')
                    const SizedBox(height: 16),
                  if (order.orderStatus == 'delivered')
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final deliveredAt = order.deliveredAt ?? order.updatedAt ?? now;
                        final difference = now.difference(deliveredAt);
                        final remainingMinutes = 30 - difference.inMinutes;
                        final isReturnAllowed = remainingMinutes > 0;

                        return Column(
                          children: [
                            if (isReturnAllowed) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 20, color: AppTheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Return/Replacement window expires in $remainingMinutes minutes.',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showReturnReplaceDialog(order, true),
                                  icon: const Icon(Icons.assignment_return_outlined),
                                  label: const Text('Request Return'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                                    foregroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showReturnReplaceDialog(order, false),
                                  icon: const Icon(Icons.published_with_changes_outlined),
                                  label: const Text('Request Replacement'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
                                    foregroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ] else ...[
                             Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.onSurface.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_clock_outlined, size: 20, color: AppTheme.onSurfaceVariant),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'The 30-minute return/replacement window has ended.',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => InvoiceService.downloadInvoice(order),
                                icon: const Icon(Icons.description_outlined),
                                label: const Text('Download Invoice'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                  foregroundColor: AppTheme.onSurfaceVariant,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
                    _buildAdminNotes(order),
                  const SizedBox(height: 80), // Padding for bottom nav
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed on ${DateFormat('MMM dd, yyyy').format(order.createdAt ?? DateTime.now())}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: _buildStatusBadge(order)),
          const SizedBox(width: 12),
          Text(
            '₹${order.total.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundAlert(Order order) {
    String title = 'Order Cancelled';
    String message = 'Your order has been cancelled.';
    IconData icon = Icons.cancel;
    Color color = AppTheme.error;

    if (order.paymentStatus == 'refund_pending') {
      title = 'Refund Pending';
      message = 'Your refund of ₹${order.total} is being processed.';
      icon = Icons.pending_actions;
      color = Colors.orange;
    } else if (order.paymentStatus == 'refunded') {
      title = 'Refunded';
      message = 'A refund of ₹${order.total} has been issued to your original payment method.';
      icon = Icons.check_circle;
      color = Colors.teal;
    } else if (order.orderStatus == 'return_requested') {
      title = 'Return Requested';
      message = 'Your return request for "${order.returnReason ?? 'Reason not specified'}" is being reviewed.';
      icon = Icons.assignment_return;
      color = AppTheme.primary;
    } else if (order.orderStatus == 'replacement_requested') {
      title = 'Replacement Requested';
      message = 'Your replacement request for "${order.replacementReason ?? 'Reason not specified'}" is being reviewed.';
      icon = Icons.published_with_changes;
      color = Colors.blue;
    } else if (order.orderStatus == 'return_approved') {
      title = 'Return Approved';
      message = 'Your return request has been approved. Our pickup partner will contact you soon.';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (order.orderStatus == 'replacement_approved') {
      title = 'Replacement Approved';
      message = 'Your replacement request has been approved and is being processed.';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (order.orderStatus == 'return_rejected') {
      title = 'Return Rejected';
      message = 'Your return request has been declined. Please check admin feedback below.';
      icon = Icons.cancel_outlined;
      color = AppTheme.error;
    } else if (order.orderStatus == 'replacement_rejected') {
      title = 'Replacement Rejected';
      message = 'Your replacement request has been declined. Please check admin feedback below.';
      icon = Icons.cancel_outlined;
      color = AppTheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color)),
                Text(message, style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotes(Order order) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Admin Feedback',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.adminNotes!,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTrackingTimeline(Order order) {
    List<Map<String, dynamic>> stages;
    String currentStatus = order.orderStatus.toLowerCase();

    // Check if it's a return/replacement/refund flow
    if (currentStatus.contains('return') || currentStatus.contains('replace') || currentStatus.contains('refund')) {
      if (currentStatus.contains('rejected')) {
        stages = [
          {'status': 'delivered', 'label': 'Delivered', 'icon': Icons.home_outlined},
          {
            'status': currentStatus.contains('replace') ? 'replacement_requested' : 'return_requested',
            'label': '${currentStatus.contains('replace') ? 'Replacement' : 'Return'} Requested',
            'icon': Icons.assignment_return_outlined
          },
          {
            'status': currentStatus,
            'label': 'Request Rejected',
            'icon': Icons.cancel_outlined,
            'isError': true
          },
        ];
      } else {
        stages = [
          {'status': 'delivered', 'label': 'Delivered', 'icon': Icons.home_outlined},
          {
            'status': currentStatus.contains('replace') ? 'replacement_requested' : 'return_requested',
            'label': '${currentStatus.contains('replace') ? 'Replacement' : 'Return'} Requested',
            'icon': Icons.assignment_return_outlined
          },
          {
            'status': currentStatus.contains('replace') ? 'replacement_approved' : 'return_approved',
            'label': 'Request Approved',
            'icon': Icons.check_circle_outline
          },
          {
            'status': currentStatus.contains('replace') ? 'replaced' : (currentStatus.contains('refund') ? 'refunded' : 'returned'),
            'label': currentStatus.contains('replace') ? 'Replaced' : (currentStatus.contains('refund') ? 'Refunded' : 'Completed'),
            'icon': Icons.task_alt_outlined
          },
        ];
      }
    } else if (currentStatus == 'failed') {
      stages = [
        {'status': 'pending', 'label': 'Order Placed', 'icon': Icons.assignment_turned_in_outlined},
        {'status': 'failed', 'label': 'Payment Failed', 'icon': Icons.error_outline_rounded, 'isError': true},
      ];
    } else {
      // Normal delivery flow
      stages = [
        {'status': 'pending', 'label': 'Order Placed', 'icon': Icons.assignment_turned_in_outlined},
        {'status': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle_outline},
        {'status': 'shipped', 'label': 'Shipped', 'icon': Icons.local_shipping_outlined},
        {'status': 'delivered', 'label': 'Delivered', 'icon': Icons.home_outlined},
      ];
    }

    int currentIdx = stages.indexWhere((s) => s['status'] == currentStatus);
    
    // Fallback logic for intermediate states
    if (currentIdx == -1) {
      if (currentStatus == 'cancelled') {
        return Center(
          child: Column(
            children: [
              const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 48),
              const SizedBox(height: 12),
              Text('Order Cancelled', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.error)),
            ],
          ),
        );
      }

      if (currentStatus == 'failed') {
        // This shouldn't be reached now as we added failed stages, but just in case
        currentIdx = 1;
      } else if (currentStatus == 'processing') {
        currentIdx = 1; // Between placed and confirmed or confirmed and shipped
      } else if (currentStatus.contains('requested')) {
        currentIdx = 1;
      } else if (currentStatus.contains('approved')) {
        currentIdx = 2;
      } else {
        currentIdx = 0; // Default to first stage
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentStatus.contains('return') || currentStatus.contains('replace') || currentStatus.contains('refund')
            ? 'Order Progress' 
            : 'Delivery Status',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(stages.length, (index) {
          final stage = stages[index];
          final bool isErrorState = stage['isError'] == true;
          final isCompleted = index <= currentIdx;
          final isLast = index == stages.length - 1;
          final Color stageColor = isErrorState 
              ? AppTheme.error 
              : (isCompleted ? AppTheme.primary : AppTheme.outline.withValues(alpha: 0.2));

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stageColor,
                      ),
                      child: Icon(
                        isErrorState 
                          ? Icons.close 
                          : (index < currentIdx ? Icons.check : (isCompleted ? Icons.radio_button_checked : Icons.radio_button_off)),
                        size: 14,
                        color: isCompleted || isErrorState ? Colors.white : AppTheme.outline,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < currentIdx ? AppTheme.primary : AppTheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['label'] as String,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isErrorState ? AppTheme.error : (isCompleted ? AppTheme.onSurface : AppTheme.onSurfaceVariant),
                          ),
                        ),
                        if (isCompleted && index == currentIdx)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isErrorState ? 'Case Closed' : 'Current status',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: isErrorState ? AppTheme.error : AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrackingDetails(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking Information',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              if (order.trackingNumber != null)
                _buildInfoRow('Tracking ID', order.trackingNumber!, icon: Icons.tag),
              if (order.trackingNumber != null && order.locationLink != null)
                const Divider(height: 24),
              if (order.locationLink != null)
                InkWell(
                  onTap: () => _launchURL(order.locationLink!),
                  child: _buildInfoRow(
                    'Live Location',
                    'View on map',
                    icon: Icons.map_outlined,
                    trailing: const Icon(Icons.open_in_new, size: 16, color: AppTheme.primary),
                    valueColor: AppTheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfo(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Address',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.shippingName ?? '',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.shippingAddress}, ${order.shippingCity}, ${order.shippingState} - ${order.shippingPincode}',
                style: GoogleFonts.beVietnamPro(fontSize: 14, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone: ${order.shippingPhone}',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, Widget? trailing, Color? valueColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Future<void> _showCancelDialog(Order order) async {
    final List<String> reasons = [
      'Changed my mind',
      'Incorrect items ordered',
      'Found better price elsewhere',
      'Delivery taking too long',
      'Other',
    ];
    String selectedReason = reasons[0];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this order? This action cannot be undone.',
              style: GoogleFonts.beVietnamPro(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason for cancellation:',
              style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedReason,
              items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => selectedReason = val ?? selectedReason,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      _cancelOrder(order.id!, selectedReason);
    }
  }

  Future<void> _showReturnReplaceDialog(Order order, bool isReturn) async {
    final title = isReturn ? 'Request Return' : 'Request Replacement';
    final List<String> reasons = [
      'Defective/Damaged product',
      'Incorrect item received',
      'Quality not as expected',
      'Expired product',
      'Other',
    ];
    String selectedReason = reasons[0];
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for your ${isReturn ? 'return' : 'replacement'} request.',
                style: GoogleFonts.beVietnamPro(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason:',
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: order.returnReason,
                isExpanded: true,
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => selectedReason = val ?? selectedReason,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Additional details (optional):',
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue...',
                  hintStyle: GoogleFonts.beVietnamPro(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isReturn ? AppTheme.primary : Colors.blue, 
              foregroundColor: Colors.white
            ),
            child: Text('Submit Request'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      _submitRequest(order, isReturn, selectedReason, noteController.text.trim());
    }
  }

  Widget _buildStatusBadge(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: order.statusColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: order.statusColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        order.statusLabel.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _submitRequest(Order order, bool isReturn, String reason, String notes) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    try {
      if (isReturn) {
        await OrderService.requestReturn(order.id!, reason, notes: notes);
      } else {
        await OrderService.requestReplacement(order.id!, reason, notes: notes);
      }
      
      if (mounted) {
        ref.invalidate(orderDetailsProvider(order.id!));
        ref.invalidate(userOrdersProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isReturn ? 'Return' : 'Replacement'} request submitted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelOrder(int orderId, String reason) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      debugPrint('OrderTrackingScreen: Initiating cancellation for order $orderId');
      await OrderService.cancelOrder(orderId, reason);
      
      if (mounted) {
        debugPrint('OrderTrackingScreen: Cancellation successful');
        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(userOrdersProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('OrderTrackingScreen: Cancellation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        // Use externalApplication to ensure it opens in the actual Maps app on Android
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch map URL: $e');
      // Fallback to default launch
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
