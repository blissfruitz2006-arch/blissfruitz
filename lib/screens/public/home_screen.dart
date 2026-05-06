import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/banner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/blog_provider.dart';
import '../../config/theme.dart';
import '../../widgets/hero_banner_carousel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/footer.dart';
import '../../widgets/app_download_popup.dart';
import '../../widgets/offer_carousel.dart';
import '../../models/blog_post.dart';
import '../../widgets/blog_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch all necessary providers
    final heroBanners = ref.watch(bannersByPlacementProvider('hero'));
    final topBanners = ref.watch(bannersByPlacementProvider('home_top'));
    final middleBanners = ref.watch(bannersByPlacementProvider('home_middle'));
    final bottomBanners = ref.watch(bannersByPlacementProvider('home_bottom'));
    final homeProducts = ref.watch(homeProductsProvider);
    final offers = ref.watch(offersProvider);
    final blogs = ref.watch(blogPostsProvider);

    return Title(
      title: 'BlissFruitz - Fresh Organic Fruits Delivered',
      color: AppTheme.primary,
      child: Stack(
        children: [
          CustomScrollView(
            cacheExtent: 1500, // Pre-render slightly off-screen for smoother scrolling
            slivers: [
              // --- 1. Hero Section ---
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: heroBanners.when(
                    data: (data) => data.isEmpty 
                        ? const SizedBox.shrink() 
                        : HeroBannerCarousel(
                            key: ValueKey(data.length),
                            banners: data,
                            onBannerTap: (url) { if (url != null) context.go(url); },
                          ),
                    loading: () => const LoadingSkeleton(height: 480),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),

              // --- 2. Benefit Bar ---
              SliverToBoxAdapter(
                child: RepaintBoundary(child: _buildBenefitBar(context)),
              ),

              // --- 2.5 Top Banners (Optional) ---
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: topBanners.when(
                    data: (data) => data.isEmpty 
                      ? const SizedBox.shrink() 
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: HeroBannerCarousel(
                            banners: data, 
                            height: 200,
                            showTag: false,
                            onBannerTap: (url) { if (url != null) context.go(url); },
                          ),
                        ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              // --- 3. Featured Products Header ---
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'Fresh Harvests',
                  subtitle: 'Directly from organic orchards to your doorstep',
                  onViewAll: () => context.go('/shop'),
                ),
              ),
              
              // --- Featured Products Grid ---
              homeProducts.when(
                data: (data) => _ProductSliverGrid(products: data),
                loading: () => const _ProductGridSkeleton(),
                error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // --- 4. Middle Banners ---
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: middleBanners.when(
                    data: (data) => data.isEmpty 
                      ? const SizedBox.shrink() 
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: HeroBannerCarousel(
                            banners: data, 
                            height: 240,
                            showTag: false,
                            onBannerTap: (url) { if (url != null) context.go(url); },
                          ),
                        ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: LoadingSkeleton(height: 240),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // --- 5. Offers Section ---
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: offers.when(
                    data: (data) => data.isEmpty ? const SizedBox.shrink() : OfferCarousel(offers: data),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // --- 6. Bottom Banners ---
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: bottomBanners.when(
                    data: (data) => data.isEmpty 
                      ? const SizedBox.shrink() 
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: HeroBannerCarousel(
                            banners: data, 
                            height: 240,
                            showTag: false,
                            onBannerTap: (url) { if (url != null) context.go(url); },
                          ),
                        ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: LoadingSkeleton(height: 240),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),

              // --- 7. From The Blog Header ---
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: 'Fruitful Living',
                  subtitle: 'Tips, recipes, and health benefits of organic fruits',
                  onViewAll: () => context.go('/blog'),
                ),
              ),
              
              // --- Blog Row ---
              SliverToBoxAdapter(
                child: blogs.when(
                  data: (data) => _buildBlogRow(context, data.take(4).toList()),
                  loading: () => const SizedBox(height: 200),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: AppFooter()),
            ],
          ),
          
          // --- App Download Popup (Only for Web) ---
          if (kIsWeb)
            const AppDownloadPopup(),
        ],
      ),
    );
  }

  Widget _buildBenefitBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTiny = screenWidth < 280;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: isTiny ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: isTiny ? 12 : 40,
        runSpacing: 24,
        children: [
          _buildBenefitItem(context, Icons.eco_rounded, '100% Organic', 'Certified chemical-free'),
          _buildBenefitItem(context, Icons.local_shipping_rounded, 'Express Delivery', 'Same day delivery'),
          _buildBenefitItem(context, Icons.verified_user_rounded, 'Guaranteed Fresh', 'Farm to fork in 24h'),
          _buildBenefitItem(context, Icons.support_agent_rounded, 'Expert Support', 'Available 24/7'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String title, String subtitle) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTiny = screenWidth < 280;
    
    return SizedBox(
      width: isTiny ? (screenWidth - 48) : 200,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isTiny ? 8 : 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primary, size: isTiny ? 22 : 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: isTiny ? 13 : 15,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: isTiny ? 10 : 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onViewAll,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isUltraSmall = screenWidth < 350;
    final isTiny = screenWidth < 280;

    return Padding(
      padding: EdgeInsets.fromLTRB(isTiny ? 16 : 24, 0, isTiny ? 12 : 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.philosopher(
                    fontSize: isTiny ? 24 : (isUltraSmall ? 28 : 36),
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: isTiny ? 12 : 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: EdgeInsets.symmetric(horizontal: isTiny ? 8 : 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'All',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: isTiny ? 14 : 16,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: isTiny ? 16 : 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogRow(BuildContext context, List<BlogPost> posts) {
    return SizedBox(
      height: 340,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) => SizedBox(
          width: 280,
          child: BlogCard(post: posts[index]),
        ),
      ),
    );
  }
}

class _ProductSliverGrid extends StatelessWidget {
  final List products;
  const _ProductSliverGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isUltraSmall = width < 350;
    final isTiny = width < 280;
    final crossAxisCount = width > 1200 ? 5 : (width > 900 ? 4 : (width > 600 ? 3 : (isUltraSmall ? 1 : 2)));
    final childAspectRatio = isUltraSmall ? 0.75 : 0.62;
    final horizontalPadding = isTiny ? 16.0 : 24.0;
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isTiny ? 12 : 16,
          mainAxisSpacing: isTiny ? 12 : 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => RepaintBoundary(
            child: ProductCard(
              product: products[index],
              onTap: () => context.go('/product/${products[index].slug}'),
            ),
          ),
          childCount: products.length,
        ),
      ),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => const ProductCardSkeleton(),
          childCount: 4,
        ),
      ),
    );
  }
}

