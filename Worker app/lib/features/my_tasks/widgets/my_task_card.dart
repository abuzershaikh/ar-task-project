import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../shared/widgets/platform_logo.dart';
import '../../../shared/widgets/marquee_text.dart';

/// Compact & Sleek My Task Card:
/// - Logo Box on left
/// - Title (Single-line Marquee slow scrolling if long) & Date meta
/// - Reward text on right
/// - Status Badge Pill (Accepted, Submitted, Review, Approved, Rejected)
class MyTaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;

  const MyTaskCard({super.key, required this.task, required this.onTap});

  Map<String, dynamic>? _extractRequirements(dynamic task) {
    if (task == null) return null;
    final req = task['requirements'];
    if (req is Map) return Map<String, dynamic>.from(req);
    if (req is String && req.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(req);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  String _formatTitle(dynamic task) {
    if (task == null) return 'Task';
    if (task['title'] != null && task['title'].toString().trim().isNotEmpty) {
      return task['title'].toString().trim();
    }
    if (task['serviceTitle'] != null &&
        task['serviceTitle'].toString().trim().isNotEmpty) {
      return task['serviceTitle'].toString().trim();
    }
    final reqMap = _extractRequirements(task);
    final plat = _getPlatform(task);
    final isYouTube = plat == 'youtube';
    final type = (task['taskType'] ?? task['type'] ?? task['serviceCode'] ?? '').toString().toLowerCase();
    final isInstall = !isYouTube && type.contains('install');

    if (isYouTube) {
      if (type.contains('combo')) return 'Watch, Like, Sub & Comment on YouTube';
      if (type.contains('sub') || type.contains('channel')) return 'Watch & Subscribe on YouTube';
      if (type.contains('like')) return 'Watch & Like YouTube Video';
      if (type.contains('comment')) return 'Watch & Comment on YouTube';
      return 'Watch & Engage on YouTube';
    }

    if (reqMap != null) {
      if (reqMap['appName'] != null &&
          reqMap['appName'].toString().trim().isNotEmpty) {
        final name = reqMap['appName'].toString().trim();
        return isInstall ? 'Install & Open: $name' : 'Rate & Review: $name';
      }
      if (reqMap['serviceName'] != null &&
          reqMap['serviceName'].toString().trim().isNotEmpty) {
        return reqMap['serviceName'].toString().trim();
      }
      if (reqMap['title'] != null && reqMap['title'].toString().trim().isNotEmpty) {
        return reqMap['title'].toString().trim();
      }
      if (reqMap['serviceTitle'] != null &&
          reqMap['serviceTitle'].toString().trim().isNotEmpty) {
        return reqMap['serviceTitle'].toString().trim();
      }
      for (final entry in reqMap.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('heading') ||
                k.contains('title') ||
                k.contains('name')) &&
            v.isNotEmpty) {
          return v;
        }
      }
      for (final entry in reqMap.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('textfield') ||
                k.contains('text') ||
                k.contains('desc') ||
                k.contains('instruction') ||
                k.contains('comment')) &&
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

  String _getPlatform(dynamic task) {
    if (task == null) return 'google_maps';
    final reqMap = _extractRequirements(task);

    final type = (task['taskType'] ?? task['task_type'] ?? task['type'] ?? task['serviceCode'] ?? '')
        .toString()
        .toLowerCase();
    final urlStr = (task['targetUrl'] ??
            task['url'] ??
            (reqMap != null ? (reqMap['targetUrl'] ?? reqMap['url'] ?? reqMap['link']) : null) ??
            '')
        .toString()
        .toLowerCase();
    final rawPlat = (task['platform'] ??
            (reqMap != null ? reqMap['platform'] : null) ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    final serviceName = (task['serviceTitle'] ??
            task['serviceName'] ??
            (reqMap != null ? (reqMap['serviceName'] ?? reqMap['serviceTitle']) : null) ??
            '')
        .toString()
        .toLowerCase();
    final titleStr = (task['title'] ?? '')
        .toString()
        .toLowerCase();
    final reqStr = (reqMap != null ? reqMap.toString() : (task['requirements'] ?? '')).toString().toLowerCase();
    final metaStr = (task['metadata'] != null)
        ? task['metadata'].toString().toLowerCase()
        : '';
    // ── 1. Google Business / Maps ──
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
        urlStr.contains('search.google.com/local') ||
        serviceName.contains('google maps') ||
        serviceName.contains('google business') ||
        serviceName.contains('gmb') ||
        serviceName.contains('business review') ||
        serviceName.contains('maps review') ||
        titleStr.contains('google maps') ||
        titleStr.contains('google business')) {
      return 'google_maps';
    }

    // ── 2. Play Store & App Install ──
    if (rawPlat == 'playstore' ||
        rawPlat == 'google_play' ||
        rawPlat == 'play_store' ||
        type.contains('app_install') ||
        type.contains('playstore') ||
        type.contains('google_play') ||
        type.contains('play_store') ||
        type.contains('app_review') ||
        urlStr.contains('play.google.com') ||
        urlStr.contains('market://') ||
        serviceName.contains('play store') ||
        serviceName.contains('playstore') ||
        serviceName.contains('app review') ||
        serviceName.contains('app install') ||
        serviceName.contains('install app') ||
        titleStr.contains('play store') ||
        titleStr.contains('app review') ||
        (type.contains('install') && !type.contains('instagram')) ||
        (titleStr.contains('install & open') && !titleStr.contains('instagram'))) {
      return 'playstore';
    }

    // ── 3. Instagram ──
    if (rawPlat == 'instagram' ||
        type.contains('instagram') ||
        type.contains('ig_') ||
        urlStr.contains('instagram.com') ||
        serviceName.contains('instagram') ||
        titleStr.contains('instagram')) {
      return 'instagram';
    }

    // ── 4. YouTube ──
    if (rawPlat == 'youtube' ||
        type.contains('youtube') ||
        type.contains('yt_') ||
        type == 'yt' ||
        urlStr.contains('youtu.be') ||
        urlStr.contains('youtube.com') ||
        serviceName.contains('youtube') ||
        titleStr.contains('youtube')) {
      return 'youtube';
    }

    // ── 5. Facebook ──
    if (rawPlat == 'facebook' ||
        type.contains('facebook') ||
        type.contains('fb') ||
        urlStr.contains('facebook.com') ||
        serviceName.contains('facebook')) {
      return 'facebook';
    }

    // ── 6. Twitter / X ──
    if (rawPlat == 'x' ||
        rawPlat == 'twitter' ||
        type.contains('twitter') ||
        type.contains('x_') ||
        urlStr.contains('twitter.com') ||
        urlStr.contains('x.com') ||
        serviceName.contains('twitter') ||
        serviceName.contains(' x ')) {
      return 'x';
    }

    // ── 7. Telegram ──
    if (rawPlat == 'telegram' ||
        type.contains('telegram') ||
        serviceName.contains('telegram') ||
        urlStr.contains('t.me')) {
      return 'telegram';
    }

    if (rawPlat.isNotEmpty && rawPlat != 'general') {
      return rawPlat;
    }

    return 'google_maps';
  }

  String _getReward(dynamic task) {
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
    return '10';
  }

  String _formatDate(dynamic task) {
    final rawDate =
        task['createdAt'] ??
        task['assignedAt'] ??
        task['submittedAt'] ??
        task['date'];
    if (rawDate == null) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final hour = dt.hour > 12
            ? dt.hour - 12
            : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        return 'Today, $hour:$minute $ampm';
      }
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return rawDate.toString();
    }
  }

  String? _getAppIcon(dynamic task) {
    if (task == null) return null;
    final plat = _getPlatform(task);
    if (plat == 'youtube') {
      return null;
    }
    if (task['appIcon'] != null &&
        task['appIcon'].toString().trim().isNotEmpty) {
      return task['appIcon'].toString().trim();
    }
    final reqMap = _extractRequirements(task);
    if (reqMap != null) {
      if (reqMap['appIcon'] != null &&
          reqMap['appIcon'].toString().trim().isNotEmpty) {
        return reqMap['appIcon'].toString().trim();
      }
      if (reqMap['icon'] != null && reqMap['icon'].toString().trim().isNotEmpty) {
        return reqMap['icon'].toString().trim();
      }
    }
    if (task['metadata'] is Map) {
      final meta = task['metadata'] as Map;
      if (meta['appIcon'] != null &&
          meta['appIcon'].toString().trim().isNotEmpty) {
        return meta['appIcon'].toString().trim();
      }
      if (meta['icon'] != null && meta['icon'].toString().trim().isNotEmpty) {
        return meta['icon'].toString().trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatTitle(task);
    final reward = _getReward(task);
    final platform = _getPlatform(task);
    final status = (task['status'] ?? 'Active').toString();
    final dateStr = _formatDate(task);
    final appIcon = _getAppIcon(task);
    final isYouTube = platform == 'youtube';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Platform Logo / Real App Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isYouTube ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isYouTube ? const Color(0xFFFEE2E2) : const Color(0xFFEDF2F7),
                  ),
                ),
                child: Center(
                  child: (!isYouTube && appIcon != null && appIcon.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            appIcon,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                PlatformLogo(platform: platform, size: 26),
                          ),
                        )
                      : PlatformLogo(platform: platform, size: 26),
                ),
              ),
              const SizedBox(width: 10),

              // Middle Content (Title Marquee & Date)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Single-line Marquee Title
                    MarqueeText(
                      text: title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Date Meta Row
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 10,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Column: Reward & Status Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹$reward',
                    style: const TextStyle(
                      color: Color(0xFF00875A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                    ),
                  ),
                  const Text(
                    'Per Task',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Status Badge Pill
                  _buildStatusPill(status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFE6F4EA);
    Color fg = const Color(0xFF00875A);
    String label = status;

    final norm = status.toLowerCase();
    if (norm.contains('accept') ||
        norm.contains('assign') ||
        norm.contains('progress')) {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
      label = norm.contains('progress') ? 'In Progress' : 'Accepted';
    } else if (norm.contains('submit')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      label = 'Submitted';
    } else if (norm.contains('review')) {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFEA580C);
      label = 'In Review';
    } else if (norm.contains('approve') ||
        norm.contains('complete') ||
        norm.contains('done')) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      label = 'Approved ✓';
    } else if (norm.contains('reject') ||
        norm.contains('cancel') ||
        norm.contains('fail')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 9.5),
      ),
    );
  }
}
