import 'package:flutter/material.dart';

/// Renders authentic high-resolution platform and category icons
/// Uses official PNG asset icons copied from Buyer app
class PlatformLogo extends StatelessWidget {
  final String platform;
  final double size;

  const PlatformLogo({
    super.key,
    required this.platform,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final norm = platform.toLowerCase().trim();

    String? assetPath;

    if (norm.contains('app_install') || norm.contains('install') || norm.contains('smartphone')) {
      assetPath = 'assets/icons/smartphone.png';
    } else if (norm.contains('play') || norm.contains('playstore') || norm.contains('app_review')) {
      assetPath = 'assets/icons/google-play.png';
    } else if (norm.contains('youtube') || norm.contains('yt_')) {
      assetPath = 'assets/icons/youtube.png';
    } else if (norm.contains('instagram') || norm.contains('insta') || norm.contains('ig_')) {
      assetPath = 'assets/icons/instagram.png';
    } else if (norm.contains('rating') || norm.contains('star')) {
      assetPath = 'assets/icons/rating.png';
    } else if (norm.contains('review')) {
      assetPath = 'assets/icons/review.png';
    } else if (norm.contains('comment')) {
      assetPath = 'assets/icons/comment.png';
    } else if (norm.contains('sub')) {
      assetPath = 'assets/icons/subscribe.png';
    } else if (norm.contains('like')) {
      assetPath = 'assets/icons/like.png';
    } else if (norm.contains('google') || norm.contains('g_map') || norm.contains('maps')) {
      assetPath = 'assets/icons/google-play.png';
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(norm),
      );
    }

    return _fallbackIcon(norm);
  }

  Widget _fallbackIcon(String norm) {
    if (norm.contains('youtube')) {
      return Icon(Icons.play_circle_fill_rounded, color: const Color(0xFFFF0000), size: size);
    }
    if (norm.contains('play') || norm.contains('install')) {
      return Icon(Icons.play_arrow_rounded, color: const Color(0xFF00875A), size: size);
    }
    if (norm.contains('instagram')) {
      return Icon(Icons.camera_alt_rounded, color: const Color(0xFFE1306C), size: size);
    }
    return Icon(Icons.apps_rounded, size: size, color: const Color(0xFF00875A));
  }
}
