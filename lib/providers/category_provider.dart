import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/category_service.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return CategoryService.getCategories();
});
