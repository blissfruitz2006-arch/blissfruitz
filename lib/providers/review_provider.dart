import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

final productReviewsProvider =
    FutureProvider.family<List<Review>, int>((ref, productId) async {
  return ReviewService.getProductReviews(productId);
});

final averageRatingProvider =
    FutureProvider.family<double, int>((ref, productId) async {
  return ReviewService.getAverageRating(productId);
});
