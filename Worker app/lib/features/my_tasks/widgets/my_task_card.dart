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

  const MyTaskCard({
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
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('textfield') || k.contains('text') || k.contains('desc') || k.contains('instruction') || k.contains('comment')) && v.isNotEmpty) {
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
    if (rawType.toUpperCase().startsWith('SERVICE_') || rawType.toUpperCase().startsWith('SRV_')) {
      final plat = _getPlatform(task);
      return '${plat[0].toUpperCase()}${plat.substring(1)} Promotion Task';
    }
    return rawType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _getPlatform(dynamic task) {
    if (task == null) return 'google';
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
    if (combined.contains('youtube') || combined.contains('yt_')) return 'youtube';
    if (combined.contains('instagram') || combined.contains('insta')) return 'instagram';
    if (combined.contains('facebook') || combined.contains('fb')) return 'facebook';
    if (combined.contains('google') || combined.contains('g_map') || combined.contains('maps') || combined.contains('playstore')) return 'google';
    if (combined.contains('twitter') || combined.contains(' x ') || combined.contains('x.com')) return 'x';
    if (combined.contains('telegram')) return 'telegram';
    return 'google';
  }

  String _getReward(dynamic task) {
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
    return '10';
  }

  String _formatDate(dynamic task) {
    final rawDate = task['createdAt'] ?? task['assignedAt'] ?? task['submittedAt'] ?? task['date'];
    if (rawDate == null) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        return 'Today, $hour:$minute $ampm';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return rawDate.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatTitle(task);
    final reward = _getReward(task);
    final platform = _getPlatform(task);
    final status = (task['status'] ?? 'Active').toString();
    final dateStr = _formatDate(task);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              // Left Platform Logo Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEDF2F7)),
                ),
                child: Center(
                  child: PlatformLogo(platform: platform, size: 26),
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
                        const Icon(Icons.calendar_today_outlined,
                            size: 10, color: Color(0xFF64748B)),
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
    if (norm.contains('accept') || norm.contains('assign') || norm.contains('progress')) {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
      label = norm.contains('progress') ? 'In Progress' : 'Accepted';
    } else if (norm.contains('submit')) {
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF00875A);
      label = 'Submitted';
    } else if (norm.contains('review')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      label = 'Review';
    } else if (norm.contains('approve')) {
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF00875A);
      label = 'Approved';
    } else if (norm.contains('reject')) {
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
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 9.5,
        ),
      ),
    );
  }
}
