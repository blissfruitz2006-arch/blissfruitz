import '../config/supabase_config.dart';
import '../models/product.dart';

class ProductService {
  static final _client = SupabaseConfig.client;

  static Future<List<Product>> getProducts({
    String? categorySlug,
    String? search,
    String? sortBy,
    int limit = 50,
    int offset = 0,
  }) async {
    // Build query step by step, applying filters first, then sorting
    var query = _client.from('Product').select('*, Category(*)');

    // Sorting is applied at the end; filters are applied to the base query
    // Supabase postgrest builder requires ordering before range
    List<Map<String, dynamic>> data;

    if (categorySlug != null && categorySlug.isNotEmpty) {
      // When filtering by category, we need a different approach
      // since we can't filter on joined table with .select()
      final categories = await _client
          .from('Category')
          .select('id')
          .eq('slug', categorySlug)
          .limit(1);

      if (categories.isEmpty) return [];
      final categoryId = categories.first['id'] as int;

      var filtered =
          query.eq('isActive', true).eq('isDeleted', false).eq('categoryId', categoryId);

      if (search != null && search.isNotEmpty) {
        filtered = filtered.ilike('name', '%$search%');
      }

      data = await filtered
          .order(_getSortColumn(sortBy), ascending: _getSortAscending(sortBy))
          .range(offset, offset + limit - 1);
    } else {
      var filtered = query.eq('isActive', true).eq('isDeleted', false);

      if (search != null && search.isNotEmpty) {
        filtered = filtered.ilike('name', '%$search%');
      }

      data = await filtered
          .order(_getSortColumn(sortBy), ascending: _getSortAscending(sortBy))
          .range(offset, offset + limit - 1);
    }

    return data.map((e) => Product.fromJson(e)).toList();
  }

  static String _getSortColumn(String? sortBy) {
    switch (sortBy) {
      case 'price_asc':
      case 'price_desc':
        return 'price';
      case 'newest':
      default:
        return 'createdAt';
    }
  }

  static bool _getSortAscending(String? sortBy) {
    switch (sortBy) {
      case 'price_asc':
        return true;
      case 'price_desc':
        return false;
      case 'newest':
      default:
        return false;
    }
  }

  static Future<List<Product>> getFeaturedProducts() async {
    final data = await _client
        .from('Product')
        .select('*, Category(*)')
        .eq('isActive', true)
        .eq('isDeleted', false)
        .order('isFeatured', ascending: false)
        .limit(8);

    return data.map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product?> getProductBySlug(String slug) async {
    final data = await _client
        .from('Product')
        .select('*, Category(*)')
        .eq('slug', slug)
        .eq('isDeleted', false)
        .maybeSingle();

    if (data == null) return null;
    return Product.fromJson(data);
  }

  static Future<List<Product>> getProductsByCategory(int categoryId) async {
    final data = await _client
        .from('Product')
        .select('*, Category(*)')
        .eq('categoryId', categoryId)
        .eq('isActive', true)
        .eq('isDeleted', false)
        .order('createdAt', ascending: false);

    return data.map((e) => Product.fromJson(e)).toList();
  }

  static Future<List<Product>> getRelatedProducts(
      int categoryId, int excludeId, {int limit = 12, int offset = 0}) async {
    final data = await _client
        .from('Product')
        .select('*, Category(*)')
        .eq('categoryId', categoryId)
        .neq('id', excludeId)
        .eq('isActive', true)
        .eq('isDeleted', false)
        .order('createdAt', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product?> getProductById(String id) async {
    final data = await _client
        .from('Product')
        .select('*, Category(*)')
        .eq('id', int.parse(id))
        .eq('isDeleted', false)
        .maybeSingle();

    if (data == null) return null;
    return Product.fromJson(data);
  }
}
