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

  // Audio Player state
  bool _isPlayingAudio = false;
  double _audioProgress = 0.0;
  int _audioElapsedSeconds = 0;
  int _audioTotalSeconds = 75;
  Timer? _audioPlaybackTimer;

  void _toggleAudioPlayback(String audioUrl) {
    if (_isPlayingAudio) {
      _audioPlaybackTimer?.cancel();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      _audioPlaybackTimer?.cancel();
      _audioPlaybackTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_audioElapsedSeconds < _audioTotalSeconds) {
          setState(() {
            _audioElapsedSeconds++;
            _audioProgress = _audioElapsedSeconds / _audioTotalSeconds;
          });
        } else {
          t.cancel();
          setState(() {
            _isPlayingAudio = false;
            _audioElapsedSeconds = 0;
            _audioProgress = 0.0;
          });
        }
      });
    }
  }

  void _seekAudio(double value) {
    setState(() {
      _audioProgress = value;
      _audioElapsedSeconds = (value * _audioTotalSeconds).toInt();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioPlaybackTimer?.cancel();
    _proofTextController.dispose();
    super.dispose();
  }

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

    if (_selectedProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please attach screenshot proof from gallery before submitting.'),
          backgroundColor: AppTheme.dangerColor,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();

    try {
      if (taskId.isNotEmpty) {
        final success = await taskProvider.submitTaskProof(
          taskId,
          textProof.isNotEmpty ? textProof : 'Screenshot attached',
          _selectedProofImage?.path,
        );
        if (!success) {
          throw Exception(taskProvider.error ?? 'Proof submission failed');
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Upload Error: $e'),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

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

  String _extractTitle() {
    final t = widget.task;
    if (t['title'] != null && t['title'].toString().trim().isNotEmpty) return t['title'].toString().trim();
    if (t['serviceTitle'] != null && t['serviceTitle'].toString().trim().isNotEmpty) return t['serviceTitle'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['serviceName'] != null && req['serviceName'].toString().trim().isNotEmpty) return req['serviceName'].toString().trim();
      if (req['title'] != null && req['title'].toString().trim().isNotEmpty) return req['title'].toString().trim();
      if (req['serviceTitle'] != null && req['serviceTitle'].toString().trim().isNotEmpty) return req['serviceTitle'].toString().trim();
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('heading') || k.contains('title') || k.contains('name')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    if (t['metadata'] is Map) {
      final meta = t['metadata'] as Map;
      if (meta['serviceName'] != null && meta['serviceName'].toString().trim().isNotEmpty) return meta['serviceName'].toString().trim();
      if (meta['title'] != null && meta['title'].toString().trim().isNotEmpty) return meta['title'].toString().trim();
      if (meta['serviceTitle'] != null && meta['serviceTitle'].toString().trim().isNotEmpty) return meta['serviceTitle'].toString().trim();
    }
    final raw = (t['taskType'] ?? t['type'] ?? t['serviceCode'] ?? 'Task Details').toString();
    if (raw.toUpperCase().startsWith('SERVICE_') || raw.toUpperCase().startsWith('SRV_')) {
      return 'Campaign Task Details';
    }
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  double _extractReward() {
    final t = widget.task;
    final raw = t['rewardAmount'] ?? t['rewardPerTask'] ?? t['reward'] ?? t['workerReward'] ?? t['payout'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String _extractDescription() {
    final t = widget.task;
    if (t['description'] != null && t['description'].toString().trim().isNotEmpty) return t['description'].toString().trim();
    if (t['instructions'] != null && t['instructions'].toString().trim().isNotEmpty) return t['instructions'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['description'] != null && req['description'].toString().trim().isNotEmpty) return req['description'].toString().trim();
      if (req['instructions'] != null && req['instructions'].toString().trim().isNotEmpty) return req['instructions'].toString().trim();
      if (req['adminInstructions'] != null && req['adminInstructions'].toString().trim().isNotEmpty) return req['adminInstructions'].toString().trim();
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('paragraph') || k.contains('desc') || k.contains('instruction')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    if (t['metadata'] is Map) {
      final meta = t['metadata'] as Map;
      if (meta['description'] != null && meta['description'].toString().trim().isNotEmpty) return meta['description'].toString().trim();
      if (meta['instructions'] != null && meta['instructions'].toString().trim().isNotEmpty) return meta['instructions'].toString().trim();
    }
    return 'Follow the instructions provided below to complete the task and submit proof.';
  }

  String _extractTargetUrl() {
    final t = widget.task;
    if (t['targetUrl'] != null && t['targetUrl'].toString().trim().isNotEmpty) return t['targetUrl'].toString().trim();
    if (t['channelUrl'] != null && t['channelUrl'].toString().trim().isNotEmpty) return t['channelUrl'].toString().trim();
    if (t['url'] != null && t['url'].toString().trim().isNotEmpty) return t['url'].toString().trim();
    if (t['youtubeUrl'] != null && t['youtubeUrl'].toString().trim().isNotEmpty) return t['youtubeUrl'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['targetUrl'] != null && req['targetUrl'].toString().trim().isNotEmpty) return req['targetUrl'].toString().trim();
      if (req['youtubeUrl'] != null && req['youtubeUrl'].toString().trim().isNotEmpty) return req['youtubeUrl'].toString().trim();
      if (req['channelUrl'] != null && req['channelUrl'].toString().trim().isNotEmpty) return req['channelUrl'].toString().trim();
      if (req['url'] != null && req['url'].toString().trim().isNotEmpty) return req['url'].toString().trim();
      if (req['buttonUrl'] != null && req['buttonUrl'].toString().trim().isNotEmpty) return req['buttonUrl'].toString().trim();
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('actionbutton') || k.contains('url') || k.contains('link') || k.contains('youtube')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    return '';
  }

  String _extractCustomText() {
    final t = widget.task;
    if (t['commentText'] != null && t['commentText'].toString().trim().isNotEmpty) return t['commentText'].toString().trim();
    if (t['comment_text'] != null && t['comment_text'].toString().trim().isNotEmpty) return t['comment_text'].toString().trim();
    if (t['customText'] != null && t['customText'].toString().trim().isNotEmpty) return t['customText'].toString().trim();
    if (t['comment'] != null && t['comment'].toString().trim().isNotEmpty) return t['comment'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['commentText'] != null && req['commentText'].toString().trim().isNotEmpty) return req['commentText'].toString().trim();
      if (req['comment_text'] != null && req['comment_text'].toString().trim().isNotEmpty) return req['comment_text'].toString().trim();
      if (req['generatedContent'] != null && req['generatedContent'].toString().trim().isNotEmpty) return req['generatedContent'].toString().trim();
      if (req['customText'] != null && req['customText'].toString().trim().isNotEmpty) return req['customText'].toString().trim();
      if (req['comment'] != null && req['comment'].toString().trim().isNotEmpty) return req['comment'].toString().trim();
      if (req['text'] != null && req['text'].toString().trim().isNotEmpty) return req['text'].toString().trim();
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('textfield') || k.contains('text') || k.contains('comment') || k.contains('custom')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    if (t['metadata'] is Map) {
      final meta = t['metadata'] as Map;
      if (meta['commentText'] != null && meta['commentText'].toString().trim().isNotEmpty) return meta['commentText'].toString().trim();
      if (meta['customText'] != null && meta['customText'].toString().trim().isNotEmpty) return meta['customText'].toString().trim();
      if (meta['comment'] != null && meta['comment'].toString().trim().isNotEmpty) return meta['comment'].toString().trim();
    }
    return '';
  }

  String _extractVideoTutorialUrl() {
    final t = widget.task;
    if (t['videoTutorialUrl'] != null && t['videoTutorialUrl'].toString().trim().isNotEmpty) return t['videoTutorialUrl'].toString().trim();
    if (t['video_tutorial_url'] != null && t['video_tutorial_url'].toString().trim().isNotEmpty) return t['video_tutorial_url'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['videoTutorialUrl'] != null && req['videoTutorialUrl'].toString().trim().isNotEmpty) return req['videoTutorialUrl'].toString().trim();
      if (req['video_tutorial_url'] != null && req['video_tutorial_url'].toString().trim().isNotEmpty) return req['video_tutorial_url'].toString().trim();
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('videotutorial') || k.contains('video_tutorial')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    return '';
  }

  String _extractAudioGuideUrl() {
    final t = widget.task;
    if (t['audioGuideUrl'] != null && t['audioGuideUrl'].toString().trim().isNotEmpty) return t['audioGuideUrl'].toString().trim();
    if (t['audio_guide_url'] != null && t['audio_guide_url'].toString().trim().isNotEmpty) return t['audio_guide_url'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['audioGuideUrl'] != null && req['audioGuideUrl'].toString().trim().isNotEmpty) return req['audioGuideUrl'].toString().trim();
      if (req['audio_guide_url'] != null && req['audio_guide_url'].toString().trim().isNotEmpty) return req['audio_guide_url'].toString().trim();
    }
    return '';
  }

  String _extractAdminInstructions() {
    final t = widget.task;
    if (t['adminInstructions'] != null && t['adminInstructions'].toString().trim().isNotEmpty) return t['adminInstructions'].toString().trim();
    if (t['admin_instructions'] != null && t['admin_instructions'].toString().trim().isNotEmpty) return t['admin_instructions'].toString().trim();
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['adminInstructions'] != null && req['adminInstructions'].toString().trim().isNotEmpty) return req['adminInstructions'].toString().trim();
      if (req['admin_instructions'] != null && req['admin_instructions'].toString().trim().isNotEmpty) return req['admin_instructions'].toString().trim();
    }
    return '';
  }

  List<dynamic> _extractElements() {
    final t = widget.task;
    if (t['elements'] is List && (t['elements'] as List).isNotEmpty) return t['elements'] as List;
    if (t['requirements'] is Map && (t['requirements'] as Map)['elements'] is List) {
      return (t['requirements'] as Map)['elements'] as List;
    }
    if (t['metadata'] is Map && (t['metadata'] as Map)['elements'] is List) {
      return (t['metadata'] as Map)['elements'] as List;
    }
    return [];
  }

  String? _extractYouTubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final title = _extractTitle();
    final reward = _extractReward();
    final description = _extractDescription();
    final targetUrl = _extractTargetUrl();
    final customText = _extractCustomText();
    final videoTutorialUrl = _extractVideoTutorialUrl();
    final audioGuideUrl = _extractAudioGuideUrl();
    final adminInstructions = _extractAdminInstructions();
    final List<dynamic> elements = _extractElements();
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
          const SizedBox(height: 16),

          // ── 1. Admin Tutorial Video (if configured) ─────────────
          if (videoTutorialUrl.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final ytId = _extractYouTubeId(videoTutorialUrl);
                return Card(
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.video_library_rounded, color: Colors.red, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text('Tutorial & Guide Video (Watch First)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _launchURL(videoTutorialUrl),
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              image: ytId != null
                                  ? DecorationImage(
                                      image: NetworkImage('https://img.youtube.com/vi/$ytId/hqdefault.jpg'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(color: Colors.black.withOpacity(0.35)),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                                ),
                                Positioned(
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('Tap to Watch Tutorial Video', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // ── 2. Admin Voice / Audio Guide Player ────────────────────
          if (audioGuideUrl.isNotEmpty) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigoAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.record_voice_over_rounded, color: Colors.cyanAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Voice Guide (Listen Instructions)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Listen carefully to complete this task correctly',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 18),
                          tooltip: 'Open Audio Stream',
                          onPressed: () => _launchURL(audioGuideUrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Audio Progress Bar & Controls
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleAudioPlayback(audioGuideUrl),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: const Color(0xFF0F172A),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: Colors.cyanAccent,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _audioProgress.clamp(0.0, 1.0),
                                  onChanged: _seekAudio,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(_audioElapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_audioElapsedSeconds % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${(_audioTotalSeconds ~/ 60).toString().padLeft(2, '0')}:${(_audioTotalSeconds % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 3. Step-by-Step Guidance from Admin ─────────────────
          if (adminInstructions.isNotEmpty) ...[
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.format_list_numbered_rounded, color: Colors.teal, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('Step-by-Step Task Guidance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Text(adminInstructions, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF334155))),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 4. Target Link Action Card (Buyer URL) ───────────────
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.link_rounded, color: Colors.blue, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('Target Link Action (Open & Perform)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.open_in_browser_rounded, color: Colors.blueAccent, size: 36),
                          const SizedBox(height: 6),
                          Text(targetUrl, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                label: const Text('Open Target Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                onPressed: () => _launchURL(targetUrl),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy Link', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: targetUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target URL copied to clipboard!')));
                                },
                              ),
                            ],
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

          // ── 5. Buyer Custom Text / Comment to Post ──────────────
          if (customText.isNotEmpty) ...[
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.content_paste_rounded, color: Colors.teal, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('Custom Text / Comment to Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(customText, style: const TextStyle(color: Color(0xFF166534), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('1-Tap Copy Custom Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: customText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Custom Text copied to clipboard! Paste it on target link.')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Dynamic Server Elements Section (if any extra) ──────
          if (elements.isNotEmpty) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Extra Task Step Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    ...elements.map((elem) => _buildServerElementWidget(elem)),
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
          const SizedBox(height: 40),
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
        text = 'Task Approved Successfully!';
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
    final type = (element['type'] ?? 'text').toString().toLowerCase();
    final content = (element['contentValue'] ?? element['defaultValue'] ?? element['value'] ?? '').toString();
    final props = (element['properties'] is Map) ? element['properties'] as Map : {};

    if (type.contains('youtube')) {
      final ytId = _extractYouTubeId(content.isNotEmpty ? content : props['url']?.toString() ?? '');

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(label.isNotEmpty ? label : 'YouTube Video Tutorial', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                if (content.isNotEmpty) _launchURL(content);
              },
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  image: ytId != null
                      ? DecorationImage(
                          image: NetworkImage('https://img.youtube.com/vi/$ytId/hqdefault.jpg'),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: Colors.black.withOpacity(0.3)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Tap to Watch Video Tutorial', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (type.contains('audio')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _isPlayingAudio = !_isPlayingAudio);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isPlayingAudio ? 'Playing Buyer Voice Instruction...' : 'Audio Paused'),
                      backgroundColor: const Color(0xFF0284C7),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle),
                  child: Icon(_isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.isNotEmpty ? label : 'Buyer Voice Guidance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0369A1))),
                    const SizedBox(height: 2),
                    Text(_isPlayingAudio ? 'Playing audio instructions...' : 'Tap play button to listen to voice guide', style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type.contains('actionbutton')) {
      final buttonText = props['buttonText']?.toString() ?? 'Open Link & Complete Task';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 1,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              if (content.isNotEmpty) _launchURL(content);
            },
          ),
        ),
      );
    }

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
