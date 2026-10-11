import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/platform_logo.dart';

/// Clean Task Feed Card matching the screenshot UI:
/// - Platform logo in rounded container on left
/// - Title & Subtitle + Easy / Duration tags
/// - + ₹X reward pill & Green "Start" pill button
class TaskFeedCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;

  const TaskFeedCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  String _formatTitle(dynamic task) {
    if (task == null) return 'Task';

    final isInstall = _isAppInstall(task);

    final plat = _getPlatform(task);

    // Check for business name first for Google Business / Maps tasks
    if (plat == 'google_business' || plat == 'google_maps' || plat == 'google') {
      String? bName;
      if (task['businessName'] != null && task['businessName'].toString().trim().isNotEmpty) {
        bName = task['businessName'].toString().trim();
      } else if (task['requirements'] is Map &&
          task['requirements']['businessName'] != null &&
          task['requirements']['businessName'].toString().trim().isNotEmpty) {
        bName = task['requirements']['businessName'].toString().trim();
      } else if (task['appName'] != null && task['appName'].toString().trim().isNotEmpty) {
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
    if (task['appName'] != null && task['appName'].toString().trim().isNotEmpty) {
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

    if (plat == 'youtube') {
      final rawType = (task['taskType'] ?? task['task_type'] ?? task['type'] ?? task['serviceCode'] ?? '').toString().toLowerCase();
      final reqStr = (task['requirements'] != null) ? task['requirements'].toString().toLowerCase() : '';
      final titleStr = (task['title'] ?? task['serviceTitle'] ?? '').toString().toLowerCase();
      final combined = '$rawType $reqStr $titleStr';
      final isCombo = combined.contains('combo');
      final isSub = !isCombo && (combined.contains('sub') || combined.contains('channel'));
      final isComment = !isCombo && combined.contains('comment');
      final isLike = !isCombo && combined.contains('like');

      if (isCombo) return 'Watch, Like, Sub & Comment';
      if (isSub) return 'Watch & Subscribe Channel';
      if (isLike) return 'Watch & Like Video';
      if (isComment) return 'Watch & Comment on Video';
      return 'Watch & Engage on YouTube';
    }

    if (appName != null && appName.isNotEmpty) {
      if (isInstall) {
        return 'Install & Open: $appName';
      }
      if (plat == 'instagram') {
        return 'Engage: $appName';
      }
      return 'Rate & Review: $appName';
    }

    if (task['title'] != null && task['title'].toString().trim().isNotEmpty) {
      return task['title'].toString().trim();
    }
    if (task['serviceTitle'] != null && task['serviceTitle'].toString().trim().isNotEmpty) {
      return task['serviceTitle'].toString().trim();
    }
    if (task['requirements'] != null && task['requirements'] is Map) {
      final req = task['requirements'] as Map;
      if (req['serviceName'] != null && req['serviceName'].toString().trim().isNotEmpty) {
        return req['serviceName'].toString().trim();
      }
      if (req['title'] != null && req['title'].toString().trim().isNotEmpty) {
        return req['title'].toString().trim();
      }
      if (req['serviceTitle'] != null && req['serviceTitle'].toString().trim().isNotEmpty) {
        return req['serviceTitle'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('heading') || k.contains('title') || k.contains('name')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    if (task['metadata'] != null && task['metadata'] is Map) {
      final meta = task['metadata'] as Map;
      if (meta['serviceName'] != null && meta['serviceName'].toString().trim().isNotEmpty) {
        return meta['serviceName'].toString().trim();
      }
      if (meta['title'] != null && meta['title'].toString().trim().isNotEmpty) {
        return meta['title'].toString().trim();
      }
      if (meta['serviceTitle'] != null && meta['serviceTitle'].toString().trim().isNotEmpty) {
        return meta['serviceTitle'].toString().trim();
      }
    }
    final rawType = (task['taskType'] ?? task['type'] ?? 'Task').toString();
    if (isInstall) return 'Install & Open App';
    if (plat == 'google_business' || plat == 'google_maps' || plat == 'google') {
      final rtLower = rawType.toLowerCase();
      if (rtLower.contains('review')) return '5-Star Google Business Review';
      return '5-Star Google Rating';
    }
    if (plat == 'playstore') return '5-Star Rating & Review';
    if (plat == 'youtube') {
      final rtLower = rawType.toLowerCase();
      if (rtLower.contains('combo')) return 'Watch, Like, Sub & Comment on YouTube';
      if (rtLower.contains('sub')) return 'Watch & Subscribe on YouTube';
      if (rtLower.contains('comment')) return 'Watch & Comment on YouTube';
      if (rtLower.contains('like')) return 'Watch & Like YouTube Video';
      return 'Watch & Engage on YouTube';
    }
    if (plat == 'instagram') {
      final rtLower = rawType.toLowerCase();
      if (rtLower.contains('combo')) return 'Like, Follow & Comment on Instagram';
      if (rtLower.contains('like')) return 'Like Instagram Post / Reel';
      if (rtLower.contains('comment')) return 'Comment on Instagram Post';
      return 'Follow on Instagram';
    }
    if (plat == 'x') return 'Follow & Repost on X';

    if (rawType.toUpperCase().startsWith('SERVICE_') || rawType.toUpperCase().startsWith('SRV_')) {
      return '${plat[0].toUpperCase()}${plat.substring(1)} Promotion Task';
    }
    return rawType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  bool _isAppInstall(dynamic task) {
    if (task == null) return false;
    final plat = _getPlatform(task);
    if (plat == 'youtube' || plat == 'instagram' || plat == 'google_maps') {
      return false;
    }
    final type = (task['taskType'] ?? task['task_type'] ?? task['type'] ?? task['serviceCode'] ?? '').toString().toLowerCase();
    if (type.contains('app_install') || (type.contains('install') && !type.contains('instagram'))) {
      return true;
    }
    final serviceName = (task['serviceTitle'] ?? task['serviceName'] ?? (task['requirements'] is Map ? task['requirements']['serviceName'] : null) ?? '').toString().toLowerCase();
    if (serviceName.contains('install & open') || serviceName.contains('app install') || serviceName.contains('install app')) {
      return true;
    }
    return false;
  }

  String _getSubtitle(dynamic task, String platform) {
    if (platform == 'youtube') {
      final req = task is Map && task['requirements'] is Map ? task['requirements'] as Map : null;
      final watchSec = req != null ? (req['watchTimeSeconds'] ?? 0) : 0;
      final mins = (watchSec is num && watchSec > 0) ? (watchSec / 60).ceil() : 2;

      final rawType = (task is Map ? (task['taskType'] ?? task['task_type'] ?? task['type'] ?? task['serviceCode'] ?? '') : '').toString().toLowerCase();
      final reqStr = (req != null) ? req.toString().toLowerCase() : '';
      final titleStr = (task is Map ? (task['title'] ?? task['serviceTitle'] ?? '') : '').toString().toLowerCase();
      final combined = '$rawType $reqStr $titleStr';

      if (combined.contains('combo')) {
        return 'Watch $mins Min, Like, Sub & Comment 🎬';
      }
      if (combined.contains('sub') || combined.contains('channel')) {
        return 'Watch Video (${mins > 0 ? "$mins Min" : "2 Min"}) & Subscribe 🔔';
      }
      if (combined.contains('like')) {
        return 'Watch Video (${mins > 0 ? "$mins Min" : "2 Min"}) & Like 👍';
      }
      if (combined.contains('comment')) {
        return 'Watch Video (${mins > 0 ? "$mins Min" : "2 Min"}) & Post Comment 💬';
      }
      return 'Watch Video ($mins Min) & Engage ▶️';
    }
    if (_isAppInstall(task)) {
      return 'Install App & Open for 30 Seconds';
    }
    if (platform == 'google_business' || platform == 'google_maps' || platform == 'google') {
      return '5-Star Google Maps Review';
    }
    if (platform == 'playstore') {
      return '5-Star Google Play Store Review';
    }
    if (platform == 'instagram') {
      return 'Like Post & Follow Creator';
    }
    if (task != null && task['description'] != null && task['description'].toString().trim().isNotEmpty) {
      final desc = task['description'].toString().trim();
      if (desc.length <= 35) return desc;
      return '${desc.substring(0, 32)}...';
    }
    if (task != null && task['category'] != null && task['category'].toString().trim().isNotEmpty) {
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
    if (platform == 'youtube') return null;
    String? raw;
    if (task['appIcon'] != null && task['appIcon'].toString().trim().isNotEmpty) {
      raw = task['appIcon'].toString().trim();
    } else if (task['requirements'] is Map) {
      final req = task['requirements'] as Map;
      if (req['appIcon'] != null && req['appIcon'].toString().trim().isNotEmpty) {
        raw = req['appIcon'].toString().trim();
      } else if (req['icon'] != null && req['icon'].toString().trim().isNotEmpty) {
        raw = req['icon'].toString().trim();
      }
    } else if (task['metadata'] is Map) {
      final meta = task['metadata'] as Map;
      if (meta['appIcon'] != null && meta['appIcon'].toString().trim().isNotEmpty) {
        raw = meta['appIcon'].toString().trim();
      } else if (meta['icon'] != null && meta['icon'].toString().trim().isNotEmpty) {
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
    if (platform == 'youtube') {
      final req = task is Map && task['requirements'] is Map ? task['requirements'] as Map : null;
      final watchSec = req != null ? (req['watchTimeSeconds'] ?? 0) : 0;
      if (watchSec is num && watchSec > 0) {
        final mins = (watchSec / 60).ceil();
        return '~ $mins Min';
      }
      return '~ 2 Min';
    }
    if (platform == 'google_business' || platform == 'google_maps' || platform == 'google' || platform == 'playstore') return '~ 2 Min';
    return '~ 1 Min';
  }

  String _getYouTubeActionTag(dynamic task) {
    final type = (task is Map ? (task['taskType'] ?? task['task_type'] ?? task['type'] ?? task['serviceCode'] ?? '') : '').toString().toLowerCase();
    final reqStr = (task is Map && task['requirements'] != null) ? task['requirements'].toString().toLowerCase() : '';
    final titleStr = (task is Map ? (task['title'] ?? task['serviceTitle'] ?? '') : '').toString().toLowerCase();
    final combined = '$type $reqStr $titleStr';
    if (combined.contains('combo')) return 'GROWTH COMBO';
    if (combined.contains('sub') || combined.contains('channel')) return 'WATCH & SUBSCRIBE';
    if (combined.contains('like')) return 'WATCH & LIKE';
    if (combined.contains('comment')) return 'WATCH & COMMENT';
    return 'WATCH & ENGAGE';
  }

  String _getPlatform(dynamic task) {
    if (task == null) return 'general';
    final type = (task['taskType'] ?? task['task_type'] ?? task['type'] ?? task['serviceCode'] ?? '').toString().toLowerCase();
    final urlStr = (task['targetUrl'] ?? task['url'] ?? (task['requirements'] is Map ? task['requirements']['targetUrl'] : null) ?? '').toString().toLowerCase();
    final rawPlat = (task['platform'] ?? (task['requirements'] is Map ? task['requirements']['platform'] : null) ?? '').toString().toLowerCase().trim();

    // 1. Google Business / Maps
    if (rawPlat == 'google_maps' ||
        rawPlat == 'google_business' ||
        rawPlat == 'maps' ||
        rawPlat == 'google' ||
        rawPlat == 'gmb' ||
        type.contains('google_maps') ||
        type.contains('google_business') ||
        type.contains('gmb') ||
        (type.contains('map') && !type.contains('bitmap')) ||
        urlStr.contains('maps.google') ||
        urlStr.contains('goo.gl/maps') ||
        urlStr.contains('maps.app.goo.gl') ||
        urlStr.contains('share.google') ||
        urlStr.contains('search.google.com/local')) {
      return 'google_maps';
    }

    // 2. Play Store / App Install / App Review
    if (rawPlat == 'playstore' ||
        rawPlat == 'google_play' ||
        rawPlat == 'play_store' ||
        type.contains('app_install') ||
        type.contains('playstore') ||
        type.contains('play_store') ||
        type.contains('app_review') ||
        urlStr.contains('play.google.com') ||
        urlStr.contains('market://') ||
        (type.contains('install') && !type.contains('instagram'))) {
      return 'playstore';
    }

    // 3. Instagram (Strict check: ensure not install)
    if (rawPlat == 'instagram' ||
        type.contains('instagram') ||
        type.contains('ig_') ||
        urlStr.contains('instagram.com')) {
      return 'instagram';
    }

    // 4. Explicit YouTube check
    if (rawPlat == 'youtube' ||
        type.contains('youtube') ||
        type.contains('yt_') ||
        type == 'yt' ||
        urlStr.contains('youtu.be') ||
        urlStr.contains('youtube.com')) {
      return 'youtube';
    }

    final serviceName = (task['serviceTitle'] ?? task['serviceName'] ?? (task['requirements'] is Map ? task['requirements']['serviceName'] : null) ?? '').toString().toLowerCase();
    if (serviceName.contains('play store') || serviceName.contains('playstore') || serviceName.contains('app install')) {
      return 'playstore';
    }
    if (serviceName.contains('google maps') || serviceName.contains('google review')) {
      return 'google_maps';
    }
    if (serviceName.contains('youtube')) {
      return 'youtube';
    }
    if (serviceName.contains('instagram')) {
      return 'instagram';
    }

    if (rawPlat.isNotEmpty && rawPlat != 'general') {
      return rawPlat;
    }

    return 'google_maps';
  }

  String _getReward(dynamic task) {
    if (task == null) return '5';
    final raw = task['rewardAmount'] ?? task['rewardPerTask'] ?? task['reward'] ?? task['workerReward'] ?? task['payout'];
    if (raw is num) {
      return raw.toStringAsFixed(raw == raw.roundToDouble() ? 0 : 2);
    }
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null) {
        return parsed.toStringAsFixed(parsed == parsed.roundToDouble() ? 0 : 2);
      }
    }
    if (task['metadata'] is Map && (task['metadata'] as Map)['rewardSnapshot'] is Map) {
      final snap = (task['metadata'] as Map)['rewardSnapshot'] as Map;
      final tot = snap['totalReward'] ?? snap['baseReward'];
      if (tot != null) {
        final parsed = double.tryParse(tot.toString());
        if (parsed != null) {
          return parsed.toStringAsFixed(parsed == parsed.roundToDouble() ? 0 : 2);
        }
      }
    }
    return '5';
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatTitle(task);
    final platform = _getPlatform(task);
    final subtitle = _getSubtitle(task, platform);
    final duration = _getDuration(task, platform);
    final reward = _getReward(task);
    final appIcon = _getAppIcon(task);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Platform Logo / Real App Icon on Left ──
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEDF2F7)),
                  ),
                  child: Center(
                    child: ((platform != 'youtube' && platform != 'google_maps' && platform != 'google_business' && platform != 'google') && appIcon != null && appIcon.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              appIcon,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => PlatformLogo(platform: platform, size: 30),
                            ),
                          )
                        : PlatformLogo(platform: platform, size: 30),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Middle Details: Title, Subtitle & Tags ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Tags Row (Easy, ~ 2 Min, Action Tag)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Easy',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF00875A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                duration,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            if (platform == 'youtube') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                                ),
                                child: Text(
                                  _getYouTubeActionTag(task),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Right: Reward Pill & Start Button ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+ ₹$reward',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00875A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00875A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00875A).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Start',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
