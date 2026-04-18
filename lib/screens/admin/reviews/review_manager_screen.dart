import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';

class ReviewManagerScreen extends ConsumerWidget {
  const ReviewManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(adminReviewsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Customer Reviews', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) return const Center(child: Text('No reviews found'));
          return ListView.builder(
            itemCount: reviews.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                elevation: 0,
                color: AppTheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(5, (i) => Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: i < review.rating ? const Color(0xFFF59E0B) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            )),
                          ),
                          Row(
                            children: [
                              Text(
                                review.approved ? 'Approved' : 'Pending',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: review.approved ? AppTheme.primary : AppTheme.error,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: review.approved,
                                onChanged: (val) async {
                                  await AdminService.toggleReviewApproval(review.id, val);
                                  ref.invalidate(adminReviewsProvider);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.comment ?? 'No comment provided.',
                        style: GoogleFonts.beVietnamPro(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'By ${review.guestName ?? "Anonymous"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                            onPressed: () async {
                              await AdminService.deleteReview(review.id);
                              ref.invalidate(adminReviewsProvider);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
