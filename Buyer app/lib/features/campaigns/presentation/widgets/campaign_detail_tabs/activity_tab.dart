import 'package:flutter/material.dart';

class ActivityTab extends StatelessWidget {
  final String campaignId;

  const ActivityTab({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActivityItem(
          icon: Icons.campaign,
          title: 'Campaign Created',
          time: '11 Aug, 2:30 PM',
          color: Colors.blue,
        ),
        _ActivityItem(
          icon: Icons.payment,
          title: 'Payment Confirmed',
          time: '11 Aug, 2:35 PM',
          color: Colors.green,
        ),
        _ActivityItem(
          icon: Icons.task_alt,
          title: '500 Tasks Generated',
          time: '11 Aug, 2:40 PM',
          color: Colors.purple,
        ),
        _ActivityItem(
          icon: Icons.people,
          title: 'Workers Assigned',
          time: '11 Aug, 3:00 PM',
          color: Colors.orange,
        ),
        _ActivityItem(
          icon: Icons.check_circle,
          title: 'First Submission',
          time: '11 Aug, 4:15 PM',
          color: Colors.teal,
        ),
        _ActivityItem(
          icon: Icons.celebration,
          title: '100 Tasks Completed',
          time: '12 Aug, 10:00 AM',
          color: Colors.amber,
        ),
        _ActivityItem(
          icon: Icons.schedule,
          title: 'Campaign Extended +10h',
          time: '13 Aug, 10:05 PM',
          color: Colors.red,
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
