import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/worker_task_model.dart';

/// TaskDetailScreen (Server-Status-Driven Dynamic Task Execution Engine)
class TaskDetailScreen extends StatefulWidget {
  final dynamic task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _proofTextController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedProofImage;
  bool _isSubmitting = false;
  bool _isTaskAccepted = false;

  // Countdown timer state
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    final status = _getTaskStatus();
    if (status == 'ACCEPTED' || status == 'ASSIGNED' || status == 'IN_PROGRESS') {
      _isTaskAccepted = true;
      _startTimer();
    }
  }

  String _getTaskStatus() {
    final s = (widget.task['status'] ?? widget.task['stage'] ?? 'AVAILABLE').toString().toUpperCase();
    return s;
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    final execTime = widget.task['executionTimeSeconds'] ??
        ((widget.task['timeToCompleteHours'] ?? 1) * 3600);
    setState(() => _secondsRemaining = (execTime is int && execTime > 0) ? execTime : 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _acceptTask() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();

    setState(() => _isTaskAccepted = true);
    _startTimer();

    try {
      if (taskId.isNotEmpty) {
        await taskProvider.acceptTask(taskId);
        await taskProvider.startTask(taskId);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task Accepted! Execution timer started.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  Future<void> _pickProofScreenshot() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedProofImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick screenshot: $e')),
        );
      }
    }
  }

  void _submitProof() async {
    final textProof = _proofTextController.text.trim();

    if (_selectedProofImage == null && textProof.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach screenshot proof or enter proof details.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();

    try {
      if (taskId.isNotEmpty) {
        await taskProvider.submitTaskProof(
          taskId,
          textProof.isNotEmpty ? textProof : 'Screenshot attached',
          _selectedProofImage?.path,
        );
      }
    } catch (_) {}

    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Task Proof Submitted Successfully for Review!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri uri = Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening link: $urlString')),
        );
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _proofTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.task['title'] ?? widget.task['name'] ?? widget.task['taskType'] ?? widget.task['serviceCode'] ?? 'Task Details').toString();
    final reward = (widget.task['workerReward'] ?? widget.task['rewardPerTask'] ?? widget.task['reward'] ?? 0.0).toDouble();
    final description = (widget.task['description'] ?? widget.task['instructions'] ?? 'Follow the instructions provided below to complete the task and submit proof.').toString();
    final targetUrl = (widget.task['targetUrl'] ?? widget.task['channelUrl'] ?? widget.task['url'] ?? '').toString();
    final rawElements = widget.task['elements'];
    final List<dynamic> elements = (rawElements is List) ? rawElements : [];
    final status = _getTaskStatus();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Banner (If completed / submitted / under review) ────────
          if (status != 'AVAILABLE' && status != 'ASSIGNED' && status != 'IN_PROGRESS' && status != 'ACCEPTED') ...[
            _buildStatusHeaderCard(status),
            const SizedBox(height: 16),
          ],

          // ── Worker Reward & Timer Header Banner ─────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Worker Payout Reward', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${reward.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _secondsRemaining > 0 ? '${_secondsRemaining}s Timer' : 'Timer Done',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Dynamic Server Elements Section ─────────────────────
          if (elements.isNotEmpty) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task Execution Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    ...elements.map((elem) => _buildServerElementWidget(elem)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Target URL Action Card (if available) ───────────────
          if (targetUrl.isNotEmpty) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.link_rounded, color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text('Target Link Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.open_in_browser_rounded, color: Colors.blueAccent, size: 42),
                          const SizedBox(height: 8),
                          Text(targetUrl, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open Target Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () => _launchURL(targetUrl),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Instructions Card ──────────────────────────────────
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Instructions'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: description));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instructions copied!')));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Proof Attachment & Submit Section ───────────────────
          if (_isTaskAccepted) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Submit Proof Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: _pickProofScreenshot,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                        ),
                        child: _selectedProofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedProofImage!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 42, color: Colors.indigo),
                                  SizedBox(height: 8),
                                  Text('Tap to attach Screenshot Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                                  Text('Upload clear proof screenshot', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _proofTextController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Text Proof (Username / Notes)',
                        labelStyle: const TextStyle(fontSize: 12),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Task Proof', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: _isSubmitting ? null : _submitProof,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (status == 'AVAILABLE') ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Accept & Start Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _acceptTask,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeaderCard(String status) {
    Color cardColor;
    IconData icon;
    String text;

    switch (status) {
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        cardColor = Colors.amber.shade800;
        icon = Icons.hourglass_top_rounded;
        text = 'Task Submitted — Currently Under Review';
        break;
      case 'APPROVED':
      case 'COMPLETED':
        cardColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        text = 'Task Approved — Reward Credited!';
        break;
      case 'REJECTED':
        cardColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        text = 'Task Proof Rejected';
        break;
      default:
        cardColor = Colors.indigo;
        icon = Icons.info_rounded;
        text = 'Status: $status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerElementWidget(dynamic element) {
    if (element is! Map) return const SizedBox.shrink();

    final label = (element['label'] ?? '').toString();
    final type = (element['type'] ?? 'text').toString();
    final content = (element['contentValue'] ?? element['defaultValue'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded, color: Color(0xFF4F46E5), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty)
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                if (content.isNotEmpty)
                  Text(content, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
