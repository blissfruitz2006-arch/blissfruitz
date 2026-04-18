import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/delivery_provider.dart';
import '../../../models/order.dart';
import '../../../models/rider.dart';
import '../../../widgets/glass_card.dart';

class AssignRiderScreen extends ConsumerStatefulWidget {
  final int orderId;

  const AssignRiderScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AssignRiderScreen> createState() => _AssignRiderScreenState();
}

class _AssignRiderScreenState extends ConsumerState<AssignRiderScreen> {
  String? _selectedZone;
  String? _selectedRiderId;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final order = ordersAsync.when(
      data: (list) {
        try {
          return list.firstWhere((o) => o.id == widget.orderId);
        } catch (_) {
          return null;
        }
      },
      loading: () => null,
      error: (_, _) => null,
    );

    // Get available riders for the selected zone
    final ridersAsync = ref.watch(availableRidersProvider(_selectedZone ?? order?.shippingCity ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assign Rider',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOrderSummary(order),
                const Divider(),
                _buildRiderFilters(order),
                Expanded(
                  child: _buildRiderList(ridersAsync),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomAction(order!),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber?.toUpperCase()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, order.shippingName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, order.shippingAddress ?? 'No Address'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.shopping_basket_outlined, '${order.items.length} items'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderFilters(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Available Riders',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Builder(
            builder: (context) {
              final city = order.shippingCity ?? 'Mumbai North';
              final zones = ['Mumbai North', 'Mumbai South', 'Thane', 'Navi Mumbai', 'Pune'];
              
              // Find the best match for the current value
              String? dropdownValue;
              if (_selectedZone != null && zones.contains(_selectedZone)) {
                dropdownValue = _selectedZone;
              } else {
                // Try to match the city (case-insensitive)
                dropdownValue = zones.firstWhere(
                  (z) => z.toLowerCase() == city.toLowerCase(),
                  orElse: () => zones.first,
                );
              }

              return DropdownButton<String>(
                value: dropdownValue,
                hint: const Text('Zone'),
                underline: const SizedBox(),
                items: zones
                    .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedZone = val;
                    _selectedRiderId = null;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiderList(AsyncValue<List<Rider>> ridersAsync) {
    return ridersAsync.when(
      data: (riders) {
        if (riders.isEmpty) {
          return Center(
            child: Text(
              'No available riders in this zone',
              style: GoogleFonts.beVietnamPro(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: riders.length,
          itemBuilder: (context, index) {
            final rider = riders[index];
            final isSelected = _selectedRiderId == rider.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRiderId = rider.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppTheme.primary.withValues(alpha: 0.05) 
                    : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                      ? AppTheme.primary 
                      : Colors.grey.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        rider.fullName.isNotEmpty ? rider.fullName.substring(0, 1).toUpperCase() : 'R',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rider.fullName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${rider.vehicleType ?? 'Bike'} • ${rider.zone ?? 'Central'}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBottomAction(Order order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_selectedRiderId == null || _isAssigning) 
          ? null 
          : () => _handleAssignment(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isAssigning
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'ASSIGN RIDER',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Future<void> _handleAssignment() async {
    setState(() => _isAssigning = true);
    try {
      final service = ref.read(deliveryServiceProvider);
      await service.assignRider(widget.orderId, _selectedRiderId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }
}
