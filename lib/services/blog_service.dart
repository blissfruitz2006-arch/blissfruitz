import '../config/supabase_config.dart';
import '../models/blog_post.dart';

class BlogService {
  static final _client = SupabaseConfig.client;

  static Future<List<BlogPost>> getPosts({int limit = 10}) async {
    final data = await _client
        .from('BlogPost')
        .select()
        .eq('isPublished', true)
        .order('publishedAt', ascending: false)
        .limit(limit);

    return (data as List).map((e) => BlogPost.fromJson(e)).toList();
  }

  static Future<BlogPost?> getPostBySlug(String slug) async {
    final data = await _client
        .from('BlogPost')
        .select()
        .eq('slug', slug)
        .eq('isPublished', true)
        .maybeSingle();

    if (data == null) return null;
    return BlogPost.fromJson(data);
  }
}
