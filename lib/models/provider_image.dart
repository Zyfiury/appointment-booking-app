class ProviderImage {
  final String id;
  final String providerId;
  final String url;
  final String? caption;
  final String type; // 'gallery' | 'portfolio' | 'before_after'
  final int order;
  final String createdAt;

  ProviderImage({
    required this.id,
    required this.providerId,
    required this.url,
    this.caption,
    required this.type,
    required this.order,
    required this.createdAt,
  });

  factory ProviderImage.fromJson(Map<String, dynamic> json) {
    return ProviderImage(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      url: json['url'] ?? '',
      caption: json['caption'],
      type: json['type'] ?? 'gallery',
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'url': url,
      'caption': caption,
      'type': type,
      'order': order,
      'createdAt': createdAt,
    };
  }
}
