import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_badge.dart';

/// Task Detail Screen — shows full task info, proof submission form, and accept CTA.
class TaskDetailScreen extends StatefulWidget {
  final dynamic task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _proofTextController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isSubmitting = false;

  void _acceptTask() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = widget.task['id'] ?? widget.task['_id'];

    final success = await taskProvider.acceptTask(taskId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Task Accepted Successfully!' : 'Failed to accept task'),
          backgroundColor: success ? AppTheme.accentColor : AppTheme.dangerColor,
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  void _submitProof() async {
    final textProof = _proofTextController.text.trim();
    if (textProof.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter proof details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = widget.task['id'] ?? widget.task['_id'];

    final success = await taskProvider.submitTaskProof(
      taskId,
      textProof,
      _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
    );

    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Proof Submitted Successfully!' : 'Submission failed'),
          backgroundColor: success ? AppTheme.accentColor : AppTheme.dangerColor,
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _proofTextController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.task['title'] ?? widget.task['taskType'] ?? 'Task Details';
    final reward = widget.task['rewardPerTask'] ?? widget.task['reward'] ?? 15.0;
    final status = (widget.task['status'] ?? 'AVAILABLE').toString().toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reward Banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Reward',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$reward',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StatusBadge(status: status, fontSize: 13),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Instructions ───────────────────────────────────────
            Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.task['description'] ??
                      '1. Complete the task as per instructions.\n2. Take a screenshot of the completed proof.\n3. Enter required text proof and submit.',
                  style: const TextStyle(height: 1.5, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Proof Submission Form ──────────────────────────────
            if (status == 'ASSIGNED' ||
                status == 'IN_PROGRESS' ||
                status == 'ACCEPTED') ...[
              Text('Submit Proof', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _proofTextController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Text Proof (Username / Reference ID / Answer)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Screenshot / Image Proof URL (Optional)',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProof,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Task Proof'),
                ),
              ),
            ] else if (status == 'AVAILABLE' || status == 'ACTIVE') ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _acceptTask,
                  child: const Text('Accept This Task'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
