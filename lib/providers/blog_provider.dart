import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';

final blogPostsProvider = FutureProvider<List<BlogPost>>((ref) async {
  return BlogService.getPosts();
});

final blogPostBySlugProvider =
    FutureProvider.family<BlogPost?, String>((ref, slug) async {
  return BlogService.getPostBySlug(slug);
});
