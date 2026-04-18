import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/cart_service.dart';
import 'auth_provider.dart';

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<Cart> {
  final Ref ref;

  CartNotifier(this.ref) : super(const Cart()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Initial check if already logged in
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      final items = await CartService.loadCartFromDb(profile.id);
      state = state.copyWith(items: items);
    } else {
      // Load local if guest
      final items = await CartService.loadLocalCartWithFullProducts();
      state = state.copyWith(items: items);
    }

    // 2. Watch for login/logout
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) async {
      final oldUser = previous?.valueOrNull;
      final newUser = next.valueOrNull;

      if (oldUser == null && newUser != null) {
        // Login detected
        await _mergeOnLogin(newUser.id);
      } else if (oldUser != null && newUser == null) {
        // Logout detected - Restore local guest cart instead of clearing
        final localItems = await CartService.loadLocalCartWithFullProducts();
        state = Cart(items: localItems);
      }
    });
  }

  Future<void> _mergeOnLogin(int userId) async {
    final mergedItems = await CartService.mergeCartsOnLogin(userId, state.items);
    state = state.copyWith(items: mergedItems);
  }

  Future<void> _persist() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      await CartService.syncCartToDb(profile.id, state.items);
    } else {
      await CartService.saveLocalCart(state.items);
    }
  }

  void addItem(Product product, {int quantity = 1}) => addToCart(product, quantity: quantity);

  void addToCart(Product product, {int quantity = 1}) {
    final items = List<CartItem>.from(state.items);
    final existingIndex =
        items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Create new list to ensure state update is detected
      final oldItem = items[existingIndex];
      items[existingIndex] = CartItem(
        product: oldItem.product,
        quantity: oldItem.quantity + quantity,
      );
    } else {
      items.add(CartItem(product: product, quantity: quantity));
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
      items[index] = CartItem(
        product: items[index].product,
        quantity: quantity,
      );
      state = state.copyWith(items: items);
      _persist();
    }
  }

  void incrementQuantity(int productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      items[index] = CartItem(
        product: items[index].product,
        quantity: items[index].quantity + 1,
      );
      state = state.copyWith(items: items);
      _persist();
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

