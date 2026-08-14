import 'package:flutter/material.dart';
import '../../../shared/widgets/platform_logo.dart';
import '../../../shared/widgets/marquee_text.dart';

/// Clean Task Feed Card:
/// - Logo box on left
/// - Badge & Title (Single-line Marquee slow scrolling if long)
/// - Reward text on right (e.g. ₹10 Per Task)
/// - Centered "Start Task ➔" green button at bottom
class TaskFeedCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;

  const TaskFeedCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = task['title'] ?? task['taskType'] ?? 'Review on Google';
    final reward = task['rewardPerTask'] ?? task['reward'] ?? 10;
    final platform = (task['platform'] ?? task['taskType'] ?? 'Google').toString();
    final badge = (task['badge'] ?? 'Featured').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Top Row: Logo | Badge + Title | Reward
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Logo Icon Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEDF2F7)),
                  ),
                  child: Center(
                    child: PlatformLogo(platform: platform, size: 32),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle Content: Badge & Title Marquee
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Color(0xFF00875A),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Single-line Marquee Title
                      MarqueeText(
                        text: title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Reward Box
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹$reward',
                      style: const TextStyle(
                        color: Color(0xFF00875A),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      'Per Task',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Centered "Start Task ➔" Button
            Center(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00875A),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00875A).withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
