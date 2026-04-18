import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/cart.dart';
import '../models/product.dart';

/// Service for persisting cart to local storage and syncing with
/// the Supabase Cart/CartLine tables for authenticated users.
class CartService {
  static const _localCartKey = 'blissfruitz_guest_cart';
  static final _client = SupabaseConfig.client;

  // ─── Local Storage (Guest Cart) ───

  /// Save cart items to SharedPreferences
  static Future<void> saveLocalCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = items
        .map((item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
            })
        .toList();
    await prefs.setString(_localCartKey, jsonEncode(cartJson));
  }

  /// Load guest cart from SharedPreferences
  static Future<List<Map<String, dynamic>>> loadLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_localCartKey);
    if (cartString == null) return [];

    try {
      final decoded = jsonDecode(cartString) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clear local cart
  static Future<void> clearLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localCartKey);
  }

  /// Load guest cart from SharedPreferences with full product data from DB
  static Future<List<CartItem>> loadLocalCartWithFullProducts() async {
    final rawItems = await loadLocalCart();
    if (rawItems.isEmpty) return [];

    final productIds = rawItems.map((i) => i['productId']).toList();
    final productsResponse = await _client
        .from('Product')
        .select('*')
        .inFilter('id', productIds);

    final products = (productsResponse as List)
        .map((p) => Product.fromJson(p))
        .toList();

    return rawItems.map((item) {
      final product = products.firstWhere(
        (p) => p.id == item['productId'],
        orElse: () => throw Exception('Product not found'),
      );
      return CartItem(
        product: product,
        quantity: item['quantity'] as int,
      );
    }).toList();
  }

  // ─── Supabase DB Cart (Logged-in Users) ───

  /// Get or create a DB cart for the given user
  static Future<String> _getOrCreateCartId(int userId) async {
    // Try to find existing cart
    final existing = await _client
        .from('Cart')
        .select('id')
        .eq('userId', userId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create new cart
    final cartId = 'cart_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('Cart').insert({
      'id': cartId,
      'userId': userId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return cartId;
  }

  /// Sync local cart to Supabase for an authenticated user
  static Future<void> syncCartToDb(int userId, List<CartItem> items) async {
    final cartId = await _getOrCreateCartId(userId);

    // Clear existing cart lines
    await _client.from('CartLine').delete().eq('cartId', cartId);

    // Insert current items
    if (items.isNotEmpty) {
      final lines = items.map((item) => {
            'cartId': cartId,
            'productId': item.product.id,
            'quantity': item.quantity,
          }).toList();

      await _client.from('CartLine').insert(lines);
    }

    // Update cart timestamp
    await _client.from('Cart').update({
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', cartId);
  }

  /// Load cart from Supabase DB for authenticated user
  static Future<List<CartItem>> loadCartFromDb(int userId) async {
    final cart = await _client
        .from('Cart')
        .select('id')
        .eq('userId', userId)
        .maybeSingle();

    if (cart == null) return [];

    final cartId = cart['id'] as String;
    final lines = await _client
        .from('CartLine')
        .select('*, Product(*)')
        .eq('cartId', cartId);

    return (lines as List).map((line) {
      final product = Product.fromJson(line['Product']);
      return CartItem(
        product: product,
        quantity: line['quantity'] as int? ?? 1,
      );
    }).toList();
  }

  /// Merge local guest cart into the DB cart on login
  static Future<List<CartItem>> mergeCartsOnLogin(
    int userId,
    List<CartItem> localItems,
  ) async {
    // Load existing DB cart
    final dbItems = await loadCartFromDb(userId);

    // Merge: guest items override DB quantities for same product
    final mergedMap = <int, CartItem>{};
    for (final item in dbItems) {
      mergedMap[item.product.id] = item;
    }
    for (final item in localItems) {
      if (mergedMap.containsKey(item.product.id)) {
        // Add quantities
        mergedMap[item.product.id]!.quantity += item.quantity;
      } else {
        mergedMap[item.product.id] = item;
      }
    }

    final merged = mergedMap.values.toList();

    // Sync merged cart back to DB
    await syncCartToDb(userId, merged);

    // Clear local cart
    await clearLocalCart();

    return merged;
  }
}
