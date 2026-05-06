import '../config/supabase_config.dart';
import '../models/product.dart';

class CategoryService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<Category>> getCategories() async {
    final data = await _client
        .from('Category')
        .select()
        .order('name', ascending: true);

    return (data as List).map((e) => Category.fromJson(e)).toList();
  }
}
