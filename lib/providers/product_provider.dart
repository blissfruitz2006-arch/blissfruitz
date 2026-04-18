import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';

// All products (optionally filtered)
final productsProvider =
    FutureProvider.family<List<Product>, ProductFilter>((ref, filter) async {
  return ProductService.getProducts(
    categorySlug: filter.categorySlug,
    search: filter.search,
    sortBy: filter.sortBy,
  );
});

// Featured products for homepage
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ProductService.getFeaturedProducts();
});

// Home products (subset for home page)
final homeProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ProductService.getProducts(limit: 10);
});

// Single product by slug
final productBySlugProvider =
    FutureProvider.family<Product?, String>((ref, slug) async {
  return ProductService.getProductBySlug(slug);
});

// Single product by ID
final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  return ProductService.getProductById(id);
});

typedef RelatedParams = ({int categoryId, int excludeProductId});

class RelatedProductsNotifier
    extends FamilyAsyncNotifier<List<Product>, RelatedParams> {
  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Product>> build(RelatedParams arg) async {
    _offset = 0;
    _hasMore = true;
    return ProductService.getRelatedProducts(arg.categoryId, arg.excludeProductId,
        limit: 12, offset: 0);
  }

  Future<void> fetchMore() async {
    if (!_hasMore || state.isLoading || state.isRefreshing) return;

    final currentProducts = state.value ?? [];
    _offset += 12;

    state = const AsyncLoading<List<Product>>().copyWithPrevious(state);
    
    final newProducts = await ProductService.getRelatedProducts(
        arg.categoryId, arg.excludeProductId,
        limit: 12, offset: _offset);

    if (newProducts.length < 12) _hasMore = false;
    state = AsyncValue.data([...currentProducts, ...newProducts]);
  }
}

final relatedProductsNotifierProvider = AsyncNotifierProviderFamily<
    RelatedProductsNotifier, List<Product>, RelatedParams>(
  RelatedProductsNotifier.new,
);

final relatedProductsProvider =
    FutureProvider.family<List<Product>, RelatedParams>((ref, params) async {
  return ProductService.getRelatedProducts(
      params.categoryId, params.excludeProductId);
});

// Paginated product list
class PaginatedProductsNotifier extends FamilyAsyncNotifier<List<Product>, ProductFilter> {
  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  static const int _limit = 10;

  @override
  Future<List<Product>> build(ProductFilter arg) async {
    _offset = 0;
    _hasMore = true;
    return ProductService.getProducts(
      categorySlug: arg.categorySlug,
      search: arg.search,
      sortBy: arg.sortBy,
      limit: _limit,
      offset: 0,
    );
  }

  Future<void> fetchMore() async {
    if (!_hasMore || state.isLoading || state.isRefreshing) return;

    final currentProducts = state.value ?? [];
    _offset += _limit;

    state = const AsyncLoading<List<Product>>().copyWithPrevious(state);
    
    try {
      final newProducts = await ProductService.getProducts(
        categorySlug: arg.categorySlug,
        search: arg.search,
        sortBy: arg.sortBy,
        limit: _limit,
        offset: _offset,
      );

      if (newProducts.length < _limit) _hasMore = false;
      state = AsyncValue.data([...currentProducts, ...newProducts]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final paginatedProductsProvider = AsyncNotifierProviderFamily<
    PaginatedProductsNotifier, List<Product>, ProductFilter>(
  PaginatedProductsNotifier.new,
);

// Filter model
class ProductFilter {
  final String? categorySlug;
  final String? search;
  final String? sortBy;

  const ProductFilter({
    this.categorySlug,
    this.search,
    this.sortBy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilter &&
          categorySlug == other.categorySlug &&
          search == other.search &&
          sortBy == other.sortBy;

  @override
  int get hashCode => Object.hash(categorySlug, search, sortBy);
}
