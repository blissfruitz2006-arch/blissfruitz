import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../widgets/scrollable_table_html_extension.dart';
import '../../providers/blog_provider.dart';
import '../../widgets/app_image.dart';
import '../../widgets/footer.dart';
import 'package:google_fonts/google_fonts.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String slug;

  const BlogDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogPostBySlugProvider(slug));

    return postAsync.when(
      data: (post) {
        if (post == null) {
          return const Center(child: Text('Blog post not found'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width > 640 ? 24 : 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.coverImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AppImage(
                              path: post.coverImage,
                              width: double.infinity,
                              height: MediaQuery.of(context).size.width > 640 ? 400 : 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          post.title,
                          style: GoogleFonts.outfit(
                            fontSize: MediaQuery.of(context).size.width > 640 ? 32 : 24,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (post.publishedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(post.publishedAt!),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        const Divider(height: 32),
                        if (post.content != null)
                          Html(
                            data: post.content!,
                            extensions: const [
                              ScrollableTableHtmlExtension(),
                            ],
                            style: {
                              'p': Style(
                                fontSize: FontSize(16),
                                lineHeight: const LineHeight(1.7),
                                margin: Margins.only(bottom: 16),
                              ),
                              'table': Style(
                                margin: Margins.only(top: 16, bottom: 16),
                                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white.withValues(alpha: 0.05) 
                                    : Colors.grey.shade50,
                              ),
                              'th': Style(
                                padding: HtmlPaddings.all(12),
                                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white12 
                                    : Colors.grey.shade100,
                                fontWeight: FontWeight.bold,
                                whiteSpace: WhiteSpace.pre,
                                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                              ),
                              'td': Style(
                                padding: HtmlPaddings.all(12),
                                whiteSpace: WhiteSpace.pre,
                                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200),
                              ),
                            },
                          ),
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
              ),
              const AppFooter(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
