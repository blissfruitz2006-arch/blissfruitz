class Review {
  final int id;
  final int productId;
  final int? userId;
  final String? guestName;
  final int rating;
  final String? title;
  final String? comment;
  final bool approved;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.productId,
    this.userId,
    this.guestName,
    required this.rating,
    this.title,
    this.comment,
    this.approved = false,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      productId: json['productId'] as int? ?? 0,
      userId: json['userId'] as int?,
      guestName: json['guestName'] as String?,
      rating: json['rating'] as int? ?? 5,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      approved: json['approved'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
