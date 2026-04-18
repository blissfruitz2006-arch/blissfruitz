import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../config/theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/footer.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _debouncedQuery = ''; // Actual query sent to provider
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  Timer? _debounceTimer;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final filter = ProductFilter(
        categorySlug: _selectedCategory == 'all' ? null : _selectedCategory,
        search: _debouncedQuery.isEmpty ? null : _debouncedQuery,
      );
      ref.read(paginatedProductsProvider(filter).notifier).fetchMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _debouncedQuery = value);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reactively read query params from the URL using GoRouterState
    final state = GoRouterState.of(context);
    final categoryParam = state.uri.queryParameters['category'];
    final searchParam = state.uri.queryParameters['search'];

    // Update local state only if not already initialized
    if (!_initialized) {
      if (categoryParam != null) _selectedCategory = categoryParam;
      if (searchParam != null) {
        _searchQuery = searchParam;
        _debouncedQuery = searchParam;
        _searchController.text = searchParam;
      }
      _initialized = true;
    }

    final filter = ProductFilter(
      categorySlug: _selectedCategory == 'all' ? null : _selectedCategory,
      search: _debouncedQuery.isEmpty ? null : _debouncedQuery,
    );
    final productsAsync = ref.watch(paginatedProductsProvider(filter));
    final categories = ref.watch(categoriesProvider);

    // Cache the cross-axis count once per build
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isUltraSmall = screenWidth < 350;
    final isTiny = screenWidth < 280;
    final crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : (isUltraSmall ? 1 : 2)));
    final horizontalPadding = isTiny ? 12.0 : (isUltraSmall ? 16.0 : 24.0);
    final childAspectRatio = isUltraSmall ? 0.75 : 0.62; // Wider aspect ratio for single column tiny screens

    return Title(
      title: 'Shop Premium Organic Fruits | BlissFruitz',
      color: AppTheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        cacheExtent: 1500,
        slivers: [
          // ─── CATEGORY SECTION ───
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Container(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
                child: categories.when(
                  data: (data) => _buildCategoryList(data, isTiny),
                  loading: () => const SizedBox(height: 48),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // ─── SEARCH SECTION ───
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: _buildSearchBar(isTiny),
            ),
          ),

          // ─── PRODUCT GRID ───
          productsAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                );
              }
              final notifier = ref.read(paginatedProductsProvider(filter).notifier);
              
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 32),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: isTiny ? 12 : 16,
                        mainAxisSpacing: isTiny ? 12 : 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => RepaintBoundary(
                          child: ProductCard(
                            product: data[index],
                            onTap: () => context.push('/product/${data[index].slug}'),
                          ),
                        ),
                        childCount: data.length,
                      ),
                    ),
                    if (notifier.hasMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: isTiny ? 12 : 16,
                  mainAxisSpacing: isTiny ? 12 : 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, _) => const ProductCardSkeleton(),
                  childCount: 10,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: AppFooter()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 80, color: AppTheme.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            Text(
              'No fresh harvests found',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or category',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() {
                _selectedCategory = 'all';
                _searchController.clear();
                _searchQuery = '';
                _debouncedQuery = '';
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String slug, String name, bool isTiny) {
    final isSelected = _selectedCategory == slug;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = slug);
          }
        },
        labelStyle: GoogleFonts.outfit(
          fontSize: isTiny ? 12 : 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
        ),
        backgroundColor: Colors.transparent,
        selectedColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
        ),
        showCheckmark: false,
        padding: EdgeInsets.symmetric(
          horizontal: isTiny ? 8 : 12,
          vertical: isTiny ? 6 : 8,
        ),
      ),
    );
  }

  Widget _buildCategoryList(List categories, bool isTiny) {
    return SizedBox(
      height: isTiny ? 40 : 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('all', 'All Fruit', isTiny),
          ...categories.map((c) => _buildCategoryChip(c.slug, c.name, isTiny)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isTiny) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: isTiny ? const TextStyle(fontSize: 14) : null,
        decoration: InputDecoration(
          hintText: isTiny ? 'Search...' : 'Search fresh harvests...',
          prefixIcon: Icon(Icons.search_rounded, size: isTiny ? 20 : 24),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: isTiny ? 18 : 24),
                onPressed: () {
                  _searchController.clear();
                  _debounceTimer?.cancel();
                  setState(() {
                    _searchQuery = '';
                    _debouncedQuery = '';
                  });
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTiny ? 12 : 16,
            vertical: isTiny ? 10 : 12,
          ),
        ),
      ),
    );
  }
}
