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

  @override
  Widget build(BuildContext context) {
    final title = task['title'] ?? task['taskType'] ?? 'Review on Google';
    final reward = task['rewardPerTask'] ?? task['reward'] ?? 10;
    final platform = (task['platform'] ?? task['taskType'] ?? 'Google').toString();
    final status = (task['status'] ?? 'Submitted').toString();
    final dateStr = (task['date'] ?? '10 May 2025').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
    if (norm.contains('accept')) {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
      label = 'Accepted';
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
