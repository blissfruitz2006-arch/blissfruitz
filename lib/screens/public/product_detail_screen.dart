import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/product_card.dart';
import '../../widgets/footer.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../widgets/scrollable_table_html_extension.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  List<Product> _relatedProducts = [];
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  double get screenWidth => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final product = await ProductService.getProductBySlug(widget.slug);
      if (product == null) {
        setState(() {
          _error = 'Product not found';
          _isLoading = false;
        });
        return;
      }

      final related = await ProductService.getRelatedProducts(
        product.categoryId ?? 0,
        product.id,
        limit: 4,
      );

      final reviews = await ReviewService.getProductReviews(product.id);

      if (mounted) {
        setState(() {
          _product = product;
          _relatedProducts = related;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load product details';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _product == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'Product not found', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/shop'),
              child: const Text('Back to Shop'),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final contentWidth = isDesktop ? 1400.0 : screenWidth; // Increased from 1200 to 1400 for wider layout

    return Title(
      title: '${_product!.name} | Blissfruitz',
      color: AppTheme.primary,
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              cacheExtent: 1000,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // --- 1. Main Content (Image & Info) ---
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 40 : 20),
                        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
                      ),
                    ),
                  ),
                ),

                // --- 2. Full Description ---
                SliverToBoxAdapter(
                  child: _buildFullDescription(contentWidth),
                ),

                // --- 3. Related Products ---
                if (_relatedProducts.isNotEmpty)
                  _buildRelatedProductsSliver(isDesktop),

                // --- 4. Reviews Section ---
                _buildReviewsSectionSliver(contentWidth),

                // --- 5. Footer ---
                const SliverToBoxAdapter(child: AppFooter()),
                
                if (!isDesktop) 
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            if (!isDesktop) _buildMobileStickyFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Section
        Expanded(
          flex: 5,
          child: _buildProductImage(),
        ),
        const SizedBox(width: 60),
        // Info Section
        Expanded(
          flex: 4,
          child: _buildProductInfo(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductImage(),
        const SizedBox(height: 24),
        _buildProductInfo(),
      ],
    );
  }

  Widget _buildProductImage() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Hero(
            tag: 'product-${_product!.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppImage(
                    path: _product!.imageMain,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          if (_product!.hasDiscount)
            Positioned(
              top: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE52D27), Color(0xFFB31217)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB31217).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '${_product!.discountPercent.toStringAsFixed(0)}% OFF',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _product!.category?.name.toUpperCase() ?? 'FRESH',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Product Name
          Text(
            _product!.name,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          
          // Rating & Reviews count
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '4.8', // Mock rating
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '(${_reviews.length} Reviews)',
                style: GoogleFonts.beVietnamPro(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_product!.price.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '/ ${_product!.unit}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_product!.hasDiscount) ...[
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '₹${_product!.comparePrice!.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _DiscountBadge(percent: _product!.discountPercent.round()),
              ],
            ],
          ),
          const SizedBox(height: 32),
          
          // Short Summary (Moved above actions)
          if (_product!.shortDescription != null && _product!.shortDescription!.isNotEmpty) ...[
            Text(
              _product!.shortDescription!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
          ],
          
          // Quantity and Actions
          _buildActionSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildFullDescription(double contentWidth) {
    if (_product!.description == null || _product!.description!.isEmpty) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth - 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Details',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                Html(
                  data: _product!.description!,
                  extensions: const [
                    ScrollableTableHtmlExtension(),
                  ],
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.8),
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
                    ),
                    "table": Style(
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      padding: HtmlPaddings.all(8),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      margin: Margins.only(top: 16, bottom: 16),
                    ),
                    "th": Style(
                      padding: HtmlPaddings.all(12),
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
                      fontWeight: FontWeight.bold,
                      whiteSpace: WhiteSpace.pre,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    "td": Style(
                      padding: HtmlPaddings.all(12),
                      whiteSpace: WhiteSpace.pre,
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    "tr": Style(
                       border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        screenWidth < 350 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuantityPicker(isDark),
                const SizedBox(height: 16),
                _buildStockStatus(),
              ],
            )
          : Row(
              children: [
                _buildQuantityPicker(isDark),
                const SizedBox(width: 20),
                _buildStockStatus(),
              ],
            ),
        const SizedBox(height: 24),
        screenWidth < 350
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _buildAddToCartButton(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildBuyNowButton(),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildAddToCartButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildBuyNowButton()),
              ],
            ),
      ],
    );
  }

  Widget _buildMobileStickyFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                ),
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
                // Quantity Selector
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      _qtyBtn(Icons.remove_rounded, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Container(
                        constraints: BoxConstraints(minWidth: screenWidth < 350 ? 20 : 30),
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: screenWidth < 350 ? 14 : 16,
                          ),
                        ),
                      ),
                      _qtyBtn(Icons.add_rounded, () => setState(() => _quantity++)),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth < 350 ? 8 : 16),
                // Add to Cart Button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (_product?.inStock ?? false) ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: screenWidth < 350 ? 8 : 16),
                        elevation: 0,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _product?.inStock ?? true ? 'Add to Cart' : 'Out of Stock',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: screenWidth < 350 ? 13 : 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < 350 ? 8 : 20),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildRelatedProductsSliver(bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: isDesktop ? 60 : 20),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 40 : (screenWidth < 350 ? 12 : 20), 
                    8, 
                    isDesktop ? 40 : (screenWidth < 350 ? 12 : 20), 
                    8
                  ),
                  child: Text(
                    'Related Products',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 1200 ? 5 : (screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2)),
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _relatedProducts.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: _relatedProducts[index],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSectionSliver(double contentWidth) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Reviews',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {}, // Add review functionality
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Write Review'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_reviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet. Be the first to review!',
                            style: GoogleFonts.beVietnamPro(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    separatorBuilder: (context, index) => const Divider(height: 48),
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.guestName ?? 'Verified Buyer',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: i < review.rating ? Colors.amber : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (review.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            review.comment ?? '',
                            style: GoogleFonts.beVietnamPro(height: 1.5),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    for (int i = 0; i < _quantity; i++) {
        ref.read(cartProvider.notifier).addItem(_product!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  void _buyNow() {
    _addToCart();
    context.go('/cart');
  }

  Widget _buildQuantityPicker(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _product!.inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: _product!.inStock ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _product!.inStock ? 'In Stock' : 'Out of Stock',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w600,
            color: _product!.inStock ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    return ElevatedButton(
      onPressed: _product!.inStock ? _addToCart : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: screenWidth < 350 ? 14 : 20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Add to Cart',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 350 ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyNowButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    return ElevatedButton(
      onPressed: _product!.inStock ? _buyNow : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.onSurface,
        foregroundColor: Theme.of(context).colorScheme.surface,
        padding: EdgeInsets.symmetric(vertical: screenWidth < 350 ? 14 : 20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Buy Now',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 350 ? 14 : 16,
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final int percent;

  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4B2B), Color(0xFFFF416C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF416C).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$percent% OFF',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
