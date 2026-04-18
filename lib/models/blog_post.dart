class BlogPost {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? coverImage;
  final String? author;
  final DateTime? publishedAt;
  final bool isPublished;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    this.coverImage,
    this.author,
    this.publishedAt,
    this.isPublished = true,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      excerpt: json['excerpt'] as String?,
      content: json['content'] as String?,
      coverImage: json['coverImage'] as String?,
      author: json['author'] as String?,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      isPublished: json['isPublished'] as bool? ?? true,
    );
  }
}
