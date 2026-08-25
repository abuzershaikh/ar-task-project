import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ActivityTab extends StatelessWidget {
  final List<dynamic> activity;

  const ActivityTab({
    super.key,
    this.activity = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Live Session & Audit Logs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          activity.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.access_time_rounded, size: 40, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text(
                        'No recent session logs recorded',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activity.length,
                  itemBuilder: (context, index) {
                    final item = activity[index];
                    final type = item['type'] ?? 'ACTIVITY';
                    final timestamp = item['timestamp']?.toString() ?? 'Recent';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.history_rounded, color: Color(0xFF0284C7), size: 20),
                        title: Text(type.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        subtitle: Text(timestamp, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

