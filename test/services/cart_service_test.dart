import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blissfruitz/services/cart_service.dart';
import 'package:blissfruitz/models/product.dart';
import 'package:blissfruitz/models/cart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartService Local Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Local cart starts empty', () async {
      final cart = await CartService.loadLocalCart();
      expect(cart, isEmpty);
    });

    test('Can save and load local cart items', () async {
      final testProduct = Product(
        id: 1,
        name: 'Test Apple',
        slug: 'test-apple',
        price: 100,
      );

      final items = [
        CartItem(product: testProduct, quantity: 2),
      ];

      await CartService.saveLocalCart(items);

      final loaded = await CartService.loadLocalCart();
      expect(loaded.length, 1);
      expect(loaded.first['productId'], 1);
      expect(loaded.first['quantity'], 2);
    });

    test('Can clear local cart', () async {
      final testProduct = Product(
        id: 1,
        name: 'Test Apple',
        slug: 'test-apple',
        price: 100,
      );

      final items = [
        CartItem(product: testProduct, quantity: 2),
      ];

      await CartService.saveLocalCart(items);
      await CartService.clearLocalCart();

      final loaded = await CartService.loadLocalCart();
      expect(loaded, isEmpty);
    });
  });
}
