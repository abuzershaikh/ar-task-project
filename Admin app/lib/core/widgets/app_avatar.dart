import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../storage/local_avatar_cache.dart';
import '../theme/app_colors.dart';

/// Reusable avatar widget that displays Google/Gmail profile photos
/// with graceful caching and stylized fallback initials.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? userId;
  final String name;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Border? border;
  final bool isOnline;
  final bool showOnlineBadge;
  final IconData? fallbackIcon;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.userId,
    this.radius = 20,
    this.fontSize,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.isOnline = false,
    this.showOnlineBadge = false,
    this.fallbackIcon,
  });

  String _getInitial() {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    return clean[0].toUpperCase();
  }

  LinearGradient _generateGradient() {
    // Generate attractive distinctive color palettes based on name
    final hash = name.hashCode.abs();
    final palettes = [
      [const Color(0xFF0284C7), const Color(0xFF38BDF8)], // Sky blue
      [const Color(0xFF4F46E5), const Color(0xFF818CF8)], // Indigo
      [const Color(0xFF0D9488), const Color(0xFF2DD4BF)], // Teal
      [const Color(0xFF7C3AED), const Color(0xFFA78BFA)], // Violet
      [const Color(0xFFE11D48), const Color(0xFFFB7185)], // Rose
      [const Color(0xFFD97706), const Color(0xFFFBBF24)], // Amber
      [const Color(0xFF16A34A), const Color(0xFF4ADE80)], // Emerald
      [const Color(0xFF2563EB), const Color(0xFF60A5FA)], // Blue
    ];
    final selected = palettes[hash % palettes.length];
    return LinearGradient(
      colors: selected,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius;
    final size = effectiveRadius * 2;
    final initial = _getInitial();
    final effectiveFontSize = fontSize ?? (effectiveRadius * 0.85);

    String? candidateUrl = imageUrl;
    if ((candidateUrl == null || candidateUrl.trim().isEmpty) && userId != null && userId!.trim().isNotEmpty) {
      candidateUrl = LocalAvatarCache.getAvatarSync(userId);
    }

    final String? validUrl = (candidateUrl != null &&
            candidateUrl.trim().isNotEmpty &&
            (candidateUrl.startsWith('http://') || candidateUrl.startsWith('https://')))
        ? candidateUrl.trim()
        : null;

    if (validUrl != null && userId != null && userId!.trim().isNotEmpty) {
      LocalAvatarCache.saveAvatar(userId, validUrl);
    }

    Widget avatarContent;

    if (validUrl != null) {
      avatarContent = CachedNetworkImage(
        imageUrl: validUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.15),
            border: border,
          ),
          child: Center(
            child: SizedBox(
              width: effectiveRadius,
              height: effectiveRadius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackInitial(
          size,
          initial,
          effectiveFontSize,
        ),
      );
    } else {
      avatarContent = _buildFallbackInitial(size, initial, effectiveFontSize);
    }

    if (!showOnlineBadge) {
      return avatarContent;
    }

    return Stack(
      children: [
        avatarContent,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: effectiveRadius * 0.6,
            height: effectiveRadius * 0.6,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackInitial(double size, String initial, double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: backgroundColor == null ? _generateGradient() : null,
        color: backgroundColor,
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: fallbackIcon != null
            ? Icon(
                fallbackIcon,
                size: radius * 1.1,
                color: foregroundColor ?? Colors.white,
              )
            : Text(
                initial,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor ?? Colors.white,
                ),
              ),
      ),
    );
  }
}
