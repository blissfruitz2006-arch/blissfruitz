import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../models/order.dart';
import '../../../services/admin_service.dart';
import '../../../services/order_service.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/invoice_service.dart';
import '../../../providers/order_provider.dart';
import '../components/admin_common_widgets.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isProcessing = false;
  final _trackingController = TextEditingController();
  final _locationController = TextEditingController();
  final _adminNotesController = TextEditingController();
  bool _initialized = false;
  
  Map<String, dynamic>? _deliveryInfo;
  bool _isLoadingDelivery = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryInfo();
  }

  Future<void> _loadDeliveryInfo() async {
    final orderId = int.tryParse(widget.orderId);
    if (orderId == null) {
      if (mounted) setState(() => _isLoadingDelivery = false);
      return;
    }
    
    try {
      final info = await OrderService.getDeliveryInfo(orderId);
      if (mounted) {
        setState(() {
          _deliveryInfo = info;
          _isLoadingDelivery = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDelivery = false);
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _locationController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  void _initFields(Order order) {
    if (!_initialized) {
      _trackingController.text = order.trackingNumber ?? '';
      _locationController.text = order.locationLink ?? '';
      _adminNotesController.text = order.adminNotes ?? '';
      _initialized = true;
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    setState(() => _isProcessing = true);
    try {
      await AdminService.updateOrderStatus(orderId, status);
      if (mounted) {
        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(adminOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processRefund(Order order) async {
    final refundIdController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount to Refund: ₹${order.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Enter the Refund ID from your payment gateway (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: refundIdController,
              decoration: const InputDecoration(
                hintText: 'e.g. rfnd_123456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Mark Refunded'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await AdminService.processRefund(order.id!, refundIdController.text.trim().isEmpty ? null : refundIdController.text.trim());
        if (mounted) {
          ref.invalidate(orderDetailsProvider(order.id!));
          ref.invalidate(adminOrdersProvider);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund processed successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updatePaymentStatus(int orderId, String status) async {
    setState(() => _isProcessing = true);
    try {
      await AdminService.updateOrderPaymentStatus(orderId, status);
      if (mounted) {
        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(adminOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment status updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateTracking(int orderId) async {
    setState(() => _isProcessing = true);
    try {
      await AdminService.updateOrderTracking(
        orderId,
        _trackingController.text.trim(),
        _locationController.text.trim(),
      );
      if (mounted) {
        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(adminOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracking info updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRequestResponse(int orderId, String status) async {
    final isApproved = status.contains('approved');
    final action = isApproved ? 'Approve' : 'Reject';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request?'),
        content: Text('Are you sure you want to $action this ${status.contains('return') ? 'return' : 'replacement'} request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, $action'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await AdminService.updateOrderRequestStatus(
        orderId,
        status,
        _adminNotesController.text.trim(),
      );
      if (mounted) {
        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(adminOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request updated to $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = int.tryParse(widget.orderId) ?? 0;
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: orderAsync.when(
          data: (order) => LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Flexible(
                    child: Text(
                      'Order #${order?.orderNumber ?? widget.orderId}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: constraints.maxWidth < 400 ? 18 : 22,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order != null) ...[
                    const SizedBox(width: 12),
                    StatusBadge(
                      label: order.statusLabel,
                      color: order.statusColor,
                      icon: order.statusIcon,
                    ),
                  ],
                ],
              );
            },
          ),
          loading: () => const Text('Loading...'),
          error: (error, _) => const Text('Order Details'),
        ),
        actions: [
          orderAsync.when(
            data: (order) => order != null 
              ? Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.createdAt != null 
                          ? 'Placed ${order.createdAt!.day} ${_getMonth(order.createdAt!.month)} ${order.createdAt!.year}'
                          : '',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13, 
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),
        ],
      ),
      body: orderAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          _initFields(order);

          final screenWidth = MediaQuery.of(context).size.width;
          final horizontalPadding = screenWidth < 600 ? 12.0 : 24.0;
          final cardPadding = screenWidth < 600 ? 16.0 : 24.0;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 950;
                        
                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Order Info & Items
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AdminGlassCard(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(title: 'Order Items'),
                                          _buildItemsList(order),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (order.orderStatus.contains('returned') || 
                                        order.orderStatus.contains('return') || 
                                        order.orderStatus.contains('replace') || 
                                        order.orderStatus.contains('replacement')) ...[
                                      AdminGlassCard(
                                        padding: EdgeInsets.all(cardPadding),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SectionHeader(title: 'Return / Replacement Info'),
                                            _buildReturnReplacementDetails(order),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    AdminGlassCard(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(title: 'Payment Details'),
                                          _buildPaymentInfo(order),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right Column: Shipping & Actions
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AdminGlassCard(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(title: 'Customer Details'),
                                          _buildShippingInfo(order),
                                          Padding(
                                            padding: EdgeInsets.symmetric(vertical: cardPadding),
                                            child: const Divider(height: 1),
                                          ),
                                          _buildCustomerStats(order.userId),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AdminGlassCard(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(title: 'Documents'),
                                          _buildDocuments(order),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AdminGlassCard(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(title: 'Fulfillment Actions'),
                                          _buildActions(order),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AdminGlassCard(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(title: 'Delivery & Rider'),
                                          _buildDeliveryAndRider(order),
                                        ],
                                      ),
                                    ),
                                    if (order.orderStatus == 'delivered' && order.deliveredAt != null) ...[
                                      const SizedBox(height: 24),
                                      _buildReturnWindowCard(order),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminGlassCard(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Customer Details'),
                                    _buildShippingInfo(order),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: cardPadding),
                                      child: const Divider(height: 1),
                                    ),
                                    _buildCustomerStats(order.userId),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              AdminGlassCard(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Order Items'),
                                    _buildItemsList(order),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (order.orderStatus.contains('returned') || 
                                  order.orderStatus.contains('return') || 
                                  order.orderStatus.contains('replace') || 
                                  order.orderStatus.contains('replacement')) ...[
                                AdminGlassCard(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SectionHeader(title: 'Return / Replacement Info'),
                                      _buildReturnReplacementDetails(order),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              AdminGlassCard(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Payment Details'),
                                    _buildPaymentInfo(order),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              AdminGlassCard(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Documents'),
                                    _buildDocuments(order),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              AdminGlassCard(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Fulfillment Actions'),
                                    _buildActions(order),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              AdminGlassCard(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Delivery & Rider'),
                                    _buildDeliveryAndRider(order),
                                  ],
                                ),
                              ),
                              if (order.orderStatus == 'delivered' && order.deliveredAt != null) ...[
                                const SizedBox(height: 24),
                                _buildReturnWindowCard(order),
                              ],
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildItemsList(Order order) {
    return Column(
      children: [
        ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.quantity.toString(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Unit Price: ₹${item.price}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12, 
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹${item.totalPrice}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(height: 1),
        ),
        _buildSummaryRow('Subtotal', '₹${order.subtotal}'),
        _buildSummaryRow('Shipping Fee', '₹${order.shippingAmount}'),
        if (order.discountAmount > 0) 
          _buildSummaryRow('Discount Applied', '-₹${order.discountAmount}', color: const Color(0xFF10B981)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(height: 1),
        ),
        _buildSummaryRow('Total Payable', '₹${order.total}', isBold: true, fontSize: 20),
      ],
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppTheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem('Customer', order.shippingName ?? 'Unknown'),
        _buildInfoItem('Phone', order.shippingPhone ?? 'N/A'),
        _buildInfoItem('Email', order.guestEmail ?? 'N/A'),
        const SizedBox(height: 12),
        Text(
          'Address',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.outline),
        ),
        const SizedBox(height: 4),
        Text(
          '${order.shippingAddress}, ${order.shippingCity}, ${order.shippingState} - ${order.shippingPincode}',
          style: GoogleFonts.beVietnamPro(fontSize: 14),
        ),
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoItem('Notes', order.notes!),
        ],
      ],
    );
  }

  Widget _buildPaymentInfo(Order order) {
    return Column(
      children: [
        _buildInfoItem('Method', order.paymentMethod?.toUpperCase() ?? 'COD'),
        _buildInfoItem(
          'Status', 
          order.paymentLabel,
          valueColor: order.paymentStatus == 'failed' ? Colors.redAccent : null,
        ),
        if (order.razorpayPaymentId != null) _buildInfoItem('Payment ID', order.razorpayPaymentId!),
        if (order.refundId != null) _buildInfoItem('Refund ID', order.refundId!),
        const SizedBox(height: 16),
        if (order.paymentStatus == 'refund_pending' || order.orderStatus == 'cancelled' && order.paymentStatus == 'paid')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processRefund(order),
              icon: const Icon(Icons.replay_outlined),
              label: const Text('Mark as Refunded'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (order.paymentStatus != 'refunded')
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updatePaymentStatus(order.id!, 'paid'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Mark Paid'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updatePaymentStatus(order.id!, 'pending'),
                  child: const Text('Mark Pending'),
                ),
              ),
            ],
          ),
      ],
    );
  }


  Widget _buildDocuments(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invoice', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.outline)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => InvoiceService.printInvoice(order),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => InvoiceService.downloadInvoice(order),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Shipping Sticker', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.outline)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => InvoiceService.printShippingLabel(order),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => InvoiceService.downloadShippingLabel(order),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryAndRider(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingDelivery)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else if (_deliveryInfo != null) ...[
          _buildInfoItem('Rider Name', _deliveryInfo!['rider_name'] ?? 'Unknown', valueColor: AppTheme.primary),
          _buildInfoItem('Phone', _deliveryInfo!['rider_phone'] ?? 'N/A'),
          if (_deliveryInfo!['status'] != null)
            _buildInfoItem('Delivery Status', _deliveryInfo!['status'].toString().toUpperCase()),
          if (_deliveryInfo!['proof_image_url'] != null && _deliveryInfo!['proof_image_url'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 16, color: AppTheme.outline),
                const SizedBox(width: 8),
                Text('Delivery Proof', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.outline)),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // Show full image dialog
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            AdminService.getPublicUrl(_deliveryInfo!['proof_image_url']),
                            fit: BoxFit.contain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.network(
                    AdminService.getPublicUrl(_deliveryInfo!['proof_image_url']),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: AppTheme.surfaceContainerLow,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey.shade100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                            const SizedBox(height: 12),
                            Text('Image failed to load', style: GoogleFonts.beVietnamPro(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No rider has been assigned to this order yet.',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/admin/riders/assign/${order.id}'),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(
              _deliveryInfo != null || order.riderId != null ? 'CHANGE RIDER' : 'ASSIGN RIDER',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primary),
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Order order) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: order.orderStatus,
          decoration: InputDecoration(
            labelText: 'Update Order Status',
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
            DropdownMenuItem(value: 'processing', child: Text('Processing')),
            DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
            DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery')),
            DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            DropdownMenuItem(value: 'failed', child: Text('Failed')),
            DropdownMenuItem(value: 'return_requested', child: Text('Return Requested')),
            DropdownMenuItem(value: 'return_approved', child: Text('Return Approved')),
            DropdownMenuItem(value: 'return_rejected', child: Text('Return Rejected')),
            DropdownMenuItem(value: 'returned', child: Text('Returned')),
            DropdownMenuItem(value: 'replacement_requested', child: Text('Replacement Requested')),
            DropdownMenuItem(value: 'replacement_approved', child: Text('Replacement Approved')),
            DropdownMenuItem(value: 'replacement_rejected', child: Text('Replacement Rejected')),
            DropdownMenuItem(value: 'replaced', child: Text('Replaced')),
          ],
          onChanged: (val) {
            if (val != null && val != order.orderStatus) {
              _updateStatus(order.id!, val);
            }
          },
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _adminNotesController,
          maxLines: 3,
          style: GoogleFonts.beVietnamPro(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Internal Notes / Customer Feedback', 
            hintText: 'Provide reason for approval/rejection...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        if (order.orderStatus == 'return_requested' || order.orderStatus == 'replacement_requested') ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleRequestResponse(order.id!, order.orderStatus.contains('return') ? 'return_approved' : 'replacement_approved'),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('APPROVE'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleRequestResponse(order.id!, order.orderStatus.contains('return') ? 'return_rejected' : 'replacement_rejected'),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('REJECT'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(height: 1),
        ),
        TextField(
          controller: _trackingController,
          style: GoogleFonts.beVietnamPro(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Tracking Number',
            hintText: 'Enter courier tracking ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _locationController,
          style: GoogleFonts.beVietnamPro(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Live Tracking / Map Link',
            hintText: 'https://...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateTracking(order.id!),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SAVE FULFILLMENT INFO'),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnReplacementDetails(Order order) {
    bool isReturn = order.orderStatus.contains('return') || order.returnReason != null;
    String? reason = isReturn ? order.returnReason : order.replacementReason;
    String? notes = isReturn ? order.returnNotes : order.replacementNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem('Type', isReturn ? 'RETURN' : 'REPLACEMENT'),
        if (reason != null) _buildInfoItem('Reason', reason),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Customer Notes:',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.outline),
          ),
          const SizedBox(height: 4),
          Text(
            notes,
            style: GoogleFonts.beVietnamPro(fontSize: 14),
          ),
        ],
      ],
    );
  }


  Widget _buildCustomerStats(String? userId) {
    if (userId == null) return const SizedBox.shrink();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminService.getUserStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        
        final stats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Activity',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.outline),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatItem('Total Orders', stats['orderCount'].toString())),
                Expanded(child: _buildStatItem('Total Spent', '₹${(stats['totalSpent'] as double).toStringAsFixed(0)}')),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.outline)),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }


  Widget _buildReturnWindowCard(Order order) {
    final window = order.returnWindowRemaining;
    final isClosed = window == 'Window Closed';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClosed 
            ? [Colors.grey.shade50, Colors.grey.shade100]
            : [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isClosed ? Colors.grey.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isClosed ? Colors.grey.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClosed ? Icons.lock_clock_outlined : Icons.history_rounded,
              color: isClosed ? Colors.grey : Colors.orange.shade800,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Return/Replacement Window',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isClosed ? 'This order is no longer eligible for returns.' : 'Customer can request return/replacement within this time.',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isClosed ? Colors.grey.shade200 : Colors.orange.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                window,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isClosed ? Colors.grey.shade600 : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.outline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                fontSize: 14, 
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
