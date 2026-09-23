import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../bloc/more_bloc.dart';
import '../../../orders/presentation/widgets/task_review_inspector_modal.dart';

class TaskReviewsQueueScreen extends StatefulWidget {
  const TaskReviewsQueueScreen({super.key});

  @override
  State<TaskReviewsQueueScreen> createState() => _TaskReviewsQueueScreenState();
}

class _TaskReviewsQueueScreenState extends State<TaskReviewsQueueScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MoreBloc>().add(LoadReviewsQueueEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Reviews Queue'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MoreBloc>().add(LoadReviewsQueueEvent()),
          ),
        ],
      ),
      body: BlocBuilder<MoreBloc, MoreState>(
        builder: (context, state) {
          if (state is MoreLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MoreError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<MoreBloc>().add(LoadReviewsQueueEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ReviewsQueueLoaded) {
            final items = state.items;

            if (items.isEmpty) {
              return const Center(child: Text('No pending task reviews in queue'));
            }

            return Column(
              children: [
                // Stats Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.white,
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('Pending Submissions', '${items.length}', AppColors.warning)),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Task List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => TaskReviewInspectorModal(
                                submissionId: item.id,
                                taskId: item.taskId,
                                workerId: item.workerId,
                                workerName: item.workerName,
                                workerEmail: item.workerEmail,
                                workerAvatarUrl: item.avatarUrl,
                                proofUrl: item.proofUrl,
                                proofText: item.proofText,
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
                                    Expanded(
                                      child: Text(
                                        item.taskTitle.isNotEmpty ? item.taskTitle : 'Submission #${item.id}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Row(
                                  children: [
                                    const Icon(Icons.task_alt_rounded, size: 14, color: AppColors.gray500),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Task ID: ${item.taskId}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 10),
                                
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      AppAvatar(
                                        name: item.workerName.isNotEmpty ? item.workerName : 'Worker',
                                        imageUrl: item.avatarUrl,
                                        userId: item.workerId,
                                        radius: 18,
                                        fontSize: 12,
                                        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.workerName.isNotEmpty
                                                  ? item.workerName
                                                  : (item.workerEmail.isNotEmpty ? item.workerEmail : 'Worker #${item.workerId.length > 6 ? item.workerId.substring(0, 6) : item.workerId}'),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.workerEmail.isNotEmpty
                                                  ? item.workerEmail
                                                  : 'ID: ${item.workerId.length > 8 ? item.workerId.substring(0, 8) : item.workerId}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item.proofUrl.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attachment_rounded, size: 14, color: Color(0xFF059669)),
                                              SizedBox(width: 4),
                                              Text('Proof', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.read<MoreBloc>().add(ApproveReviewEvent(item.id));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Approve Submission', style: TextStyle(fontSize: 13)),
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
                                            submissionId: item.id,
                                            taskId: item.taskId,
                                            workerId: item.workerId,
                                            workerName: item.workerName,
                                            workerEmail: item.workerEmail,
                                            workerAvatarUrl: item.avatarUrl,
                                            proofUrl: item.proofUrl,
                                            proofText: item.proofText,
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
            );
          }

          return const SizedBox();
        },
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
