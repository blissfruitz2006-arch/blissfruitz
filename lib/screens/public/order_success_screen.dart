import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../config/theme.dart';
import '../../models/order.dart';
import '../../models/delivery_assignment.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  Order? _order;
  DeliveryAssignment? _assignment;
  bool _isLoading = true;
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isRatingSubmitted = false;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _loadData();
    _checkController.forward();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.orderId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final id = int.tryParse(widget.orderId);
      if (id != null) {
        final order = await OrderService.getOrderById(id);
        final deliveryService = ref.read(deliveryServiceProvider);
        final assignment = await deliveryService.getOrderAssignment(id);
        
        if (mounted) {
          setState(() {
            _order = order;
            _assignment = assignment;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0 || _assignment == null || _order == null) return;

    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final deliveryService = ref.read(deliveryServiceProvider);
      await deliveryService.saveRiderRating(
        orderId: _order!.id!,
        riderId: _assignment!.riderId,
        customerId: user.id,
        rating: _rating,
        feedback: _feedbackController.text,
      );
      if (mounted) {
        setState(() {
          _isRatingSubmitted = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _order?.orderStatus == 'delivered';
    final displayOrderId = _order?.orderNumber ?? widget.orderId;

    return Title(
      title: 'Order Successful | BlissFruitz',
      color: AppTheme.primary,
      child: Scaffold(
        body: Stack(
          children: [
            // Confetti Background for just-delivered/just-placed feel
            if (!_isLoading)
              Positioned.fill(
                child: CustomPaint(
                  painter: ConfettiPainter(animation: _checkAnimation),
                ),
              ),
            
            SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Success Icon
                        ScaleTransition(
                          scale: _checkAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                              size: 100,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          isDelivered ? 'Order Delivered!' : 'Order Placed!',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isDelivered 
                            ? 'Your fresh fruits have been delivered. Enjoy!'
                            : 'Thank you for your purchase. We\'re preparing your order.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        if (_isLoading)
                          const CircularProgressIndicator()
                        else ...[
                          // Order Details Card
                          _buildDetailsCard(context, displayOrderId),
                          
                          const SizedBox(height: 32),

                          // Rating Section (Only if delivered and not already rated)
                          if (isDelivered && _assignment != null && !_isRatingSubmitted)
                            _buildRatingSection(context),

                          if (_isRatingSubmitted)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: AppTheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Rating submitted successfully!',
                                      style: GoogleFonts.beVietnamPro(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        const SizedBox(height: 48),
                        
                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go(isDelivered ? '/shop' : '/order-history'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              isDelivered ? 'Shop More' : 'Track Order',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/'),
                          child: Text(
                            'Back to Home',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, String orderNumber) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Order Number', '#$orderNumber'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildInfoRow('Amount Paid', '₹${_order?.total.toStringAsFixed(2) ?? '0.00'}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            'Status', 
            _order?.orderStatus.toUpperCase() ?? 'PENDING',
            isStatus: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'How was your delivery?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate your rider, ${_assignment?.rider?.fullName ?? "our partner"}',
            style: GoogleFonts.beVietnamPro(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: index < _rating ? Colors.amber : Colors.grey[400],
                  size: 40,
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Any feedback? (Optional)',
                hintStyle: GoogleFonts.beVietnamPro(fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit Rating'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<ConfettiPiece> pieces;

  ConfettiPainter({required this.animation})
      : pieces = List.generate(50, (i) => ConfettiPiece()),
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    for (var piece in pieces) {
      final opacity = (1.0 - animation.value).clamp(0.0, 1.0);
      final paint = Paint()..color = piece.color.withValues(alpha: opacity);
      
      final progress = animation.value;
      final x = piece.startX + (piece.vx * progress * 500);
      final y = piece.startY + (piece.vy * progress * 500) + (0.5 * 9.8 * progress * progress * 500);
      
      canvas.save();
      canvas.translate(x % size.width, y % size.height);
      canvas.rotate(piece.rotation * progress);
      canvas.drawRect(Rect.fromLTWH(0, 0, piece.size, piece.size), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiPiece {
  final double startX = Random().nextDouble() * 400;
  final double startY = -20;
  final double vx = Random().nextDouble() * 2 - 1;
  final double vy = Random().nextDouble() * 2 + 2;
  final double size = Random().nextDouble() * 6 + 4;
  final double rotation = Random().nextDouble() * pi * 2;
  final Color color = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.pink, Colors.orange
  ][Random().nextInt(6)];
}
