import 'category.dart';
export 'category.dart';

class Product {
  final int id;
  final String name;
  final String slug;
  final String? sku;
  final String? description;
  final String? shortDescription;
  final double price;
  final double? comparePrice;
  final String unit;
  final int stockQuantity;
  final String? imageMain;
  final int? categoryId;
  final bool isActive;
  final bool isFeatured;
  final bool isDeleted;
  final DateTime? createdAt;

  // Joined data
  final Category? category;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.sku,
    this.description,
    this.shortDescription,
    required this.price,
    this.comparePrice,
    this.unit = 'kg',
    this.stockQuantity = 0,
    this.imageMain,
    this.categoryId,
    this.isActive = true,
    this.isFeatured = false,
    this.isDeleted = false,
    this.createdAt,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      shortDescription: json['shortDescription'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comparePrice: (json['comparePrice'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      imageMain: json['imageMain'] as String?,
      categoryId: json['categoryId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      category: (json['Category'] ?? json['category']) != null
          ? Category.fromJson((json['Category'] ?? json['category']) as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'sku': sku,
        'description': description,
        'shortDescription': shortDescription,
        'price': price,
        'comparePrice': comparePrice,
        'unit': unit,
        'stockQuantity': stockQuantity,
        'imageMain': imageMain,
        'categoryId': categoryId,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'isDeleted': isDeleted,
      };

  bool get hasDiscount => comparePrice != null && comparePrice! > price;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((comparePrice! - price) / comparePrice! * 100).roundToDouble();
  }

  bool get inStock => stockQuantity > 0;

  String? get descriptionShort => shortDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}



