import 'package:flutter/material.dart';

class PropertyPost {
  const PropertyPost({
    required this.platform,
    required this.seller,
    required this.age,
    required this.title,
    required this.type,
    required this.deal,
    this.video = false,
    this.height = 130,
    this.color = const Color(0xFF8A7650),
    this.price = '',
    this.location = '',
    this.description = '',
    this.socialUrl = '',
    this.imagePaths = const [],
    this.isUserPost = false,
    this.sellerPhone = '',
    this.area = '',
    this.bedrooms = '',
    this.bathrooms = '',
    this.id,
  });

  final String platform, seller, age, title, type, deal;
  final bool video;
  final double height;
  final Color color;
  final String price, location, description, socialUrl;
  final String sellerPhone, area, bedrooms, bathrooms;
  final String? id;
  final List<String> imagePaths;
  final bool isUserPost;

  factory PropertyPost.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final imageUrls = json['imageUrls'] is List
        ? (json['imageUrls'] as List).whereType<String>().toList()
        : <String>[];
    if (imageUrls.isEmpty && json['imageUrl'] is String) {
      final imageUrl = json['imageUrl'] as String;
      if (imageUrl.isNotEmpty) imageUrls.add(imageUrl);
    }

    return PropertyPost(
      id: json['_id']?.toString(),
      platform: json['platform']?.toString() ?? 'PlotPost',
      seller: user['name']?.toString() ?? json['seller']?.toString() ?? 'PlotPost User',
      age: _relativeAge(json['createdAt']?.toString()),
      title: json['title']?.toString() ?? json['caption']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Plot',
      deal: json['deal']?.toString() ?? 'For sale',
      price: json['price']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      socialUrl: json['socialUrl']?.toString() ?? '',
      imagePaths: imageUrls,
      isUserPost: true,
      sellerPhone: json['sellerPhone']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      bedrooms: json['bedrooms']?.toString() ?? '',
      bathrooms: json['bathrooms']?.toString() ?? '',
    );
  }

  static String _relativeAge(String? createdAt) {
    final date = createdAt == null ? null : DateTime.tryParse(createdAt);
    if (date == null) return 'Just now';
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String get storageKey => id ?? '\u001f$platform\u001f$seller\u001f$title';

  /// Extracted seller initials for avatar display
  String get initials {
    final trimmed = seller.trim();
    if (trimmed.isEmpty) return 'P';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// First segment of location string before comma
  String get shortLocation {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return '';
    final idx = trimmed.indexOf(',');
    return idx == -1 ? trimmed : trimmed.substring(0, idx);
  }

  /// Pre-formatted search string for high-performance filtering
  String get searchableText {
    return '$title $type $deal $seller $platform $location'.toLowerCase();
  }
}
