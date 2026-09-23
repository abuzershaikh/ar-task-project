import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../data/models/buyer_model.dart';

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final BuyerModel? buyer;

  const TasksTab({
    super.key,
    this.tasks = const [],
    this.buyer,
  });

  @override
  Widget build(BuildContext context) {
    final buyerName = buyer?.name.isNotEmpty == true ? buyer!.name : 'Buyer';
    final buyerAvatar = buyer?.avatarUrl;
    final buyerId = buyer?.id ?? '';

    return Column(
      children: [
        // Buyer Identity & Total Tasks Banner
        if (buyer != null)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: buyerName,
                  imageUrl: buyerAvatar,
                  userId: buyerId,
                  radius: 20,
                  border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$buyerName\'s Task Submissions',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E1B4B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Total ${tasks.length} submissions recorded',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Submissions List
        Expanded(
          child: tasks.isEmpty
              ? Container(
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
                      Icon(Icons.task_alt_rounded, size: 48, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 12),
                      Text(
                        'No buyer task submissions recorded',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final item = tasks[index];
                    final title = (item['title'] ?? item['name'] ?? 'Task #${index + 1}').toString();
                    final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                      ),
                      child: ListTile(
                        leading: AppAvatar(
                          name: buyerName,
                          imageUrl: buyerAvatar,
                          userId: buyerId,
                          radius: 19,
                          fontSize: 12,
                          border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B)),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Backward compatibility alias
typedef BuyerTasksTab = TasksTab;
