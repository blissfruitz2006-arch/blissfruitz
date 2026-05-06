import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../providers/blog_provider.dart';
import '../../widgets/blog_card.dart';
import '../../widgets/footer.dart';
import '../../config/theme.dart';

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogs = ref.watch(blogPostsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1400) {
      crossAxisCount = 3;
      childAspectRatio = 0.85;
    } else if (screenWidth > 1000) {
      crossAxisCount = 2;
      childAspectRatio = 0.9;
    } else if (screenWidth > 600) {
      crossAxisCount = 1;
      childAspectRatio = 1.8;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.3;
    }

    return blogs.when(
      data: (posts) => CustomScrollView(
        slivers: [
          // Header / Hero Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BLISSFUL STORIES',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Our Latest\nArticles & Recipes',
                    style: GoogleFonts.outfit(
                      height: 1.1,
                      fontSize: screenWidth > 640 ? 44 : 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Discover the secrets to a healthier, blissful life through our curated stories.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blog Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return BlogCard(
                    post: post,
                    isHorizontal: crossAxisCount == 1,
                  );
                },
                childCount: posts.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: AppFooter()),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}


