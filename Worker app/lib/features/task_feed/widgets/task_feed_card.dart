import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/platform_logo.dart';

/// Clean Task Feed Card matching the screenshot UI:
/// - Platform logo in rounded container on left
/// - Title & Subtitle + Easy / Duration tags
/// - + ₹X reward pill & Green "Start" pill button
class TaskFeedCard extends StatefulWidget {
  final dynamic task;
  final VoidCallback onTap;
  final int index;

  const TaskFeedCard({
    super.key,
    required this.task,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<TaskFeedCard> createState() => _TaskFeedCardState();
}

class _TaskFeedCardState extends State<TaskFeedCard> {
  double _scale = 1.0;

  String _formatTitle(dynamic task) {
    if (task == null) return 'Task';

    final isInstall = _isAppInstall(task);

    final plat = _getPlatform(task);

    // Check for business name first for Google Business / Maps tasks
    if (plat == 'google_business' ||
        plat == 'google_maps' ||
        plat == 'google') {
      String? bName;
      if (task['businessName'] != null &&
          task['businessName'].toString().trim().isNotEmpty) {
        bName = task['businessName'].toString().trim();
      } else if (task['requirements'] is Map &&
          task['requirements']['businessName'] != null &&
          task['requirements']['businessName'].toString().trim().isNotEmpty) {
        bName = task['requirements']['businessName'].toString().trim();
      } else if (task['appName'] != null &&
          task['appName'].toString().trim().isNotEmpty) {
        bName = task['appName'].toString().trim();
      } else if (task['requirements'] is Map &&
          task['requirements']['appName'] != null &&
          task['requirements']['appName'].toString().trim().isNotEmpty) {
        bName = task['requirements']['appName'].toString().trim();
      }
      if (bName != null && bName.isNotEmpty) {
        return 'Rate & Review: $bName';
      }
    }

    // 1. Extract app name if available
    String? appName;
    if (task['appName'] != null &&
        task['appName'].toString().trim().isNotEmpty) {
      appName = task['appName'].toString().trim();
    } else if (task['requirements'] is Map &&
        task['requirements']['appName'] != null &&
        task['requirements']['appName'].toString().trim().isNotEmpty) {
      appName = task['requirements']['appName'].toString().trim();
    } else if (task['metadata'] is Map &&
        task['metadata']['appName'] != null &&
        task['metadata']['appName'].toString().trim().isNotEmpty) {
      appName = task['metadata']['appName'].toString().trim();
    }

    if (appName != null && appName.isNotEmpty) {
      if (isInstall) {
        return 'Install & Open: $appName';
      }
      if (plat == 'youtube') {
        return 'Watch & Engage: $appName';
      }
      if (plat == 'instagram') {
        return 'Engage: $appName';
      }
      return 'Rate & Review: $appName';
    }

    if (task['title'] != null && task['title'].toString().trim().isNotEmpty) {
      return task['title'].toString().trim();
    }
    if (task['serviceTitle'] != null &&
        task['serviceTitle'].toString().trim().isNotEmpty) {
      return task['serviceTitle'].toString().trim();
    }
    if (task['requirements'] != null && task['requirements'] is Map) {
      final req = task['requirements'] as Map;
      if (req['serviceName'] != null &&
          req['serviceName'].toString().trim().isNotEmpty) {
        return req['serviceName'].toString().trim();
      }
      if (req['title'] != null && req['title'].toString().trim().isNotEmpty) {
        return req['title'].toString().trim();
      }
      if (req['serviceTitle'] != null &&
          req['serviceTitle'].toString().trim().isNotEmpty) {
        return req['serviceTitle'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('heading') ||
                k.contains('title') ||
                k.contains('name')) &&
            v.isNotEmpty) {
          return v;
        }
      }
    }
    if (task['metadata'] != null && task['metadata'] is Map) {
      final meta = task['metadata'] as Map;
      if (meta['serviceName'] != null &&
          meta['serviceName'].toString().trim().isNotEmpty) {
        return meta['serviceName'].toString().trim();
      }
      if (meta['title'] != null && meta['title'].toString().trim().isNotEmpty) {
        return meta['title'].toString().trim();
      }
      if (meta['serviceTitle'] != null &&
          meta['serviceTitle'].toString().trim().isNotEmpty) {
        return meta['serviceTitle'].toString().trim();
      }
    }
    final rawType = (task['taskType'] ?? task['type'] ?? 'Task').toString();
    if (isInstall) return 'Install & Open App';
    if (plat == 'google_business' ||
        plat == 'google_maps' ||
        plat == 'google') {
      final rtLower = rawType.toLowerCase();
      if (rtLower.contains('review')) return '5-Star Google Business Review';
      return '5-Star Google Rating';
    }
    if (plat == 'playstore') return '5-Star Rating & Review';
    if (plat == 'youtube') {
      final rtLower = rawType.toLowerCase();
      if (rtLower.contains('combo')) return 'Like, Sub & Comment on YouTube';
      if (rtLower.contains('sub')) return 'Subscribe on YouTube';
      if (rtLower.contains('comment')) return 'Comment on YouTube';
      if (rtLower.contains('like')) return 'Like YouTube Video';
      return 'Like & Comment on YouTube';
    }
    if (plat == 'instagram') {
      final rtLower = rawType.toLowerCase();
      if (rtLower.contains('combo')) {
        return 'Like, Follow & Comment on Instagram';
      }
      if (rtLower.contains('like')) {
        return 'Like Instagram Post / Reel';
      }
      if (rtLower.contains('comment')) {
        return 'Comment on Instagram Post';
      }
      return 'Follow on Instagram';
    }
    if (plat == 'x') return 'Follow & Repost on X';

    if (rawType.toUpperCase().startsWith('SERVICE_') ||
        rawType.toUpperCase().startsWith('SRV_')) {
      return '${plat[0].toUpperCase()}${plat.substring(1)} Promotion Task';
    }
    return rawType
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool _isAppInstall(dynamic task) {
    if (task == null) return false;
    final type = (task['taskType'] ?? task['type'] ?? task['serviceCode'] ?? '')
        .toString()
        .toLowerCase();
    String reqStr = '';
    if (task['requirements'] is Map) {
      reqStr = task['requirements'].toString().toLowerCase();
    }
    final titleStr =
        (task['title'] ?? task['serviceTitle'] ?? task['serviceName'] ?? '')
            .toString()
            .toLowerCase();
    final combined = '$type $reqStr $titleStr';
    return type.contains('install') ||
        combined.contains('install & open') ||
        combined.contains('app install');
  }

  String _getSubtitle(dynamic task, String platform) {
    if (_isAppInstall(task)) {
      return 'Install App & Open for 30 Seconds';
    }
    if (platform == 'google_business' ||
        platform == 'google_maps' ||
        platform == 'google') {
      return '5-Star Google Maps Review';
    }
    if (platform == 'playstore') {
      return '5-Star Google Play Store Review';
    }
    if (platform == 'youtube') {
      return 'Watch, Like, Sub & Comment';
    }
    if (platform == 'instagram') {
      return 'Like Post & Follow Creator';
    }
    if (task != null &&
        task['description'] != null &&
        task['description'].toString().trim().isNotEmpty) {
      final desc = task['description'].toString().trim();
      if (desc.length <= 35) return desc;
      return '${desc.substring(0, 32)}...';
    }
    if (task != null &&
        task['category'] != null &&
        task['category'].toString().trim().isNotEmpty) {
      return task['category'].toString().trim();
    }
    switch (platform) {
      case 'google_business':
      case 'google_maps':
        return 'Rate & Review on Google Maps';
      case 'google':
      case 'playstore':
        return '5-Star App Review & Rating';
      case 'youtube':
        return 'Engage with videos';
      case 'facebook':
        return 'Stay updated';
      case 'instagram':
        return 'Support the creator';
      case 'x':
        return 'Follow & engage';
      default:
        return 'Complete simple actions';
    }
  }

  String? _getAppIcon(dynamic task) {
    if (task == null) return null;
    final platform = _getPlatform(task);
    String? raw;
    if (task['appIcon'] != null &&
        task['appIcon'].toString().trim().isNotEmpty) {
      raw = task['appIcon'].toString().trim();
    } else if (task['requirements'] is Map) {
      final req = task['requirements'] as Map;
      if (req['appIcon'] != null &&
          req['appIcon'].toString().trim().isNotEmpty) {
        raw = req['appIcon'].toString().trim();
      } else if (req['icon'] != null &&
          req['icon'].toString().trim().isNotEmpty) {
        raw = req['icon'].toString().trim();
      }
    } else if (task['metadata'] is Map) {
      final meta = task['metadata'] as Map;
      if (meta['appIcon'] != null &&
          meta['appIcon'].toString().trim().isNotEmpty) {
        raw = meta['appIcon'].toString().trim();
      } else if (meta['icon'] != null &&
          meta['icon'].toString().trim().isNotEmpty) {
        raw = meta['icon'].toString().trim();
      }
    }
    if (raw != null && raw.isNotEmpty) {
      if (platform == 'playstore' && raw.contains('instagram')) {
        return null;
      }
      return raw;
    }
    return null;
  }

  String _getDuration(dynamic task, String platform) {
    if (platform == 'google_business' ||
        platform == 'google_maps' ||
        platform == 'google' ||
        platform == 'playstore') {
      return '~ 2 Min';
    }
    return '~ 1 Min';
  }

  String _getPlatform(dynamic task) {
    if (task == null) return 'general';
    final type =
        (task['taskType'] ??
                task['task_type'] ??
                task['type'] ??
                task['serviceCode'] ??
                '')
            .toString()
            .toLowerCase();
    String reqStr = '';
    if (task['requirements'] is Map) {
      reqStr = task['requirements'].toString().toLowerCase();
    }
    final titleStr =
        (task['title'] ??
                task['serviceTitle'] ??
                task['serviceName'] ??
                (task['requirements'] is Map
                    ? (task['requirements']['serviceName'] ??
                          task['requirements']['title'])
                    : null) ??
                '')
            .toString()
            .toLowerCase();
    final urlStr =
        (task['targetUrl'] ??
                task['url'] ??
                (task['requirements'] is Map
                    ? task['requirements']['targetUrl']
                    : null) ??
                '')
            .toString()
            .toLowerCase();
    final combined = '$type $reqStr $titleStr $urlStr';

    // 0. Google Business / Maps
    if (type.contains('google_business') ||
        type.contains('google_maps') ||
        type.contains('gmb') ||
        type.contains('map') ||
        combined.contains('google business') ||
        combined.contains('google maps') ||
        combined.contains('share.google') ||
        combined.contains('maps.google') ||
        combined.contains('goo.gl/maps') ||
        combined.contains('maps.app.goo.gl') ||
        combined.contains('gmb')) {
      return 'google_maps';
    }

    // 1. App Install & Play Store takes priority over raw platform tag
    if (type.contains('app_install') ||
        (type.contains('install') && !type.contains('instagram')) ||
        combined.contains('install & open') ||
        combined.contains('app install') ||
        combined.contains('playstore') ||
        combined.contains('play.google')) {
      return 'playstore';
    }
    // 2. YouTube
    if (type.contains('youtube') ||
        combined.contains('youtube') ||
        type.contains('yt_')) {
      return 'youtube';
    }
    // 3. Instagram (Strict check: ensure not install)
    if (type.contains('instagram') ||
        combined.contains('instagram') ||
        (combined.contains('insta') && !combined.contains('install'))) {
      return 'instagram';
    }
    // 4. Google Maps fallback
    if (type.contains('google') ||
        combined.contains('g_map') ||
        combined.contains('maps') ||
        combined.contains('share.google')) {
      return 'google_maps';
    }

    if (task['platform'] != null &&
        task['platform'].toString().trim().isNotEmpty) {
      final p = task['platform'].toString().toLowerCase().trim();
      if (p == 'google' ||
          p == 'google_business' ||
          p == 'google_maps' ||
          p == 'maps') {
        return 'google_maps';
      }
      if (p != 'general') {
        return p;
      }
    }

    return 'google_maps';
  }

  String _getReward(dynamic task) {
    if (task == null) return '5';
    final raw =
        task['rewardAmount'] ??
        task['rewardPerTask'] ??
        task['reward'] ??
        task['workerReward'] ??
        task['payout'];
    if (raw is num) {
      return raw.toStringAsFixed(raw == raw.roundToDouble() ? 0 : 2);
    }
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null) {
        return parsed.toStringAsFixed(parsed == parsed.roundToDouble() ? 0 : 2);
      }
    }
    if (task['metadata'] is Map &&
        (task['metadata'] as Map)['rewardSnapshot'] is Map) {
      final snap = (task['metadata'] as Map)['rewardSnapshot'] as Map;
      final tot = snap['totalReward'] ?? snap['baseReward'];
      if (tot != null) {
        final parsed = double.tryParse(tot.toString());
        if (parsed != null) {
          return parsed.toStringAsFixed(
            parsed == parsed.roundToDouble() ? 0 : 2,
          );
        }
      }
    }
    return '5';
  }

