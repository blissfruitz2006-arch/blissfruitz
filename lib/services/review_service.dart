import '../config/supabase_config.dart';
import '../models/review.dart';

class ReviewService {
  static final _client = SupabaseConfig.client;

  /// Get approved reviews for a product
  static Future<List<Review>> getProductReviews(int productId) async {
    final data = await _client
        .from('Review')
        .select()
        .eq('productId', productId)
        .eq('approved', true)
        .order('createdAt', ascending: false);

    return (data as List).map((e) => Review.fromJson(e)).toList();
  }

  /// Submit a new review
  static Future<Review> submitReview({
    required int productId,
    int? userId,
    String? guestName,
    required int rating,
    String? title,
    required String comment,
  }) async {
    final data = await _client
        .from('Review')
        .insert({
          'productId': productId,
          'userId': ?userId,
          'guestName': ?guestName,
          'rating': rating,
          'title': ?title,
          'comment': comment,
          'approved': false, // Requires admin approval
        })
        .select()
        .single();

    return Review.fromJson(data);
  }

  /// Get the average rating for a product
  static Future<double> getAverageRating(int productId) async {
    final data = await _client
        .from('Review')
        .select('rating')
        .eq('productId', productId)
        .eq('approved', true);

    final reviews = data as List;
    if (reviews.isEmpty) return 0;

    final totalRating =
        reviews.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
    return totalRating / reviews.length;
  }

  /// Get reviews submitted by a specific user
  static Future<List<Review>> getUserReviews(int userId) async {
    final data = await _client
        .from('Review')
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false);

    return (data as List).map((e) => Review.fromJson(e)).toList();
  }

  /// Check if user has already reviewed a product
  static Future<bool> hasUserReviewed({
    required int productId,
    required int userId,
  }) async {
    final data = await _client
        .from('Review')
        .select('id')
        .eq('productId', productId)
        .eq('userId', userId)
        .maybeSingle();

    return data != null;
  }
}
