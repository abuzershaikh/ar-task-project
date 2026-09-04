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
    if (task['title'] != null && task['title'].toString().trim().isNotEmpty) {
      return task['title'].toString().trim();
    }
    if (task['serviceTitle'] != null && task['serviceTitle'].toString().trim().isNotEmpty) {
      return task['serviceTitle'].toString().trim();
    }
    if (task['requirements'] != null && task['requirements'] is Map) {
      final req = task['requirements'] as Map;
      if (req['appName'] != null && req['appName'].toString().trim().isNotEmpty) {
        return 'Rate & Review: ${req['appName']}';
      }
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
      if (meta['appName'] != null && meta['appName'].toString().trim().isNotEmpty) {
        return 'Rate & Review: ${meta['appName']}';
      }
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
    final plat = _getPlatform(task);
    if (plat == 'google') return 'Write a review on Google';
    if (plat == 'youtube') return 'Like & Comment on YouTube';
    if (plat == 'facebook') return 'Follow on Facebook Page';
    if (plat == 'instagram') return 'Follow on Instagram';
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

  String _getSubtitle(dynamic task, String platform) {
    if (task != null && task['requirements'] is Map && (task['requirements']['appName'] != null && task['requirements']['appName'].toString().trim().isNotEmpty)) {
      return '5-Star Google Play Store Review';
    }
    if (task != null && task['metadata'] is Map && (task['metadata']['appName'] != null && task['metadata']['appName'].toString().trim().isNotEmpty)) {
      return '5-Star Google Play Store Review';
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
    if (task['appIcon'] != null && task['appIcon'].toString().trim().isNotEmpty) {
      return task['appIcon'].toString().trim();
    }
    if (task['requirements'] is Map) {
      final req = task['requirements'] as Map;
      if (req['appIcon'] != null && req['appIcon'].toString().trim().isNotEmpty) {
        return req['appIcon'].toString().trim();
      }
      if (req['icon'] != null && req['icon'].toString().trim().isNotEmpty) {
        return req['icon'].toString().trim();
      }
    }
    if (task['metadata'] is Map) {
      final meta = task['metadata'] as Map;
      if (meta['appIcon'] != null && meta['appIcon'].toString().trim().isNotEmpty) {
        return meta['appIcon'].toString().trim();
      }
      if (meta['icon'] != null && meta['icon'].toString().trim().isNotEmpty) {
        return meta['icon'].toString().trim();
      }
    }
    return null;
  }

  String _getDuration(dynamic task, String platform) {
    if (platform == 'google' || platform == 'playstore') return '~ 2 Min';
    return '~ 1 Min';
  }

  String _getPlatform(dynamic task) {
    if (task == null) return 'youtube';
    if (task['platform'] != null && task['platform'].toString().trim().isNotEmpty) {
      return task['platform'].toString().toLowerCase().trim();
    }
    final type = (task['taskType'] ?? task['type'] ?? task['serviceCode'] ?? '').toString().toLowerCase();
    String reqStr = '';
    if (task['requirements'] is Map) {
      reqStr = task['requirements'].toString().toLowerCase();
    }
    final metaStr = (task['metadata'] != null) ? task['metadata'].toString().toLowerCase() : '';
    final titleStr = (task['title'] ?? task['serviceTitle'] ?? '').toString().toLowerCase();

    final combined = '$type $reqStr $metaStr $titleStr';
    if (combined.contains('play') || combined.contains('playstore') || combined.contains('app_review')) return 'playstore';
    if (combined.contains('youtube') || combined.contains('yt_')) return 'youtube';
    if (combined.contains('instagram') || combined.contains('insta')) return 'instagram';
    if (combined.contains('facebook') || combined.contains('fb')) return 'facebook';
    if (combined.contains('google') || combined.contains('g_map') || combined.contains('maps')) return 'google';
    if (combined.contains('twitter') || combined.contains(' x ') || combined.contains('x.com')) return 'x';
    if (combined.contains('telegram')) return 'telegram';
    return 'youtube';
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
                    child: (appIcon != null && appIcon.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              appIcon,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => PlatformLogo(platform: platform, size: 30),
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

                      // Tags Row (Easy, ~ 2 Min)
                      Row(
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
                        ],
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