  int get _biomeIndex => widget.index % 8;

  String _getCardBoardSvg() {
    switch (_biomeIndex) {
      case 1:
        return 'assets/svg/card_theme_water.svg';
      case 2:
        return 'assets/svg/card_theme_amethyst.svg';
      case 3:
        return 'assets/svg/card_theme_ruby.svg';
      case 4:
        return 'assets/svg/card_theme_emerald.svg';
      case 5:
        return 'assets/svg/card_theme_gold.svg';
      case 6:
        return 'assets/svg/card_theme_cyber.svg';
      case 7:
        return 'assets/svg/card_theme_obsidian.svg';
      case 0:
      default:
        return 'assets/svg/card_theme_wood.svg';
    }
  }

  Color _getSubtitleColor() {
    switch (_biomeIndex) {
      case 1:
        return const Color(0xFFBAE6FD);
      case 2:
        return const Color(0xFFF5D0FE);
      case 3:
        return const Color(0xFFFECDD3);
      case 4:
        return const Color(0xFFA7F3D0);
      case 5:
        return const Color(0xFFFEF08A);
      case 6:
        return const Color(0xFFBFDBFE);
      case 7:
        return const Color(0xFFE2E8F0);
      case 0:
      default:
        return const Color(0xFFFFF0D4);
    }
  }

