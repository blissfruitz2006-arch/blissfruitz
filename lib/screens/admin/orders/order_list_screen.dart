import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';
import '../../../services/invoice_service.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const OrderListScreen({super.key, this.initialFilter});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  bool _showFailedOnly = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'failed') {
      _showFailedOnly = true;
    }
  }

  @override
  void didUpdateWidget(OrderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter && widget.initialFilter == 'failed') {
      setState(() => _showFailedOnly = true);
    } else if (widget.initialFilter != oldWidget.initialFilter && widget.initialFilter == null) {
      setState(() => _showFailedOnly = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Manage Orders',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by Order # or Customer Name',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilterChip(
              label: const Text('Failed Only', style: TextStyle(fontSize: 12)),
              selected: _showFailedOnly,
              onSelected: (val) => setState(() => _showFailedOnly = val),
              selectedColor: Colors.redAccent.withValues(alpha: 0.2),
              checkmarkColor: Colors.redAccent,
              labelStyle: TextStyle(
                color: _showFailedOnly ? Colors.redAccent : null,
                fontWeight: _showFailedOnly ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (allOrders) {
          final filteredBySearch = allOrders.where((o) {
            final orderNum = (o.orderNumber ?? o.id.toString()).toLowerCase();
            final name = (o.shippingName ?? '').toLowerCase();
            return orderNum.contains(_searchQuery) || name.contains(_searchQuery);
          }).toList();

          final orders = _showFailedOnly 
              ? filteredBySearch.where((o) => o.paymentStatus == 'failed').toList() 
              : filteredBySearch;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showFailedOnly ? Icons.check_circle_outline : Icons.shopping_bag_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showFailedOnly ? 'No failed orders found' : 'No orders found',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final hasNotes = order.adminNotes != null && order.adminNotes!.isNotEmpty;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        'Order #${order.orderNumber ?? order.id}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      if (hasNotes) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.note_alt_outlined, size: 14, color: Colors.blueAccent),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${order.shippingName ?? 'Guest'} • ₹${order.total}\n${order.createdAt != null ? DateFormat.yMMMd().format(order.createdAt!) : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'return_requested', 'return_approved', 'return_rejected', 'returned', 'replacement_requested', 'replacement_approved', 'replacement_rejected', 'replaced'].contains(order.orderStatus)
                            ? order.orderStatus
                            : 'pending',
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(order.orderStatus, order.paymentStatus)),
                        style: TextStyle(
                          color: _getStatusColor(order.orderStatus, order.paymentStatus),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                          DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                          DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                          DropdownMenuItem(value: 'return_requested', child: Text('Return Requested')),
                          DropdownMenuItem(value: 'return_approved', child: Text('Return Approved')),
                          DropdownMenuItem(value: 'return_rejected', child: Text('Return Rejected')),
                          DropdownMenuItem(value: 'returned', child: Text('Returned')),
                          DropdownMenuItem(value: 'replacement_requested', child: Text('Replacement Requested')),
                          DropdownMenuItem(value: 'replacement_approved', child: Text('Replacement Approved')),
                          DropdownMenuItem(value: 'replacement_rejected', child: Text('Replacement Rejected')),
                          DropdownMenuItem(value: 'replaced', child: Text('Replaced')),
                        ],
                        onChanged: (val) async {
                          if (val != null && order.id != null) {
                            try {
                              await AdminService.updateOrderStatus(order.id!, val);
                              ref.invalidate(adminOrdersProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'invoice_print') InvoiceService.printInvoice(order);
                          if (val == 'sticker_print') InvoiceService.printShippingLabel(order);
                          if (val == 'invoice_download') InvoiceService.downloadInvoice(order);
                          if (val == 'sticker_download') InvoiceService.downloadShippingLabel(order);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'invoice_print',
                            child: Row(
                              children: [
                                Icon(Icons.print_outlined, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                const Text('Print Invoice'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'invoice_download',
                            child: Row(
                              children: [
                                Icon(Icons.download_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                const Text('Download Invoice'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'sticker_print',
                            child: Row(
                              children: [
                                Icon(Icons.print_outlined, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                const Text('Print Sticker'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'sticker_download',
                            child: Row(
                              children: [
                                Icon(Icons.file_download_outlined, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                const Text('Download Sticker'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/admin/orders/${order.id}', extra: order);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getStatusColor(String status, String paymentStatus) {
    if (paymentStatus == 'failed') return Colors.redAccent;
    
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'return_requested':
      case 'replacement_requested':
        return Colors.purple;
      case 'return_approved':
      case 'replacement_approved':
        return Colors.green;
      case 'return_rejected':
      case 'replacement_rejected':
        return Colors.red;
      case 'returned':
      case 'replaced':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
