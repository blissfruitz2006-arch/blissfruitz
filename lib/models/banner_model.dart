class BannerModel {
  final int id;
  final String placement;
  final String? title;
  final String? subtitle;
  final String? linkUrl;
  final String? imagePath;
  final int sortOrder;
  final bool isActive;

  const BannerModel({
    required this.id,
    this.placement = 'hero',
    this.title,
    this.subtitle,
    this.linkUrl,
    this.imagePath,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      placement: json['placement'] as String? ?? 'hero',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      linkUrl: json['linkUrl'] as String?,
      imagePath: json['imagePath'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
