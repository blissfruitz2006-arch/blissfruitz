import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/app_image.dart';
import '../../services/coupon_service.dart';


class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _isValidatingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    try {
      final cart = ref.read(cartProvider);
      
      final user = ref.read(userProfileProvider).valueOrNull;
      final coupon = await CouponService.validateCoupon(
        code, 
        userId: user?.supabaseId,
      );

      if (coupon == null) {
        throw Exception('Invalid or expired coupon code');
      }

      if (coupon.minOrder != null && cart.subtotal < coupon.minOrder!) {
        throw Exception('Minimum order amount for this coupon is ₹${coupon.minOrder}');
      }

      final discount = coupon.calculateDiscount(cart.subtotal);
      ref.read(cartProvider.notifier).applyCoupon(coupon.code, discount);
      _couponController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon applied! You saved ₹$discount')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')), 
            backgroundColor: AppTheme.error
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    if (cart.items.isEmpty) {
      return Title(
        title: 'Empty Basket | Blissfruitz',
        color: AppTheme.primary,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Your Basket',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 72,
                      color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your basket is empty',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some fresh fruits to get started!',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => context.go('/shop'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Browse Products',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onPrimary,
                          ),
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
    }

    final cartList = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: AppImage(path: item.product.imageMain, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${item.product.price.toStringAsFixed(0)} / ${item.product.unit}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.surfaceContainer),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.remove, size: 16, color: AppTheme.primary),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(cartProvider.notifier).incrementQuantity(item.product.id),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.add, size: 16, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    final cartSummary = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: isWide ? BorderRadius.circular(16) : null,
        border: isWide
            ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
            : Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _summaryRow(
            'Shipping',
            cart.shippingAmount == 0 ? 'FREE' : '₹${cart.shippingAmount.toStringAsFixed(0)}',
            valueColor: cart.shippingAmount == 0 ? AppTheme.primary : null,
          ),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Discount',
              '-₹${cart.discountAmount.toStringAsFixed(0)}',
              valueColor: AppTheme.primary,
            ),
          ],
          
          // Coupon Section
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          if (cart.couponCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon "${cart.couponCode}" applied!',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(cartProvider.notifier).removeCoupon(),
                    child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Coupon Code',
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLowest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidatingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isValidatingCoupon
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply'),
                ),
              ],
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(height: 1, color: AppTheme.surfaceContainer),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '₹${cart.total.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.push('/checkout'),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Checkout',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: AppTheme.onPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Title(
      title: 'Shopping Basket | Blissfruitz',
      color: AppTheme.primary,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    'My Cart',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                    tooltip: 'Clear Cart',
                  ),
                ],
              ),
            ),
            if (isWide)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: cartList,
                          ),
                        ),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: 380,
                          child: cartSummary,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  cartList,
                  cartSummary,
                  const SizedBox(height: 100),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

