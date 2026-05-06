import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/cart_service.dart';
import 'auth_provider.dart';

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  final notifier = CartNotifier(ref);
  
  // Watch for auth changes and notify the notifier
  ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
    notifier.handleAuthChange(previous?.valueOrNull, next.valueOrNull);
  });
  
  return notifier;
});

class CartNotifier extends StateNotifier<Cart> {
  final Ref ref;

  CartNotifier(this.ref) : super(const Cart()) {
    _init();
  }

  Future<void> _init() async {
    // Initial load
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && profile.supabaseId != null) {
      final items = await CartService.loadCartFromDb(profile.supabaseId!);
      state = state.copyWith(items: items);
    } else {
      final items = await CartService.loadLocalCartWithFullProducts();
      state = state.copyWith(items: items);
    }
  }

  /// Public method to handle auth changes called by the provider
  Future<void> handleAuthChange(UserProfile? oldUser, UserProfile? newUser) async {
    if (oldUser == null && newUser != null && newUser.supabaseId != null) {
      // Login detected
      await _mergeOnLogin(newUser.supabaseId!);
    } else if (oldUser != null && newUser == null) {
      // Logout detected
      final localItems = await CartService.loadLocalCartWithFullProducts();
      state = Cart(items: localItems);
    }
  }

  Future<void> _mergeOnLogin(String userId) async {
    final mergedItems = await CartService.mergeCartsOnLogin(userId, state.items);
    state = state.copyWith(items: mergedItems);
  }

  Future<void> _persist() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && profile.supabaseId != null) {
      await CartService.syncCartToDb(profile.supabaseId!, state.items);
    } else {
      await CartService.saveLocalCart(state.items);
    }
  }

  void addItem(Product product, {int quantity = 1}) => addToCart(product, quantity: quantity);

  void addToCart(Product product, {int quantity = 1}) {
    if (!product.inStock) return;

    final items = List<CartItem>.from(state.items);
    final existingIndex =
        items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final oldItem = items[existingIndex];
      final newQuantity = oldItem.quantity + quantity;
      
      // Validate against stock
      if (newQuantity > product.stockQuantity) {
        // Just cap at stock instead of returning if you want to be user-friendly, 
        // but the user-request implies we should show it's limited.
        items[existingIndex] = CartItem(
          product: oldItem.product,
          quantity: product.stockQuantity,
        );
      } else {
        items[existingIndex] = CartItem(
          product: oldItem.product,
          quantity: newQuantity,
        );
      }
    } else {
      final initialQuantity = quantity > product.stockQuantity ? product.stockQuantity : quantity;
      items.add(CartItem(product: product, quantity: initialQuantity));
    }

    state = state.copyWith(items: items);
    _persist();
  }

  void removeFromCart(int productId) {
    final items =
        state.items.where((item) => item.product.id != productId).toList();
    state = state.copyWith(items: items);
    _persist();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final product = items[index].product;
      final validatedQuantity = quantity > product.stockQuantity ? product.stockQuantity : quantity;
      
      items[index] = CartItem(
        product: product,
        quantity: validatedQuantity,
      );
      state = state.copyWith(items: items);
      _persist();
    }
  }

  void incrementQuantity(int productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final product = items[index].product;
      if (items[index].quantity < product.stockQuantity) {
        items[index] = CartItem(
          product: product,
          quantity: items[index].quantity + 1,
        );
        state = state.copyWith(items: items);
        _persist();
      }
    }
  }

  void decrementQuantity(int productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (items[index].quantity > 1) {
        items[index] = CartItem(
          product: items[index].product,
          quantity: items[index].quantity - 1,
        );
        state = state.copyWith(items: items);
        _persist();
      } else {
        removeFromCart(productId);
      }
    }
  }

  void clearCart() {
    state = const Cart();
    _persist();
  }

  void applyCoupon(String code, double discountAmount) {
    state = state.copyWith(
      couponCode: code,
      discountAmount: discountAmount,
    );
  }

  void removeCoupon() {
    state = state.copyWith(
      couponCode: null,
      discountAmount: 0,
    );
  }

  void updateShipping(double amount) {
    state = state.copyWith(shippingAmount: amount);
  }
}

