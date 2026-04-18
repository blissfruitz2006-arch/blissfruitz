import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';
import '../../widgets/app_image.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';
import '../../widgets/address_form_modal.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/settings_service.dart';
import '../../services/coupon_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/razorpay_checkout.dart' as rzp;
import '../../models/settings.dart';
import '../../services/logger_service.dart';


class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 1; // 0=Cart, 1=Details, 2=Confirm
  Address? _selectedAddress;
  String? _guestEmail;
  String _selectedPayment = 'cod';
  bool _loading = false;
  bool _fetchingAddresses = true;
  List<Address> _savedAddresses = [];
  int? _pendingOrderId;
  
  // Settings

  PaymentSettings _paymentSettings = PaymentSettings();
  ShippingSettings _shippingSettings = const ShippingSettings();

  Razorpay? _razorpay;
  final TextEditingController _couponController = TextEditingController();
  bool _validatingCoupon = false;
  String? _couponError;


  @override
  void initState() {
    super.initState();
    _loadAddresses();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAddresses(),
      _loadSettings(),
    ]);
  }

  Future<void> _loadSettings() async {
    try {
      final payment = await SettingsService.getPaymentSettings();
      final shipping = await SettingsService.getShippingSettings();
      setState(() {
        _paymentSettings = payment;
        _shippingSettings = shipping;

        _selectedPayment = payment.codEnabled ? 'cod' : 'card';
      });
      
      // Update cart shipping if already in cart
      _updateCartShipping();
    } catch (e) {
      LoggerService.logError('CheckoutScreen._loadSettings error: $e');
    }
  }

  void _updateCartShipping() {
    final cart = ref.read(cartProvider);
    final shipping = _shippingSettings.calculateShipping(cart.subtotal);
    ref.read(cartProvider.notifier).updateShipping(shipping);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user != null) {
      try {
        final addresses = await AddressService.getUserAddresses(user.id);
        setState(() {
          _savedAddresses = addresses;
          _selectedAddress = addresses.isNotEmpty 
            ? (addresses.any((a) => a.isDefault) 
                ? addresses.firstWhere((a) => a.isDefault) 
                : addresses.first)
            : null;
          _fetchingAddresses = false;
        });
      } catch (e) {
        setState(() => _fetchingAddresses = false);
      }
    } else {
      setState(() => _fetchingAddresses = false);
    }
  }

  void _showAddAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormModal(
        onSave: (address, email) {
          if (ref.read(userProfileProvider).valueOrNull == null) {
            setState(() {
              _selectedAddress = address;
              _guestEmail = email;
              _savedAddresses = [address]; // Show it in list
            });
          } else {
            _loadAddresses();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingOrderId;
    if (orderId != null) {
      await OrderService.updatePaymentStatus(
        orderId: orderId,
        paymentStatus: 'paid',
        orderStatus: 'confirmed', // Or 'placed', let's use 'confirmed' as per Order model switch
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
      );
      
      _pendingOrderId = null;
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        setState(() => _loading = false);
        context.go('/order-success?orderId=$orderId');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    final orderId = _pendingOrderId;
    LoggerService.logInfo('Payment failed for order: $orderId. Error: ${response.message}');
    
    if (orderId != null) {
      try {
        await OrderService.updatePaymentStatus(
          orderId: orderId,
          paymentStatus: 'failed',
          orderStatus: 'failed',
        );
        LoggerService.logInfo('Successfully updated order $orderId status to failed');
      } catch (e) {
        LoggerService.logError('Error updating failed payment status for order $orderId: $e');
      }
    } else {
      LoggerService.logWarning('Payment failed but _pendingOrderId was null. Status not updated.');
    }
    
    if (mounted) {
      setState(() => _loading = false);
      context.push('/order-failed?error=${Uri.encodeComponent(response.message ?? "Payment cancelled")}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _validatingCoupon = true;
      _couponError = null;
    });

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final coupon = await CouponService.validateCoupon(
        code, 
        userId: profile?.id,
        guestEmail: profile?.email ?? _guestEmail,
        phone: _selectedAddress?.phone,
      );
      
      if (coupon == null) {
        setState(() {
          _validatingCoupon = false;
          _couponError = 'Invalid or expired coupon code';
        });
        return;
      }

      int orderCount = 0;
      if (profile != null) {
        orderCount = await OrderService.getUserOrderCount(profile.id);
      }

      final ineligibilityReason = coupon.getIneligibilityReason(profile, orderCount);
      if (ineligibilityReason != null) {
        setState(() {
          _validatingCoupon = false;
          _couponError = ineligibilityReason;
        });
        return;
      }

      final cart = ref.read(cartProvider);
      
      if (coupon.minOrder != null && cart.subtotal < coupon.minOrder!) {
        setState(() {
          _validatingCoupon = false;
          _couponError = 'Minimum order amount ₹${coupon.minOrder!.toStringAsFixed(0)} required';
        });
        return;
      }

      // Use the model's calculation logic for consistency
      final discount = coupon.calculateDiscount(cart.subtotal);
      
      if (discount <= 0) {
        setState(() {
          _validatingCoupon = false;
          _couponError = 'Coupon provides no discount for this order';
        });
        return;
      }

      ref.read(cartProvider.notifier).applyCoupon(coupon.code, discount);

      setState(() {
        _validatingCoupon = false;
        _couponController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon "${coupon.code}" applied successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _validatingCoupon = false;
        _couponError = e.toString().contains('already used') 
            ? 'You have already used this coupon code' 
            : 'Error validating coupon';
      });
    }
  }

  void _removeCoupon() {
    ref.read(cartProvider.notifier).removeCoupon();
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a shipping address')),
      );
      return;
    }

    final cart = ref.read(cartProvider);
    final user = ref.read(userProfileProvider).valueOrNull;

    if (cart.items.isEmpty) return;

    setState(() => _loading = true);

    try {
      final subtotal = cart.subtotal;
      final discount = cart.discountAmount;
      final shipping = _shippingSettings.calculateShipping(subtotal);
      final total = subtotal - discount + shipping;

      // 1. Create the order in "pending" state first
      final order = await OrderService.createOrder(
        userId: user?.id,
        guestEmail: user == null ? (_guestEmail ?? 'guest@example.com') : null,
        shippingName: _selectedAddress!.fullName,
        shippingPhone: _selectedAddress!.phone,
        shippingAddress: _selectedAddress!.line1,
        shippingCity: _selectedAddress!.city,
        shippingState: _selectedAddress!.state,
        shippingPincode: _selectedAddress!.pincode,
        subtotal: subtotal,
        shippingAmount: shipping,
        discountAmount: discount,
        total: total,
        couponCode: cart.couponCode,
        paymentMethod: _selectedPayment,
        items: cart.items,
        latitude: _selectedAddress!.latitude,
        longitude: _selectedAddress!.longitude,
      );

      _pendingOrderId = order.id;

      // 2. Handle payment based on method
      if (_selectedPayment == 'cod') {
        // COD - Update status and clear cart
        try {
          await OrderService.updatePaymentStatus(
            orderId: order.id!,
            paymentStatus: 'pending',
            orderStatus: 'confirmed',
          );
        } catch (e) {
          LoggerService.logError('Error updating COD status: $e');
        }

        ref.read(cartProvider.notifier).clearCart();
        if (mounted) {
          context.go('/order-success?orderId=${order.id}');
        }
      } else {
        // Online payment - Trigger Razorpay
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Securely connecting to payment gateway...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (!_paymentSettings.razorpayEnabled || _paymentSettings.razorpayKeyId == null || _paymentSettings.razorpayKeyId!.isEmpty) {
          throw Exception('Online payments are currently unavailable. Please use COD.');
        }

        final options = {
          'key': _paymentSettings.razorpayKeyId,
          'amount': (total * 100).toInt(),
          'currency': _paymentSettings.currency,
          'name': 'BlissFruitz',
          'description': 'Order #${order.orderNumber}',
          'retry': {'enabled': true, 'max_count': 1},
          'send_sms_hash': true,
          'prefill': {
            'contact': _selectedAddress!.phone,
            'email': user?.email ?? 'customer@example.com'
          },
          'theme': {
            'color': '#16a34a'
          },
          'external': {
            'wallets': ['paytm']
          }
        };

        try {
          if (kIsWeb) {
            rzp.openRazorpayCheckout(
              key: _paymentSettings.razorpayKeyId!,
              amount: (total * 100).toInt(),
              currency: _paymentSettings.currency,
              name: 'BlissFruitz',
              description: 'Order #${order.orderNumber}',
              contact: _selectedAddress!.phone,
              email: user?.email ?? 'customer@example.com',
              onSuccess: (paymentId, rOrderId, signature) {
                _handlePaymentSuccess(PaymentSuccessResponse(paymentId, rOrderId, signature, {}));
              },
              onFailure: (code, message) {
                _handlePaymentError(PaymentFailureResponse(code, message, {}));
              },
            );
          } else {
            // Re-initialize before opening to ensure fresh state
            _razorpay?.clear();
            _razorpay = Razorpay();
            _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
            _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
            _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
            
            _razorpay!.open(options);
          }
          
          // Fail-safe: if no event is received within 60 seconds, reset loading
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted && _loading) {
              setState(() => _loading = false);
            }
          });
        } catch (e) {
          debugPrint('Error opening Razorpay: $e');
          throw Exception('Could not open payment gateway: $e');
        }
      }
    } catch (e) {
      LoggerService.logError('Exception during _placeOrder: $e');
      final orderId = _pendingOrderId;
      if (orderId != null) {
        try {
          // If we have an order ID but hit an error (e.g. before Razorpay opened),
          // set it to failed to prevent "stuck" pending orders
          await OrderService.updatePaymentStatus(
            orderId: orderId,
            paymentStatus: 'failed',
            orderStatus: 'failed',
          );
          LoggerService.logInfo('Successfully updated order $orderId status to failed after exception');
        } catch (updateErr) {
          LoggerService.logError('Failed to mark order $orderId as failed: $updateErr');
        }
      }

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        } else {
          // Use pop if possible, otherwise go to cart
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/cart');
          }
        }
      },
      child: Title(
        title: 'Checkout | BlissFruitz',
        color: Colors.white,
        child: Stack(
          children: [
            SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_currentStep > 0) {
                                setState(() => _currentStep--);
                              } else {
                                // Prefer pop if we have a stack, otherwise fallback to cart
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/cart');
                                }
                              }
                            },
                            child: Icon(Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Checkout',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStepIndicator(),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep == 0) ...[
                          _buildBasketSection(cart),
                          const SizedBox(height: 24),
                          _buildCouponSection(cart),
                          const SizedBox(height: 24),
                          _buildBillingSummary(cart),
                        ] else if (_currentStep == 1) ...[
                          _buildShippingSection(),
                        ] else if (_currentStep == 2) ...[
                          _buildPaymentSection(),
                          const SizedBox(height: 24),
                          _buildCouponSection(cart),
                          const SizedBox(height: 24),
                          _buildBillingSummary(cart),
                        ],
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceContainerLowest : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Grand Total',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${cart.total.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _loading ? null : () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        _placeOrder();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 18),
                      decoration: BoxDecoration(
                        color: _loading ? Theme.of(context).colorScheme.surfaceContainerHigh : AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _loading ? null : [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _loading
                          ? [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.onPrimary,
                                ),
                              )
                            ]
                          : [
                              Text(
                                _currentStep < 2 ? 'Continue' : 'Place Order',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(_currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                                  size: 20, color: AppTheme.onPrimary),
                            ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStepIndicator() {
    final steps = ['Cart', 'Details', 'Confirm'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < _currentStep
                  ? AppTheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isActive = stepIndex <= _currentStep;
        return GestureDetector(
          onTap: () => setState(() => _currentStep = stepIndex),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppTheme.onPrimary : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[stepIndex],
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasketSection(dynamic cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Basket Items',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${cart.items.length} items',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...cart.items.map<Widget>((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: AppImage(
                      path: item.product.imageMain,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.quantity} × ₹${item.product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shipping Address',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: _showAddAddressModal,
              child: Text(
                '+ Add New',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_fetchingAddresses)
          const Center(child: CircularProgressIndicator())
        else if (_savedAddresses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.location_on_outlined, color: AppTheme.outline.withValues(alpha: 0.5), size: 40),
                const SizedBox(height: 12),
                Text(
                  'No saved addresses',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a new address to continue',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedAddresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final addr = _savedAddresses[index];
              final isSelected = _selectedAddress?.id == addr.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedAddress = addr),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.05),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? AppTheme.primary.withValues(alpha: 0.1) 
                            : Theme.of(context).dividerColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          addr.label?.toLowerCase() == 'home' ? Icons.home_rounded : 
                          addr.label?.toLowerCase() == 'office' ? Icons.business_rounded : Icons.location_on_rounded,
                          size: 20,
                          color: isSelected ? AppTheme.primary : Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.label ?? 'Other',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              addr.displayString,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 24),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'UPI Transfer',
          'Pay via PhonePe, Google Pay, Paytm',
          Icons.account_balance_wallet_outlined,
          'upi',
        ),
        const SizedBox(height: 8),
        _buildPaymentOption(
          'Cards / Netbanking',
          'Powered by Razorpay',
          Icons.credit_card_outlined,
          'card',
        ),
        const SizedBox(height: 8),
        _buildPaymentOption(
          'Cash on Delivery',
          'Pay when you receive the fruit',
          Icons.payments_outlined,
          'cod',
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
      String title, String subtitle, IconData icon, String value) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(icon, size: 24, color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(dynamic cart) {
    final hasCoupon = cart.couponCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.discount_rounded,
                size: 20, color: AppTheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Text(
              'Offers & Benefits',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasCoupon)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cart.couponCode!,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Total savings: ₹${cart.discountAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _removeCoupon,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter promo code',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(Icons.confirmation_number_outlined, 
                            color: AppTheme.primary.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _validatingCoupon ? null : _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _validatingCoupon
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_couponError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        _couponError!,
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildBillingSummary(dynamic cart) {
    final subtotal = cart.subtotal;
    final discount = cart.discountAmount;
    final shipping = cart.shippingAmount;
    final total = cart.total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Summary',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _billRow('Basket Total', '₹${subtotal.toStringAsFixed(0)}'),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _billRow('Discount', '-₹${discount.toStringAsFixed(0)}',
                valueColor: AppTheme.primary),
          ],
          const SizedBox(height: 8),
          _billRow('Shipping Fee', shipping == 0 ? 'FREE' : '₹${shipping.toStringAsFixed(0)}',
              valueColor: shipping == 0 ? AppTheme.primary : null),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
