import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../services/razorpay_checkout.dart' as razorpay;
import '../../models/address.dart';
import '../../models/cart.dart';
import '../../models/user_profile.dart';

import '../../widgets/address_form_modal.dart';
import '../../services/coupon_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  List<Address> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _emailController = TextEditingController();
  final _couponController = TextEditingController();

  String _paymentMethod = 'razorpay'; // 'razorpay' or 'cod'
  bool _isValidatingCoupon = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Fetch addresses immediately if profile is already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(userProfileProvider).valueOrNull != null) {
        _fetchSavedAddresses();
      }
    });
  }

  Future<void> _fetchSavedAddresses() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) {
      setState(() => _isLoadingAddresses = false);
      return;
    }

    debugPrint('📫 Fetching addresses for user ${profile.supabaseId}...');
    try {
      if (profile.supabaseId != null) {
        final addresses = await AddressService.getUserAddresses(profile.supabaseId!);
        debugPrint('✅ Found ${addresses.length} saved addresses.');
      if (mounted) {
        setState(() {
          _savedAddresses = addresses;
          _isLoadingAddresses = false;
        });
      }
      
      // If there's a default address, auto-fill it
      final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
      if (defaultAddr != null) {
        _fillAddress(defaultAddr);
      }
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  void _fillAddress(Address addr) {
    setState(() {
      _nameController.text = addr.fullName;
      _phoneController.text = addr.phone;
      _addressController.text = addr.line1;
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _pincodeController.text = addr.pincode;
      _latitude = addr.latitude;
      _longitude = addr.longitude;
    });
  }

  void _showAddressForm([Address? address]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormModal(
        address: address,
        onSave: (newAddr, email) {
          _fetchSavedAddresses();
          _fillAddress(newAddr);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _loadUserProfile() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
      _emailController.text = profile.email ?? '';
      _addressController.text = profile.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    _emailController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (_isProcessing) return;

    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(userProfileProvider).valueOrNull;

      if (_paymentMethod == 'razorpay') {
        // Step 1: Create order in pending state
        final order = await OrderService.createOrder(
          userId: user?.supabaseId,
          guestEmail: _emailController.text,
          shippingName: _nameController.text,
          shippingPhone: _phoneController.text,
          shippingAddress: _addressController.text,
          shippingCity: _cityController.text,
          shippingState: _stateController.text,
          shippingPincode: _pincodeController.text,
          notes: _notesController.text,
          subtotal: cart.subtotal,
          shippingAmount: cart.shippingAmount,
          discountAmount: cart.discountAmount,
          total: cart.total,
          couponCode: cart.couponCode,
          paymentMethod: 'online',
          items: cart.items,
          latitude: _latitude,
          longitude: _longitude,
        );

        if (!mounted) return;

        // Step 2: Open Razorpay
        final paymentSettingsAsync = ref.read(paymentSettingsProvider);
        final paymentSettings = paymentSettingsAsync.valueOrNull;
        final rzpKey = paymentSettings?.razorpayKeyId;
        
        if (rzpKey == null || rzpKey.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Razorpay is not configured by the administrator.')),
          );
          setState(() => _isProcessing = false);
          return;
        }

        // Step 2: Create Razorpay Order securely via Edge Function
        final rzpOrderId = await OrderService.createRazorpayOrder(
          amountInPaise: (cart.total * 100).toInt(),
          receipt: order.orderNumber ?? 'receipt_${order.id}',
        );

        if (!mounted) return;

        if (rzpOrderId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initialize payment gateway. Please try again.')),
          );
          setState(() => _isProcessing = false);
          return;
        }

        debugPrint('💳 Opening Razorpay with key: $rzpKey, orderId: $rzpOrderId');
        
        razorpay.openRazorpayCheckout(
          key: rzpKey,
          amount: (cart.total * 100).toInt(),
          orderId: rzpOrderId,
          name: 'BlissFruitz',
          description: 'Order #${order.orderNumber}',
          contact: _phoneController.text,
          email: user?.email ?? 'guest@blissfruitz.com',
          onSuccess: (paymentId, orderId, signature) async {
            // Securely verify signature on the server
            final isValid = await OrderService.verifyPaymentSignature(
              orderId: order.id!,
              razorpayPaymentId: paymentId,
              razorpayOrderId: orderId,
              razorpaySignature: signature,
            );

            if (isValid) {
              ref.read(cartProvider.notifier).clearCart();
              if (mounted) context.go('/order-success?orderId=${order.id}');
            } else {
              // Signature verification failed, mark as failed
              await OrderService.updatePaymentStatus(
                orderId: order.id!,
                paymentStatus: 'failed',
                orderStatus: 'failed',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment verification failed. Please contact support.')),
                );
                setState(() => _isProcessing = false);
              }
            }
          },
          onFailure: (code, message) async {
            debugPrint('Payment Failed: $code - $message');
            
            // Mark order as failed in database
            await OrderService.updatePaymentStatus(
              orderId: order.id!,
              paymentStatus: 'failed',
              orderStatus: 'failed',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment failed: $message')),
              );
              setState(() => _isProcessing = false);
            }
          },
        );
      } else {
        // Cash on Delivery
        final order = await OrderService.createOrder(
          userId: user?.supabaseId,
          guestEmail: _emailController.text,
          shippingName: _nameController.text,
          shippingPhone: _phoneController.text,
          shippingAddress: _addressController.text,
          shippingCity: _cityController.text,
          shippingState: _stateController.text,
          shippingPincode: _pincodeController.text,
          notes: _notesController.text,
          subtotal: cart.subtotal,
          shippingAmount: cart.shippingAmount,
          discountAmount: cart.discountAmount,
          total: cart.total,
          couponCode: cart.couponCode,
          paymentMethod: 'cod',
          items: cart.items,
          latitude: _latitude,
          longitude: _longitude,
        );

        ref.read(cartProvider.notifier).clearCart();
        if (mounted) context.go('/order-success?orderId=${order.id}');
      }
    } catch (e) {
      debugPrint('Order placement error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for profile changes to load addresses (e.g., after login)
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        debugPrint('👤 Profile updated, fetching saved addresses...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fetchSavedAddresses();
        });
      }
    });

    final cart = ref.watch(cartProvider);

    if (cart.items.isEmpty && !_isProcessing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: AppTheme.outline),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/shop'),
                child: const Text('Back to Shop'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator
            _buildStepIndicator(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Builder(
                          key: ValueKey(_currentStep),
                          builder: (context) {
                            if (_currentStep == 0) return _buildShippingStep(key: const ValueKey('shipping'));
                            if (_currentStep == 1) return _buildPaymentStep(key: const ValueKey('payment'));
                            if (_currentStep == 2) return _buildReviewStep(key: const ValueKey('review'));
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        children: [
          _StepIcon(index: 0, currentIndex: _currentStep, label: 'Shipping'),
          _StepDivider(index: 0, currentIndex: _currentStep),
          _StepIcon(index: 1, currentIndex: _currentStep, label: 'Payment'),
          _StepDivider(index: 1, currentIndex: _currentStep),
          _StepIcon(index: 2, currentIndex: _currentStep, label: 'Review'),
        ],
      ),
    );
  }

  Widget _buildShippingStep({Key? key}) {
    if (_isLoadingAddresses) {
      return Padding(
        key: key,
        padding: const EdgeInsets.all(40.0),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_savedAddresses.isNotEmpty) ...[
            Row(
              children: [
                _SectionTitle(title: 'Saved Addresses', icon: Icons.bookmark_rounded),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddressForm(),
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: const Text('Add New'),
                ),
              ],
            ),
          const SizedBox(height: 12),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _savedAddresses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final addr = _savedAddresses[index];
                  return InkWell(
                    onTap: () => _fillAddress(addr),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.surfaceContainerLow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                addr.label?.toUpperCase() ?? 'HOME',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const Spacer(),
                              if (addr.isDefault)
                                const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            addr.fullName,
                            style: GoogleFonts.outfit(
                              fontSize: 13, 
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.displayString,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11, 
                              color: AppTheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAddressForm(),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Select from Map'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _SectionTitle(title: 'Delivery Information', icon: Icons.local_shipping_rounded),
          const SizedBox(height: 20),
          _CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            validator: (v) => v!.length != 10 ? 'Enter valid 10-digit number' : null,
          ),
          const SizedBox(height: 16),
          _CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email for order updates',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => !v!.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          _CustomTextField(
            controller: _addressController,
            label: 'Full Address',
            hint: 'House No, Street, Landmark',
            maxLines: 3,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CustomTextField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.length != 6 ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CustomTextField(
            controller: _stateController,
            label: 'State',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _CustomTextField(
            controller: _notesController,
            label: 'Order Notes (Optional)',
            hint: 'Special instructions for delivery',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _buildCouponSection(),
        ],
    );
  }

  Widget _buildCouponSection() {
    final cart = ref.watch(cartProvider);
    final hasCoupon = cart.couponCode != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Have a Coupon?', icon: Icons.confirmation_number_rounded, small: true),
          const SizedBox(height: 12),
          if (hasCoupon)
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
                      hintText: 'Enter coupon code',
                      hintStyle: const TextStyle(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isValidatingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isValidatingCoupon
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    try {
      final user = ref.read(userProfileProvider).valueOrNull;
      final cart = ref.read(cartProvider);
      
      // Need a way to get orderCount for validation
      // For now, passing 0 or fetching from OrderService
      final coupon = await CouponService.validateCoupon(
        code, 
        userId: user?.supabaseId,
        guestEmail: _emailController.text,
        phone: _phoneController.text,
      );

      if (coupon == null) {
        throw Exception('Invalid or expired coupon code');
      }

      // Check min order
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
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }

  Widget _buildPaymentStep({Key? key}) {
    final settingsAsync = ref.watch(paymentSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Auto-select COD if Razorpay is disabled and currently selected
        if (!settings.razorpayEnabled && _paymentMethod == 'razorpay' && settings.codEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _paymentMethod == 'razorpay') {
              setState(() => _paymentMethod = 'cod');
            }
          });
        }

        return Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Choose Payment Method', icon: Icons.payment_rounded),
          const SizedBox(height: 20),
          if (settings.razorpayEnabled)
            _PaymentOption(
              id: 'razorpay',
              title: 'Pay Online',
              subtitle: 'Credit/Debit Cards, UPI, Netbanking',
              icon: Icons.account_balance_wallet_rounded,
              selectedId: _paymentMethod,
              onChanged: (id) => setState(() => _paymentMethod = id),
            ),
          if (!settings.razorpayEnabled)
             Padding(
               padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
               child: Text(
                 'Online payment is currently disabled.',
                 style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)),
               ),
             ),
          if (settings.razorpayEnabled && settings.codEnabled) const SizedBox(height: 12),
          if (settings.codEnabled)
            _PaymentOption(
              id: 'cod',
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              icon: Icons.money_rounded,
              selectedId: _paymentMethod,
              onChanged: (id) => setState(() => _paymentMethod = id),
            ),
          if (!settings.razorpayEnabled && !settings.codEnabled)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Online payments are currently unavailable. Please try again later.')),
            ),
        ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(child: Text('Error loading payment methods: $e')),
      ),
    );
  }

  Widget _buildReviewStep({Key? key}) {
    final cart = ref.read(cartProvider);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionTitle(title: 'Order Summary', icon: Icons.receipt_long_rounded),
        const SizedBox(height: 20),
        
        // Items list
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: cart.items.map((item) => _ReviewItem(item: item)).toList(),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Shipping details review
        _SectionTitle(title: 'Delivery To', icon: Icons.location_on_rounded, small: true),
        const SizedBox(height: 8),
        Text(
          '${_nameController.text}\n${_addressController.text}\n${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}\nPhone: ${_phoneController.text}',
          style: GoogleFonts.beVietnamPro(height: 1.5, color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _buildCouponSection(),
        const SizedBox(height: 24),
        // Totals
        _PriceRow(label: 'Subtotal', value: cart.subtotal),
        _PriceRow(label: 'Shipping', value: cart.shippingAmount),
        if (cart.discountAmount > 0)
          _PriceRow(label: 'Discount', value: -cart.discountAmount, isDiscount: true),
        const Divider(height: 32),
        _PriceRow(label: 'Total', value: cart.total, isTotal: true),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () {
                  if (_currentStep == 0) {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _currentStep++);
                    }
                  } else if (_currentStep == 1) {
                    setState(() => _currentStep++);
                  } else {
                    _processOrder();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : ref.watch(paymentSettingsProvider).maybeWhen(
                        data: (_) => Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
                        loading: () => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        orElse: () => Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String label;

  const _StepIcon({required this.index, required this.currentIndex, required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = currentIndex > index;
    final bool isActive = currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.primary : (isActive ? AppTheme.primary : AppTheme.outlineVariant),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  final int index;
  final int currentIndex;

  const _StepDivider({required this.index, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: currentIndex > index ? AppTheme.primary : AppTheme.outlineVariant,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool small;

  const _SectionTitle({required this.title, required this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: small ? 18 : 22, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: small ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.surfaceContainerLowest,
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String selectedId;
  final Function(String) onChanged;

  const _PaymentOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedId == id;
    return InkWell(
      onTap: () => onChanged(id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary)
            else
              const Icon(Icons.circle_outlined, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final CartItem item;

  const _ReviewItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Semantics(
              label: '${item.product.name} in order',
              image: true,
              child: Image.network(
                item.product.imageMain ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: Colors.grey, width: 50, height: 50),
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
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isDiscount;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${value.abs().toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                fontSize: isTotal ? 22 : 16,
                fontWeight: FontWeight.bold,
                color: isTotal ? AppTheme.primary : (isDiscount ? Colors.red : AppTheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
