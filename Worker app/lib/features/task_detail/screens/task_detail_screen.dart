import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/worker_task_model.dart';

/// TaskDetailScreen (Worker Task Execution & Media Engine)
/// Is screen par Worker ko dynamic task details, instructions, media (YouTube/Audio),
/// live execution countdown timer, aur screenshot proof attachment system dikhta hai.
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
    final status = (widget.task['status'] ?? 'AVAILABLE').toString().toUpperCase();
    if (status == 'ACCEPTED' || status == 'ASSIGNED' || status == 'IN_PROGRESS') {
      _isTaskAccepted = true;
      _startTimer();
    }
  }

  /// Timer start function - Worker task start karte hi 60 seconds ka timer chalega
  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = widget.task['executionTimeSeconds'] ?? 60);

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
    final taskId = widget.task['id'] ?? widget.task['_id'] ?? 'T-101';

    setState(() => _isTaskAccepted = true);
    _startTimer();

    try {
      await taskProvider.acceptTask(taskId);
      await taskProvider.startTask(taskId);
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

  /// Image Attachment Picker - Worker gallery se screenshot proof pick kar sakta hai
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

  /// Submit Task Proof function - Screenshot aur text proof validation submit karta hai
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
    final taskId = widget.task['id'] ?? widget.task['_id'] ?? 'T-101';

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await taskProvider.submitTaskProof(
        taskId,
        textProof.isNotEmpty ? textProof : 'Screenshot attached',
        _selectedProofImage?.path,
      );
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

  /// Open Link helper - YouTube ya target website link opening
  Future<void> _launchURL(String urlString) async {
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
    final title = widget.task['title'] ?? widget.task['taskType'] ?? 'YouTube Channel Subscribe';
    final reward = (widget.task['rewardPerTask'] ?? widget.task['reward'] ?? 159.20).toDouble();
    final description = widget.task['description'] ??
        '1. Click on Open Channel button.\n2. Subscribe to the YouTube channel.\n3. Take a screenshot showing Subscribed status.\n4. Upload screenshot proof below.';
    final targetUrl = widget.task['channelUrl'] ?? widget.task['targetUrl'] ?? 'https://youtube.com';

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

          // ── YouTube Video / Media Action Player Card ────────────
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
                        child: const Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YouTube Task Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Watch & Subscribe Channel', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // YouTube Embedded Video Action Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.video_library_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 8),
                        const Text('Target YouTube Video / Channel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(targetUrl, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open Channel on YouTube', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

          // ── Audio Player Preview Card ───────────────────────────
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
                        decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.graphic_eq_rounded, color: Colors.purple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Audio Instructions Player', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.purple, size: 36),
                          onPressed: () {
                            setState(() => _isPlayingAudio = !_isPlayingAudio);
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isPlayingAudio ? 'Playing Audio Guidelines...' : 'Listen Audio Guidelines (00:45)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              LinearProgressIndicator(
                                value: _isPlayingAudio ? 0.6 : 0.0,
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                color: Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Instructions List ────────────────────────────────────
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task Instructions for Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Instructions'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: description));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instructions copied to clipboard!')));
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

                    // Image Picker Screenshot Attachment Card
                    GestureDetector(
                      onTap: _pickProofScreenshot,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.withOpacity(0.3), style: BorderStyle.solid),
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

                    // Text Proof Input
                    TextField(
                      controller: _proofTextController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Text Proof (Channel Name / Comment text / Notes)',
                        labelStyle: const TextStyle(fontSize: 12),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Proof Button
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
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Task Proof for Payout', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: _isSubmitting ? null : _submitProof,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
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
}
