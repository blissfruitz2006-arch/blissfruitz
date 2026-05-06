import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';
import '../../../providers/blog_provider.dart';
import '../../../models/blog_post.dart';
import '../../../widgets/admin/admin_dialogs.dart';
import '../../../widgets/app_image.dart';

class BlogManagerScreen extends ConsumerWidget {
  const BlogManagerScreen({super.key});

  void _showBlogForm(BuildContext context, WidgetRef ref, [BlogPost? blog]) {
    showDialog(
      context: context,
      builder: (context) => BlogFormDialog(blog: blog, onSaved: () {
        ref.invalidate(adminBlogsProvider);
        ref.invalidate(blogPostsProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(adminBlogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Blog Manager', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBlogForm(context, ref),
          ),
        ],
      ),
      body: blogsAsync.when(
        data: (blogs) {
          if (blogs.isEmpty) return const Center(child: Text('No blog posts found'));
          return ListView.builder(
            itemCount: blogs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return Card(
                elevation: 0,
                color: AppTheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: AppImage(path: blog.coverImage ?? '', fit: BoxFit.cover),
                    ),
                  ),
                  title: Text(blog.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Author: ${blog.author ?? "Admin"} • ${blog.publishedAt?.toString().split(' ')[0] ?? "Not Published"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showBlogForm(context, ref, blog),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Blog Post?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await AdminService.deleteBlog(blog.id);
                            ref.invalidate(adminBlogsProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Error loading blogs: $e', textAlign: TextAlign.center),
              TextButton(onPressed: () => ref.invalidate(adminBlogsProvider), child: const Text('Retry')),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
