import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ActivityTab extends StatelessWidget {
  final List<dynamic> activity;

  const ActivityTab({super.key, this.activity = const []});

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text('No buyer activity logs recorded', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: activity.length,
      itemBuilder: (context, index) {
        final item = activity[index];
        final type = item['type'] ?? 'BUYER_ACTIVITY';
        final timestamp = item['timestamp']?.toString() ?? 'Recent';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
          ),
          child: ListTile(
            leading: const Icon(Icons.history_rounded, color: Color(0xFF4F46E5)),
            title: Text(type.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B))),
            subtitle: Text(timestamp, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ),
        );
      },
    );
  }
}

// Backward compatibility alias
typedef BuyerActivityTab = ActivityTab;

