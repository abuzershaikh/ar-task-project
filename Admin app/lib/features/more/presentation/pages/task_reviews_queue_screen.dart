import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/presentation/widgets/task_review_inspector_modal.dart';

class TaskReviewsQueueScreen extends StatefulWidget {
  const TaskReviewsQueueScreen({super.key});

  @override
  State<TaskReviewsQueueScreen> createState() => _TaskReviewsQueueScreenState();
}

class _TaskReviewsQueueScreenState extends State<TaskReviewsQueueScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Reviews Queue'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Pending', '234', AppColors.warning)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('High Priority', '45', AppColors.error)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Reviewed Today', '89', AppColors.success)),
              ],
            ),
          ),
          
          // Filter Pills
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'High Priority', 'Low Quality', 'Flagged'].map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      backgroundColor: AppColors.gray100,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray300),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 20,
              itemBuilder: (context, index) {
                final isHighPriority = index % 5 == 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => TaskReviewInspectorModal(
                          taskId: 'T-${10000 + index}',
                          workerId: 'W-${1000 + index}',
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isHighPriority)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'HIGH PRIORITY',
                                    style: TextStyle(fontSize: 9, color: AppColors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (isHighPriority) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Task #T-${10000 + index}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${index + 1}h ago',
                                style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Icon(Icons.campaign, size: 14, color: AppColors.gray500),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'YouTube Like Campaign',
                                  style: TextStyle(fontSize: 13, color: AppColors.gray600),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: const Text('W', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Worker W-${1000 + index}', style: const TextStyle(fontSize: 12)),
                                    Text('Score: ${85 + index % 15}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                  child: const Text('Reject', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: AppColors.success,
                                  ),
                                  child: const Text('Approve', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward, size: 20),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => TaskReviewInspectorModal(
                                      taskId: 'T-${10000 + index}',
                                      workerId: 'W-${1000 + index}',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
