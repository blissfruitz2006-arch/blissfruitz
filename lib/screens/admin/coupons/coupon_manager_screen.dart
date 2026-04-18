import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/coupon.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/admin/admin_dialogs.dart';

class CouponManagerScreen extends ConsumerWidget {
  const CouponManagerScreen({super.key});

  void _showCouponForm(BuildContext context, WidgetRef ref, [Coupon? coupon]) {
    showDialog(
      context: context,
      builder: (context) => CouponFormDialog(coupon: coupon, onSaved: () => ref.invalidate(adminCouponsProvider)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(adminCouponsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Coupons', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCouponForm(context, ref),
          ),
        ],
      ),
      body: couponsAsync.when(
        data: (coupons) {
          if (coupons.isEmpty) return const Center(child: Text('No coupons found'));
          return ListView.builder(
            itemCount: coupons.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                elevation: 0,
                color: AppTheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${coupon.discountValue} ${coupon.discountType == 'percent' ? '%' : 'flat'} • Min: ₹${coupon.minOrder}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showCouponForm(context, ref, coupon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Coupon?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await AdminService.deleteCoupon(coupon.id);
                            ref.invalidate(adminCouponsProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponForm(context, ref),
        label: const Text('Add Coupon'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
