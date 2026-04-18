import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': product.id,
        'quantity': quantity,
      };

  factory CartItem.fromJsonWithProduct(
      Map<String, dynamic> json, Product product) {
    return CartItem(
      product: product,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class Cart {
  final List<CartItem> items;
  final String? couponCode;
  final double discountAmount;
  final double shippingAmount;

  const Cart({
    this.items = const [],
    this.couponCode,
    this.discountAmount = 0,
    this.shippingAmount = 0,
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get total => subtotal - discountAmount + shippingAmount;

  Cart copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? discountAmount,
    double? shippingAmount,
  }) {
    return Cart(
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
    );
  }
}
