import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TasksTab extends StatefulWidget {
  final String workerId;

  const TasksTab({super.key, required this.workerId});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Active', 'Completed', 'Rejected', 'Timeout'].map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    backgroundColor: AppColors.gray100,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Task List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 15,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    'Task #T-${10000 + index}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('YouTube Like Campaign'),
                      const SizedBox(height: 4),
                      Text(
                        'Completed: ${_getDate(index)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '₹15',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    _showTaskTimeline(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getDate(int index) {
    return '${10 - index} days ago';
  }

  void _showTaskTimeline(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _TimelineItem(
                      title: 'Assigned',
                      subtitle: '10 days ago',
                      icon: Icons.assignment,
                      color: AppColors.gray500,
                    ),
                    _TimelineItem(
                      title: 'Accepted',
                      subtitle: '9 days ago',
                      icon: Icons.check_circle,
                      color: AppColors.info,
                    ),
                    _TimelineItem(
                      title: 'Started',
                      subtitle: '9 days ago',
                      icon: Icons.play_arrow,
                      color: AppColors.primary,
                    ),
                    _TimelineItem(
                      title: 'Proof Submitted',
                      subtitle: '8 days ago',
                      icon: Icons.upload,
                      color: AppColors.warning,
                    ),
                    _TimelineItem(
                      title: 'Under Review',
                      subtitle: '8 days ago',
                      icon: Icons.rate_review,
                      color: AppColors.warning,
                    ),
                    _TimelineItem(
                      title: 'Approved',
                      subtitle: '7 days ago',
                      icon: Icons.verified,
                      color: AppColors.success,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
