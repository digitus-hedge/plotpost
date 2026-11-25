import 'package:flutter/material.dart';

/// Helper providing accurate, domain-specific icons for Real Estate properties,
/// deal categories, amenities, social actions, custom image icons, and listing platforms.
class PropertyIconHelper {
  /// Returns custom Image.asset for comment icon (`assets/comment.png`)
  static Widget commentImageAsset({
    double size = 22,
    Color? color,
  }) {
    return Image.asset(
      'assets/comment.png',
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
    );
  }

  /// Returns custom Image.asset for share icon (`assets/share.png`)
  static Widget shareImageAsset({
    double size = 22,
    Color? color,
  }) {
    return Image.asset(
      'assets/share.png',
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
    );
  }

  /// Returns the most accurate icon for a given property type (Plot, Villa, Flat, House, Commercial).
  static IconData getPropertyTypeIcon(String? type) {
    if (type == null || type.trim().isEmpty) return Icons.real_estate_agent_rounded;
    final normalized = type.trim().toLowerCase();

    if (normalized.contains('plot') || normalized.contains('land')) {
      return Icons.landscape_rounded;
    } else if (normalized.contains('villa')) {
      return Icons.villa_rounded;
    } else if (normalized.contains('flat') || normalized.contains('apartment')) {
      return Icons.apartment_rounded;
    } else if (normalized.contains('house') || normalized.contains('home')) {
      return Icons.cottage_rounded;
    } else if (normalized.contains('commercial') || normalized.contains('office') || normalized.contains('shop')) {
      return Icons.storefront_rounded;
    } else if (normalized.contains('warehouse') || normalized.contains('godown')) {
      return Icons.warehouse_rounded;
    }
    return Icons.home_work_rounded;
  }

  /// Returns the accurate icon for deal categories (For Sale, For Rent, Lease).
  static IconData getDealIcon(String? deal) {
    if (deal == null) return Icons.sell_rounded;
    final normalized = deal.trim().toLowerCase();

    if (normalized.contains('rent')) {
      return Icons.key_rounded;
    } else if (normalized.contains('lease')) {
      return Icons.handshake_rounded;
    } else if (normalized.contains('sale') || normalized.contains('buy')) {
      return Icons.sell_rounded;
    }
    return Icons.local_offer_rounded;
  }

  /// Returns the accurate icon for social & listing platforms (Instagram, YouTube, Facebook, WhatsApp, PlotPost).
  static IconData getPlatformIcon(String? platform) {
    if (platform == null) return Icons.public_rounded;
    final normalized = platform.trim().toLowerCase();

    if (normalized.contains('instagram')) {
      return Icons.camera_alt_rounded;
    } else if (normalized.contains('youtube')) {
      return Icons.play_circle_fill_rounded;
    } else if (normalized.contains('facebook')) {
      return Icons.groups_rounded;
    } else if (normalized.contains('whatsapp')) {
      return Icons.chat_rounded;
    } else if (normalized.contains('plotpost')) {
      return Icons.verified_rounded;
    }
    return Icons.language_rounded;
  }

  /// Accurate social action icons
  static const IconData commentIcon = Icons.mode_comment_outlined;
  static const IconData commentFilledIcon = Icons.mode_comment_rounded;
  static const IconData shareIcon = Icons.ios_share_rounded;
  static const IconData shareNetworkIcon = Icons.share_rounded;

  /// Accurate feature icons for property details (Bedrooms, Bathrooms, Area, Price, Location, Age).
  static const IconData areaIcon = Icons.aspect_ratio_rounded;
  static const IconData bedroomIcon = Icons.bed_rounded;
  static const IconData bathroomIcon = Icons.bathtub_rounded;
  static const IconData locationIcon = Icons.location_on_rounded;
  static const IconData priceIcon = Icons.payments_rounded;
  static const IconData phoneIcon = Icons.phone_in_talk_rounded;
  static const IconData chatIcon = Icons.chat_bubble_rounded;
  static const IconData verifiedIcon = Icons.verified_user_rounded;
  static const IconData ageIcon = Icons.schedule_rounded;
}
