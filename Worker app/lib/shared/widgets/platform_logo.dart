import 'package:flutter/material.dart';

/// Renders authentic vector-style platform logos (Google, YouTube, Instagram, Facebook, X)
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
    final norm = platform.toLowerCase();
    if (norm.contains('google')) {
      return _buildGoogleLogo(size);
    } else if (norm.contains('youtube')) {
      return _buildYouTubeLogo(size);
    } else if (norm.contains('instagram')) {
      return _buildInstagramLogo(size);
    } else if (norm.contains('facebook')) {
      return _buildFacebookLogo(size);
    } else if (norm.contains('x') || norm.contains('twitter')) {
      return _buildXLogo(size);
    }

    return Icon(Icons.apps_rounded, size: size, color: const Color(0xFF00875A));
  }

  static Widget _buildGoogleLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _GoogleGPainter(),
        ),
      ),
    );
  }

  static Widget _buildYouTubeLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0000).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.65,
        ),
      ),
    );
  }

  static Widget _buildInstagramLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF833AB4), // Purple
            Color(0xFFFD1D1D), // Red
            Color(0xFFF77737), // Orange
            Color(0xFFFFDC80), // Yellow
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE1306C).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.52,
          height: size * 0.52,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2.2),
            borderRadius: BorderRadius.circular(size * 0.16),
          ),
          child: Center(
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildFacebookLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.65,
            fontFamily: 'sans-serif',
            height: 1.1,
          ),
        ),
      ),
    );
  }

  static Widget _buildXLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '𝕏',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.55,
          ),
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Top Red arc
    canvas.drawArc(rect, -2.35, 1.25, true, redPaint);
    // Bottom Yellow arc
    canvas.drawArc(rect, 2.35, 0.8, true, yellowPaint);
    // Bottom Green arc
    canvas.drawArc(rect, 0.5, 1.85, true, greenPaint);
    // Blue bar & arc
    canvas.drawArc(rect, -1.1, 1.6, true, bluePaint);

    // Inner cutout
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // Blue horizontal arm
    final armPath = Path()
      ..moveTo(center.dx, center.dy - radius * 0.22)
      ..lineTo(center.dx + radius, center.dy - radius * 0.22)
      ..lineTo(center.dx + radius, center.dy + radius * 0.22)
      ..lineTo(center.dx, center.dy + radius * 0.22)
      ..close();
    canvas.drawPath(armPath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
