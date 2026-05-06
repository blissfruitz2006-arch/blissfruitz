class Offer {
  final int id;
  final String? title;
  final String? description;
  final String? couponCode;
  final String? imageUrl;
  final double discountValue;
  final bool isActive;
  final int sortOrder;
  final bool highlight;

  const Offer({
    required this.id,
    this.title,
    this.description,
    this.couponCode,
    this.imageUrl,
    this.discountValue = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.highlight = false,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
      couponCode: json['couponCode'] as String?,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sort_order'] ?? json['sortOrder']) as int? ?? 0,
      highlight: json['highlight'] as bool? ?? false,
    );
  }
}
