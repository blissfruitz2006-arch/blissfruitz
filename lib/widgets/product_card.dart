import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../config/theme.dart';
import 'app_image.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key, 
    required this.product, 
    this.onTap,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    // Start entrance animation on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RepaintBoundary(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onTap ?? () => context.push('/product/${product.slug}'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth;
                  final isSmallCard = cardWidth < 180;
                  final isTinyCard = cardWidth < 140;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    clipBehavior: Clip.antiAlias,
                    transform: Matrix4.diagonal3Values(
                      _isHovered ? 1.03 : 1.0,
                      _isHovered ? 1.03 : 1.0,
                      1.0,
                    ),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(isSmallCard ? 20 : 28),
                      border: Border.all(
                        color: _isHovered 
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _isHovered ? 0.12 : 0.04),
                          blurRadius: _isHovered ? 40 : 24,
                          offset: Offset(0, _isHovered ? 20 : 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Section
                        Stack(
                          children: [
                            Hero(
                              tag: 'product-${product.id}',
                              child: AspectRatio(
                                aspectRatio: 1.1,
                                child: AppImage(
                                  path: product.imageMain,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            
                            // Hover Overlay (Quick View hint)
                            if (_isHovered && !isSmallCard)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  child: Center(
                                    child: _SolidBadge(
                                      child: Icon(
                                        Icons.remove_red_eye_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
        
                            // Category Tag
                            Positioned(
                              top: isSmallCard ? 8 : 16,
                              left: isSmallCard ? 8 : 16,
                              child: _SolidBadge(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallCard ? 8 : 10, 
                                  vertical: isSmallCard ? 4 : 6
                                ),
                                child: Text(
                                  product.category?.name.toUpperCase() ?? 'FRUIT',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: isSmallCard ? 8 : 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
        
                            // Discount Tag
                            if (product.hasDiscount)
                              Positioned(
                                top: isSmallCard ? 8 : 16,
                                right: isSmallCard ? 8 : 16,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallCard ? 8 : 12, 
                                    vertical: isSmallCard ? 4 : 6
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE52D27), Color(0xFFB31217)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isSmallCard ? 8 : 12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFB31217).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${product.discountPercent.toStringAsFixed(0)}% OFF',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: isSmallCard ? 8 : 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
        
                        // Content Section
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isSmallCard ? 12 : 20, 
                              isSmallCard ? 10 : 16, 
                              isSmallCard ? 12 : 20, 
                              isSmallCard ? 12 : 20
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: isTinyCard ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: isTinyCard ? 14 : (isSmallCard ? 16 : 18),
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.unit,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: isSmallCard ? 11 : 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white54 : Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (product.hasDiscount)
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '₹${product.comparePrice!.toStringAsFixed(0)}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: isSmallCard ? 11 : 14,
                                                  color: isDark ? Colors.white24 : Colors.grey[400],
                                                  decoration: TextDecoration.lineThrough,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '₹${product.price.toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                fontSize: isTinyCard ? 18 : (isSmallCard ? 20 : 24),
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.primary,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _AddButton(
                                      product: product, 
                                      isHovered: _isHovered,
                                      size: isTinyCard ? 36 : (isSmallCard ? 42 : 50),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid semi-transparent badge — replaces the expensive `BackdropFilter` glass.
/// Visually identical at small badge sizes but ~10x cheaper on the GPU.
class _SolidBadge extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _SolidBadge({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _AddButton extends ConsumerWidget {
  final Product product;
  final bool isHovered;
  final double size;
  
  const _AddButton({
    required this.product, 
    required this.isHovered,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveSize = isHovered ? size * 1.12 : size;
    
    return GestureDetector(
      onTap: () {
        if (product.inStock) {
          ref.read(cartProvider.notifier).addItem(product);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              width: 300,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: effectiveSize,
        height: effectiveSize,
        decoration: BoxDecoration(
          color: product.inStock ? AppTheme.primary : Colors.grey[400],
          borderRadius: BorderRadius.circular(size * 0.4),
          boxShadow: [
            if (product.inStock)
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: isHovered ? 20 : 12,
                offset: Offset(0, isHovered ? 10 : 6),
              ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}