  String _getTileSvg(String platform) {
    if (platform == 'youtube') {
      if (_biomeIndex == 1) return 'assets/svg/tile_water_youtube.svg';
      if (_biomeIndex == 2) return 'assets/svg/tile_amethyst_youtube.svg';
      return 'assets/svg/tile_youtube.svg';
    }
    switch (platform) {
      case 'instagram':
        return 'assets/svg/tile_instagram.svg';
      case 'telegram':
        return 'assets/svg/tile_telegram.svg';
      case 'google_maps':
      case 'google_business':
      case 'google':
        return 'assets/svg/tile_google_maps.svg';
      case 'playstore':
      case 'app_install':
        return 'assets/svg/tile_playstore.svg';
      case 'x':
      case 'twitter':
        return 'assets/svg/tile_x.svg';
      default:
        return 'assets/svg/tile_youtube.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatTitle(widget.task);
    final platform = _getPlatform(widget.task);
    final subtitle = _getSubtitle(widget.task, platform);
    final duration = _getDuration(widget.task, platform);
    final reward = _getReward(widget.task);
    final appIcon = _getAppIcon(widget.task);
    final hasCustomAppIcon =
        appIcon != null &&
        appIcon.isNotEmpty &&
        platform != 'google_maps' &&
        platform != 'google_business' &&
        platform != 'google';
    final tileSvg = hasCustomAppIcon
        ? 'assets/svg/tile_app_frame.svg'
        : _getTileSvg(platform);
    final cardBoardSvg = _getCardBoardSvg();

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => setState(() => _scale = 0.975),
            onTapUp: (_) {
              setState(() => _scale = 1.0);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _scale = 1.0),
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.amber.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── 1. Themed Biome Board SVG Frame ──
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SvgPicture.asset(
                      cardBoardSvg,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

              // ── 2. Card Interactive Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Modular Platform Tile on the Left ──
                    SizedBox(
                      width: 72,
                      height: 98,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            tileSvg,
                            width: 72,
                            height: 98,
                            fit: BoxFit.contain,
                          ),
                          if (hasCustomAppIcon)
                            Positioned(
                              top: 36,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    appIcon,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            PlatformLogo(
                                              platform: platform,
                                              size: 28,
                                            ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── Middle Column: Title, Subtitle, Badges ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Title with double shadow for 100% legibility on wood
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.0,
                                height: 1.18,
                                letterSpacing: 0.2,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF000000),
                                    offset: Offset(1.2, 1.2),
                                    blurRadius: 0,
                                  ),
                                  Shadow(
                                    color: Color(0xFF2E1405),
                                    offset: Offset(-0.8, -0.8),
                                    blurRadius: 0,
                                  ),
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),

                            // Subtitle in warm creamy gold / cyan / lavender depending on biome
                            Text(
                              subtitle,
                              style: GoogleFonts.poppins(
                                color: _getSubtitleColor(),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF2E1405),
                                    offset: Offset(1, 1),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Badges Row
                            Row(
                              children: [
                                // Easy Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF148F32),
                                        Color(0xFF084E18),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF23D950),
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        color: Color(0xFFFFE600),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Easy',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Duration Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF0D7C8F),
                                        Color(0xFF063E48),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1DD9FA),
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time_filled_rounded,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        duration,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── Right Column: Reward Pill & 3D Start Button ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Golden Rupee Reward Pill
                        Container(
                          padding: const EdgeInsets.fromLTRB(4, 2.5, 9, 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF693005), Color(0xFF3D1801)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFC77D22),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 3D Golden Coin
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFFF066),
                                      Color(0xFFFFB800),
                                      Color(0xFFD97700),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFFF59E),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF4A2500),
                                      offset: Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '₹',
                                    style: TextStyle(
                                      color: Color(0xFF693005),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '+$reward',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFFDA66),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF291100),
                                      offset: Offset(1, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 3D Glossy Green Start Button
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF3DF577),
                                  Color(0xFF00D04E),
                                  Color(0xFF009432),
                                  Color(0xFF006622),
                                ],
                                stops: [0.0, 0.35, 0.85, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF6BFF9A),
                                width: 1.8,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF004D1A),
                                  offset: Offset(0, 2.5),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 3.5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Start',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0xFF003813),
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
