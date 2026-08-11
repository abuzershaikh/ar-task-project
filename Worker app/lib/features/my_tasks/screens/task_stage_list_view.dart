import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import '../widgets/my_task_card.dart';

/// Single list view for a specific task stage.
class TaskStageListView extends StatelessWidget {
  final String stage;

  const TaskStageListView({
    super.key,
    required this.stage,
  });

  static final Map<String, List<Map<String, dynamic>>> _mockTaskStages = {
    'accepted': [
      {
        'id': 'AC1001',
        'title': 'Review on Google',
        'taskType': 'GOOGLE_REVIEW',
        'platform': 'google',
        'status': 'Accepted',
        'rewardPerTask': 10,
        'date': '11 May 2025',
      },
      {
        'id': 'AC1002',
        'title': 'Comment on YouTube',
        'taskType': 'YOUTUBE_COMMENT',
        'platform': 'youtube',
        'status': 'Accepted',
        'rewardPerTask': 8,
        'date': '11 May 2025',
      },
    ],
    'submitted': [
      {
        'id': 'GT4587',
        'title': 'Review on Google',
        'taskType': 'GOOGLE_REVIEW',
        'platform': 'google',
        'status': 'Submitted',
        'rewardPerTask': 10,
        'date': '10 May 2025',
      },
      {
        'id': 'YT7823',
        'title': 'Comment on YouTube',
        'taskType': 'YOUTUBE_COMMENT',
        'platform': 'youtube',
        'status': 'Submitted',
        'rewardPerTask': 8,
        'date': '10 May 2025',
      },
      {
        'id': 'IG1928',
        'title': 'Like & Comment on Instagram',
        'taskType': 'INSTAGRAM_LIKE',
        'platform': 'instagram',
        'status': 'Submitted',
        'rewardPerTask': 6,
        'date': '10 May 2025',
      },
      {
        'id': 'FB7712',
        'title': 'Review on Facebook Page',
        'taskType': 'FACEBOOK_REVIEW',
        'platform': 'facebook',
        'status': 'Submitted',
        'rewardPerTask': 8,
        'date': '09 May 2025',
      },
    ],
    'under-review': [
      {
        'id': 'AP3091',
        'title': 'Install & Register App',
        'taskType': 'APP_INSTALL',
        'platform': 'google',
        'status': 'Review',
        'rewardPerTask': 15,
        'date': '08 May 2025',
      },
      {
        'id': 'TW2011',
        'title': 'Follow Twitter Account',
        'taskType': 'TWITTER_FOLLOW',
        'platform': 'x',
        'status': 'Review',
        'rewardPerTask': 5,
        'date': '08 May 2025',
      },
      {
        'id': 'SV8820',
        'title': 'Survey Form Submission',
        'taskType': 'SURVEY',
        'platform': 'google',
        'status': 'Review',
        'rewardPerTask': 12,
        'date': '07 May 2025',
      },
    ],
    'approved': [
      {
        'id': 'AP9021',
        'title': 'App Rating & Review',
        'taskType': 'APP_REVIEW',
        'platform': 'google',
        'status': 'Approved',
        'rewardPerTask': 20,
        'date': '06 May 2025',
      },
      {
        'id': 'TG1092',
        'title': 'Join Telegram Channel',
        'taskType': 'TELEGRAM_JOIN',
        'platform': 'facebook',
        'status': 'Approved',
        'rewardPerTask': 5,
        'date': '05 May 2025',
      },
    ],
    'rejected': [
      {
        'id': 'RJ1002',
        'title': 'Invalid Screenshot Upload',
        'taskType': 'PROOF_REJECTED',
        'platform': 'instagram',
        'status': 'Rejected',
        'rewardPerTask': 10,
        'date': '04 May 2025',
      },
      {
        'id': 'RJ5021',
        'title': 'Incomplete Review Steps',
        'taskType': 'TASK_FAILED',
        'platform': 'youtube',
        'status': 'Rejected',
        'rewardPerTask': 8,
        'date': '03 May 2025',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    final normStage = stage.toLowerCase();
    final mockFallback = _mockTaskStages[normStage] ?? _mockTaskStages['accepted']!;

    final taskList = taskProvider.myTasks.isNotEmpty
        ? taskProvider.myTasks
        : mockFallback;

    if (taskProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00875A)),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00875A),
      onRefresh: () => taskProvider.fetchMyTasks(stage),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: taskList.length,
        itemBuilder: (context, index) {
          final task = taskList[index];
          return MyTaskCard(
            task: task,
            onTap: () {},
          );
        },
      ),
    );
  }
}
