import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/platform_logo.dart';

/// Premium 3D Realistic Task Detail & Execution Screen
/// - Exact visual layout matching reference UI image
/// - Dynamic platform adaptation (YouTube, Instagram, Facebook, Google/PlayStore, X, Telegram)
/// - Full lifecycle: Accept Task API, Live Timer, Screenshot Picker, Text Proof, Submit Proof API
/// - Fixed horizontal layout & alignments to prevent any overflows
class TaskDetailPremiumScreen extends StatefulWidget {
  final dynamic task;

  const TaskDetailPremiumScreen({super.key, required this.task});

  @override
  State<TaskDetailPremiumScreen> createState() => _TaskDetailPremiumScreenState();
}

class _TaskDetailPremiumScreenState extends State<TaskDetailPremiumScreen> {
  final _proofTextController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedProofImage;
  bool _isSubmitting = false;
  bool _isTaskAccepted = false;
  bool _isSubmitted = false;
  bool _isSaved = false;
  bool _isAccepting = false;

  // Countdown timer state
  Timer? _countdownTimer;
  int _secondsRemaining = 180;

  @override
  void initState() {
    super.initState();
    final status = _getTaskStatus();
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();
    final isAssignedToUser = widget.task['assignedTo'] != null && widget.task['assignedTo'].toString().isNotEmpty;
    final isAlreadyInMyTasks = taskProvider.myTasks.any((t) => (t['id'] ?? t['_id'] ?? '').toString() == taskId);

    final isSubmittedState = status == 'SUBMITTED' ||
        status == 'UNDER_REVIEW' ||
        status == 'IN_REVIEW' ||
        status == 'APPROVED' ||
        status == 'COMPLETED' ||
        status == 'REJECTED';

    if (isSubmittedState) {
      _isSubmitted = true;
      _isTaskAccepted = false;
    } else if (status == 'ACCEPTED' || status == 'ASSIGNED' || status == 'IN_PROGRESS' || isAssignedToUser || isAlreadyInMyTasks) {
      _isTaskAccepted = true;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _proofTextController.dispose();
    super.dispose();
  }

  String _getTaskStatus() {
    final raw = (widget.task['status'] ??
            widget.task['stage'] ??
            widget.task['currentTabStage'] ??
            widget.task['submissionStatus'] ??
            widget.task['state'] ??
            'AVAILABLE')
        .toString()
        .trim()
        .toUpperCase();
    if (raw == 'DONE' || raw == 'SUCCESS' || raw == 'APPROVED' || raw == 'COMPLETED') return 'APPROVED';
    if (raw == 'REJECTED' || raw == 'CANCELLED' || raw == 'FAILED') return 'REJECTED';
    if (raw == 'UNDER_REVIEW' || raw == 'IN_REVIEW' || raw == 'REVIEW' || raw == 'PENDING_REVIEW') return 'UNDER_REVIEW';
    if (raw == 'SUBMITTED') return 'SUBMITTED';
    if (raw == 'ACCEPTED' || raw == 'ASSIGNED' || raw == 'IN_PROGRESS' || raw == 'CLAIMED') return 'ACCEPTED';
    return raw;
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    final execTime = widget.task['executionTimeSeconds'] ??
        ((widget.task['timeToCompleteHours'] ?? 1) * 3600);
    setState(() => _secondsRemaining = (execTime is int && execTime > 0) ? execTime : 180);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Helper Extractors ──────────────────────────────────────────────────────
  String _getPlatform() {
    final t = widget.task;
    if (t == null) return 'youtube';
    if (t['platform'] != null && t['platform'].toString().trim().isNotEmpty) {
      return t['platform'].toString().toLowerCase().trim();
    }
    final type = (t['taskType'] ?? t['type'] ?? t['serviceCode'] ?? '').toString().toLowerCase();
    String reqStr = '';
    if (t['requirements'] is Map) {
      reqStr = t['requirements'].toString().toLowerCase();
    }
    final metaStr = (t['metadata'] != null) ? t['metadata'].toString().toLowerCase() : '';
    final combined = '$type $reqStr $metaStr';
    if (combined.contains('youtube') || combined.contains('yt_')) return 'youtube';
    if (combined.contains('instagram') || combined.contains('insta')) return 'instagram';
    if (combined.contains('facebook') || combined.contains('fb')) return 'facebook';
    if (combined.contains('google') || combined.contains('playstore') || combined.contains('maps')) return 'google';
    if (combined.contains('twitter') || combined.contains(' x ') || combined.contains('x.com')) return 'x';
    if (combined.contains('telegram')) return 'telegram';
    return 'youtube';
  }

  String _formatTitle() {
    final t = widget.task;
    if (t == null) return 'Task Details';
    if (t['title'] != null && t['title'].toString().trim().isNotEmpty) {
      return t['title'].toString().trim();
    }
    if (t['serviceTitle'] != null && t['serviceTitle'].toString().trim().isNotEmpty) {
      return t['serviceTitle'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['serviceName'] != null && req['serviceName'].toString().trim().isNotEmpty) {
        return req['serviceName'].toString().trim();
      }
      if (req['title'] != null && req['title'].toString().trim().isNotEmpty) {
        return req['title'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('heading') || k.contains('title') || k.contains('name')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    final p = _getPlatform();
    return 'Comment on ${p[0].toUpperCase()}${p.substring(1)} Video';
  }

  String _getBadgeText() {
    final t = widget.task;
    if (t['badge'] != null && t['badge'].toString().trim().isNotEmpty) {
      return t['badge'].toString().trim().toUpperCase();
    }
    final p = _getPlatform();
    final type = (t['taskType'] ?? t['type'] ?? 'COMMENT').toString().toUpperCase();
    if (type.contains('COMMENT')) return '$p COMMENT'.toUpperCase();
    if (type.contains('LIKE')) return '$p LIKE'.toUpperCase();
    if (type.contains('SUBSCRIBE') || type.contains('FOLLOW')) return '$p FOLLOW'.toUpperCase();
    if (type.contains('INSTALL') || type.contains('APP')) return '$p APP'.toUpperCase();
    return '$p TASK'.toUpperCase();
  }

  String _getTaskId() {
    final t = widget.task;
    final id = (t['taskId'] ?? t['task_id'] ?? t['id'] ?? t['_id'] ?? '').toString();
    if (id.isEmpty) return '#TS8921';
    if (id.length > 6) {
      final prefix = _getPlatform() == 'youtube' ? 'YT' : (_getPlatform() == 'instagram' ? 'IG' : 'TS');
      return '#$prefix${id.substring(id.length - 4).toUpperCase()}';
    }
    return '#$id'.toUpperCase();
  }

  double _getReward() {
    final t = widget.task;
    final raw = t['rewardAmount'] ?? t['rewardPerTask'] ?? t['reward'] ?? t['workerReward'] ?? t['payout'];
    if (raw is num) return raw.toDouble();
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    if (t['metadata'] is Map && (t['metadata'] as Map)['rewardSnapshot'] is Map) {
      final snap = (t['metadata'] as Map)['rewardSnapshot'] as Map;
      final tot = snap['totalReward'] ?? snap['baseReward'];
      if (tot != null) {
        final parsed = double.tryParse(tot.toString());
        if (parsed != null) return parsed;
      }
    }
    return 25.0;
  }

  String _getEstimatedTime() {
    final t = widget.task;
    final sec = t['executionTimeSeconds'] ?? ((t['timeToCompleteHours'] ?? 0) * 3600);
    if (sec is int && sec > 0) {
      if (sec < 60) return '$sec sec';
      final min = (sec / 60).round();
      return '$min - ${min + 1} min';
    }
    return '2 - 3 min';
  }

  String _getSuccessRate() {
    final t = widget.task;
    final rate = t['successRate'] ?? t['rating'] ?? 98;
    return '$rate%';
  }

  String _getDescription() {
    final t = widget.task;
    if (t['description'] != null && t['description'].toString().trim().isNotEmpty) {
      return t['description'].toString().trim();
    }
    if (t['instructions'] != null && t['instructions'].toString().trim().isNotEmpty) {
      return t['instructions'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['description'] != null && req['description'].toString().trim().isNotEmpty) {
        return req['description'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('desc') || k.contains('paragraph') || k.contains('instruction')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    final p = _getPlatform();
    return 'Watch the video on ${p[0].toUpperCase()}${p.substring(1)} and post a genuine comment using the text provided.';
  }

  String _getCustomText() {
    final t = widget.task;
    if (t['commentText'] != null && t['commentText'].toString().trim().isNotEmpty) {
      return t['commentText'].toString().trim();
    }
    if (t['generatedContent'] != null && t['generatedContent'].toString().trim().isNotEmpty) {
      return t['generatedContent'].toString().trim();
    }
    if (t['customText'] != null && t['customText'].toString().trim().isNotEmpty) {
      return t['customText'].toString().trim();
    }
    if (t['comment'] != null && t['comment'].toString().trim().isNotEmpty) {
      return t['comment'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['commentText'] != null && req['commentText'].toString().trim().isNotEmpty) {
        return req['commentText'].toString().trim();
      }
      if (req['generatedContent'] != null && req['generatedContent'].toString().trim().isNotEmpty) {
        return req['generatedContent'].toString().trim();
      }
      if (req['customText'] != null && req['customText'].toString().trim().isNotEmpty) {
        return req['customText'].toString().trim();
      }
      if (req['comment'] != null && req['comment'].toString().trim().isNotEmpty) {
        return req['comment'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('textfield') || k.contains('text') || k.contains('comment') || k.contains('custom')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    return 'Amazing video! Very useful information. Thanks for sharing 🙏';
  }

  String _getTargetUrl() {
    final t = widget.task;
    if (t['targetUrl'] != null && t['targetUrl'].toString().trim().isNotEmpty) {
      return t['targetUrl'].toString().trim();
    }
    if (t['url'] != null && t['url'].toString().trim().isNotEmpty) {
      return t['url'].toString().trim();
    }
    if (t['youtubeUrl'] != null && t['youtubeUrl'].toString().trim().isNotEmpty) {
      return t['youtubeUrl'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['targetUrl'] != null && req['targetUrl'].toString().trim().isNotEmpty) {
        return req['targetUrl'].toString().trim();
      }
      if (req['buttonUrl'] != null && req['buttonUrl'].toString().trim().isNotEmpty) {
        return req['buttonUrl'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('actionbutton') || k.contains('url') || k.contains('link') || k.contains('youtube')) && v.isNotEmpty) {
          return v;
        }
      }
    }
    final p = _getPlatform();
    if (p == 'instagram') return 'https://instagram.com';
    if (p == 'facebook') return 'https://facebook.com';
    if (p == 'google') return 'https://play.google.com';
    return 'https://youtube.com';
  }

  String _getVideoTutorialUrl() {
    final t = widget.task;
    if (t['videoTutorialUrl'] != null && t['videoTutorialUrl'].toString().trim().isNotEmpty) {
      return t['videoTutorialUrl'].toString().trim();
    }
    if (t['requirements'] is Map && t['requirements']['videoTutorialUrl'] != null) {
      return t['requirements']['videoTutorialUrl'].toString().trim();
    }
    return '';
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
          SnackBar(content: Text('Opening: $urlString')),
        );
      }
    }
  }

  // ── 1. Accept Task API & Start ─────────────────────────────────────────────
  void _onAcceptAndStart() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();

    setState(() => _isAccepting = true);

    try {
      if (taskId.isNotEmpty) {
        await taskProvider.acceptTask(taskId);
        await taskProvider.startTask(taskId);
        await taskProvider.fetchAvailableTasks();
        await taskProvider.fetchMyTasks('assigned');
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isAccepting = false;
      _isTaskAccepted = true;
      if (widget.task is Map) {
        widget.task['status'] = 'ASSIGNED';
        widget.task['assignedTo'] = 'current_user';
      }
    });

    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Task Accepted! Moved to Accepted Tasks tab. Submit proof below.'),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ── 2. Pick Screenshot Proof ───────────────────────────────────────────────
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

  // ── 3. Submit Task Proof Flow ─────────────────────────────────────────────
  void _onPressSubmit() {
    final textProof = _proofTextController.text.trim();

    if (_selectedProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please tap "Tap to Upload Screenshot Proof" first to attach your proof image.'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _showProofConfirmationDialog(textProof);
  }

  // ── Fullscreen Image Preview Helper ────────────────────────────────────────
  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.92),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(imageFile, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Proof Confirmation Dialog with Full Preview ────────────────────────────
  void _showProofConfirmationDialog(String textProof) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 640),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Submission',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Review your proof before sending',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screenshot Preview
                        if (_selectedProofImage != null) ...[
                          const Text(
                            'Attached Screenshot Proof:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showFullScreenImage(_selectedProofImage!),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _selectedProofImage!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tap to Zoom',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Text Proof Preview
                        if (textProof.isNotEmpty) ...[
                          const Text(
                            'Submitted Notes / Text Proof:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              textProof,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Warning Box: 1-Time Submission
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⚠️', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'One-Time Submission: Once submitted, this task moves to Under Review and the submit option will be locked. You cannot re-submit.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            'Change Proof',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _executeSubmitProof(textProof, dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Yes, Submit Proof',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Execute Submit Proof API ───────────────────────────────────────────────
  void _executeSubmitProof(String textProof, BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
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
      if (widget.task is Map) {
        widget.task['status'] = 'UNDER_REVIEW';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Upload Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      setState(() => _isSubmitting = false);
      return;
    }

    _countdownTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
      _isTaskAccepted = false;
    });

    try {
      await taskProvider.fetchMyTasks('submitted');
      await taskProvider.fetchMyTasks('assigned');
      await taskProvider.fetchAvailableTasks();
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Task Proof Submitted! It is now Under Review.'),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _getPlatformDisplayName() {
    final p = _getPlatform();
    switch (p) {
      case 'youtube':
        return 'YouTube';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'google':
        return 'Play Store';
      case 'x':
        return 'X (Twitter)';
      case 'telegram':
        return 'Telegram';
      default:
        return 'Platform';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatTitle();
    final badge = _getBadgeText();
    final taskId = _getTaskId();
    final reward = _getReward();
    final timeEst = _getEstimatedTime();
    final successRate = _getSuccessRate();
    final description = _getDescription();
    final customText = _getCustomText();
    final targetUrl = _getTargetUrl();
    final videoTutorialUrl = _getVideoTutorialUrl();
    final platformName = _getPlatformDisplayName();
    final status = _getTaskStatus();
    final bool isApprovedOrCompleted = status == 'APPROVED' || status == 'COMPLETED';
    final bool isRejected = status == 'REJECTED';
    final bool isUnderReviewOrSubmitted = _isSubmitted ||
        status == 'SUBMITTED' ||
        status == 'UNDER_REVIEW' ||
        status == 'IN_REVIEW';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: _buildTopAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Banner (For all non-available tasks: Accepted, Submitted, Review, Approved, Rejected) ──
                if (status != 'AVAILABLE') ...[
                  _buildStatusHeaderCard(status),
                  const SizedBox(height: 14),
                ],

                // ── Live Execution Timer Banner (if task accepted and not yet submitted) ──
                if (_isTaskAccepted && !isUnderReviewOrSubmitted && !isApprovedOrCompleted && !isRejected) ...[
                  _buildLiveTimerBanner(),
                  const SizedBox(height: 14),
                ],

                // ── 1. Hero Card (3D Character + Title + Trophy + Stage Pill) ───
                _buildHeroCard(title, description, badge, status),
                const SizedBox(height: 14),

                // ── 2. 4-Item Quick Stats Row ──────────────────────────────
                _buildStatsRow(reward, timeEst, taskId, successRate),
                const SizedBox(height: 16),

                // ── 3. Video Tutorial & Instruction Cards ──────────────────
                _buildVideoCardsSection(videoTutorialUrl),
                const SizedBox(height: 16),

                // ── 4. Task Instructions List with 3D Notepad ──────────────
                _buildTaskInstructionsSection(platformName),
                const SizedBox(height: 16),

                // ── 5. Comment Text (Copy & Paste) Box ─────────────────────
                _buildCommentCopySection(customText),
                const SizedBox(height: 16),

                // ── 6. Where to Comment & Open Platform ────────────────────
                _buildWhereToCommentSection(platformName, targetUrl),
                const SizedBox(height: 16),

                // ── 7. Submit Proof / Status Section ───────────────────────
                if (_isTaskAccepted && !isUnderReviewOrSubmitted && !isApprovedOrCompleted && !isRejected) ...[
                  _buildProofSubmissionCard(),
                  const SizedBox(height: 16),
                ] else if (isApprovedOrCompleted) ...[
                  _buildApprovedSection(reward),
                  const SizedBox(height: 16),
                ] else if (isRejected) ...[
                  _buildRejectedSection(),
                  const SizedBox(height: 16),
                ] else if (isUnderReviewOrSubmitted) ...[
                  _buildUnderReviewSection(reward),
                  const SizedBox(height: 16),
                ],

                // ── 8. Remember / Guidelines Box ───────────────────────────
                _buildRememberSection(),
                const SizedBox(height: 140),
              ],
            ),
          ),

          // ── Fixed Bottom Action Bar ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(targetUrl, platformName, status),
          ),
        ],
      ),
    );
  }

  // ── Top App Bar ────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF6F8FB),
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20),
          ),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Details',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 1),
          Text(
            'Complete the task and earn rewards',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task reported for review to admin.')),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Report Task',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Banner for Accepted / Submitted / Review / Approved / Rejected ──
  Widget _buildStatusHeaderCard(String status) {
    Color cardColor;
    IconData icon;
    String text;

    switch (status) {
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'IN_PROGRESS':
        cardColor = const Color(0xFF0284C7);
        icon = Icons.play_circle_fill_rounded;
        text = 'Task Accepted — In Progress';
        break;
      case 'SUBMITTED':
        cardColor = const Color(0xFFD97706);
        icon = Icons.send_rounded;
        text = 'Task Submitted — Awaiting Verification';
        break;
      case 'UNDER_REVIEW':
      case 'IN_REVIEW':
        cardColor = const Color(0xFFEA580C);
        icon = Icons.hourglass_top_rounded;
        text = 'Task Under Review — Admin Verification';
        break;
      case 'APPROVED':
      case 'COMPLETED':
        cardColor = const Color(0xFF059669);
        icon = Icons.verified_rounded;
        text = 'Task Approved & Reward Credited!';
        break;
      case 'REJECTED':
        cardColor = const Color(0xFFDC2626);
        icon = Icons.cancel_rounded;
        text = 'Task Proof Rejected';
        break;
      default:
        cardColor = const Color(0xFF4F46E5);
        icon = Icons.info_rounded;
        text = 'Status: $status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stage Badge Pill Widget for Hero Card ─────────────────────────────────
  Widget _buildStagePill(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'IN_PROGRESS':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        label = 'ACCEPTED';
        break;
      case 'SUBMITTED':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'SUBMITTED';
        break;
      case 'UNDER_REVIEW':
      case 'IN_REVIEW':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        label = 'UNDER REVIEW';
        break;
      case 'APPROVED':
      case 'COMPLETED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'APPROVED ✓';
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'REJECTED';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Live Execution Timer Banner ────────────────────────────────────────────
  Widget _buildLiveTimerBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4338CA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 22),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TASK IN PROGRESS',
                    style: TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Complete task & submit proof below',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFFDE047), size: 16),
                const SizedBox(width: 5),
                Text(
                  _secondsRemaining > 0 ? _formatTimer(_secondsRemaining) : '00:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Hero Card ───────────────────────────────────────────────────────────
  Widget _buildHeroCard(String title, String description, String badge, String status) {
    final platform = _getPlatform();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Avatar + Platform Icon Box
          _build3DPlatformAvatar(platform),
          const SizedBox(width: 12),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge Pill Row (Category + Stage)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStagePill(status),
                  ],
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3D Golden Trophy Badge
          _build3DTrophyBadge(),
        ],
      ),
    );
  }

  Widget _build3DPlatformAvatar(String platform) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.face_retouching_natural_rounded, size: 34, color: Color(0xFF6D28D9)),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: PlatformLogo(platform: platform, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DTrophyBadge() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.workspace_premium_rounded, size: 26, color: Color(0xFFD97706)),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.signal_cellular_alt_rounded, size: 9, color: Color(0xFF059669)),
              SizedBox(width: 2),
              Text(
                'Easy Task',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. 4-Item Quick Stats Row ──────────────────────────────────────────────
  Widget _buildStatsRow(double reward, String timeEst, String taskId, String successRate) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            label: 'REWARD',
            value: '₹${reward.toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_filled_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            label: 'TIME',
            value: timeEst,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.badge_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            label: 'TASK ID',
            value: taskId,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.track_changes_rounded,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
            label: 'SUCCESS RATE',
            value: successRate,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 3. Video Cards (01 Tutorial & 02 Instructions) ─────────────────────────
  Widget _buildVideoCardsSection(String videoTutorialUrl) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleVideoCard(
            stepNum: '01',
            stepColor: const Color(0xFF7C3AED),
            title: 'Tutorial Video',
            subtitle: 'Step by step guide',
            duration: '03:15',
            gradientColors: const [Color(0xFF2E1065), Color(0xFF581C87)],
            buttonColor: const Color(0xFF7C3AED),
            buttonText: 'Watch Tutorial',
            illustration: '💻',
            onTap: () {
              if (videoTutorialUrl.isNotEmpty) {
                _launchURL(videoTutorialUrl);
              } else {
                _launchURL('https://youtube.com');
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSingleVideoCard(
            stepNum: '02',
            stepColor: const Color(0xFF2563EB),
            title: 'Instructions Video',
            subtitle: 'Important guidelines',
            duration: '01:45',
            gradientColors: const [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
            buttonColor: const Color(0xFF2563EB),
            buttonText: 'Watch Instructions',
            illustration: '💡',
            onTap: () {
              if (videoTutorialUrl.isNotEmpty) {
                _launchURL(videoTutorialUrl);
              } else {
                _launchURL('https://youtube.com');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleVideoCard({
    required String stepNum,
    required Color stepColor,
    required String title,
    required String subtitle,
    required String duration,
    required List<Color> gradientColors,
    required Color buttonColor,
    required String buttonText,
    required String illustration,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stepColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stepNum,
                  style: TextStyle(
                    color: stepColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(illustration, style: const TextStyle(fontSize: 32)),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Task Instructions Section ───────────────────────────────────────────
  Widget _buildTaskInstructionsSection(String platformName) {
    final List<String> steps = [];
    if (widget.task != null && widget.task['requirements'] is Map) {
      final req = widget.task['requirements'] as Map;
      for (int i = 1; i <= 10; i++) {
        if (req['heading_$i'] != null && req['heading_$i'].toString().trim().isNotEmpty) {
          steps.add(req['heading_$i'].toString().trim());
        } else if (req['step_$i'] != null && req['step_$i'].toString().trim().isNotEmpty) {
          steps.add(req['step_$i'].toString().trim());
        }
      }
    }
    if (steps.isEmpty) {
      steps.addAll([
        'Click on the "Open $platformName" button below.',
        'Follow the instructions in the task description carefully.',
        'Copy and paste the comment/text provided if required.',
        'Take a clear screenshot of completed task and submit proof.',
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Task Instructions',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 4),
                    Text(
                      'Checklist',
                      style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1) const SizedBox(height: 10),
          ],

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Make sure your comment is genuine. Spam or fake comments will get rejected.',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Comment Text (Copy & Paste) ─────────────────────────────────────────
  Widget _buildCommentCopySection(String customText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C3AED), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Comment Text',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '(Copy & Paste)',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text('💬', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    customText,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: customText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Comment text copied to clipboard!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: Color(0xFF7C3AED), size: 16),
                        SizedBox(height: 2),
                        Text(
                          'Copy',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF3B82F6)),
              SizedBox(width: 4),
              Text(
                "Don't change the text. Copy and paste as it is.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 6. Where to Comment & Open Platform (Overflow-Proof Layout) ─────────────
  Widget _buildWhereToCommentSection(String platformName, String targetUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('💬', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),

          // Middle Text (Expanded so it wraps and never overflows)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Where to Comment',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'On $platformName – Video/Post Section',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Button (Fixed padding & shrink-wrapped)
          InkWell(
            onTap: () => _launchURL(targetUrl),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Open $platformName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 7. Submit Proof Card (Shown when task is accepted) ──────────────────────
  Widget _buildProofSubmissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: Color(0xFF4F46E5), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Submit Proof Attachment',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Text('📸', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a screenshot proving you completed the task on the target platform.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
          ),
          const SizedBox(height: 12),

          // Screenshot Picker Box
          GestureDetector(
            onTap: _pickProofScreenshot,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedProofImage != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: _selectedProofImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_selectedProofImage!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to Change',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded, size: 30, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to Upload Screenshot Proof',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(height: 2),
                        const Text('PNG, JPG from gallery', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Text Proof Notes Input
          TextField(
            controller: _proofTextController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Enter your username / comment link / notes (optional)',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onPressSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Submit Task Proof',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Under Review Section (Shown when task proof is submitted) ──────────────
  Widget _buildUnderReviewSection(double reward) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Under Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Proof verification in progress',
                        style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have already submitted proof for this task. Once verified by admin, ₹${reward.toStringAsFixed(2)} will be credited to your wallet.',
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedProofImage != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Submitted Screenshot Proof:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullScreenImage(_selectedProofImage!),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(_selectedProofImage!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Zoom',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Approved Section (Shown when task is approved & reward credited) ───────
  Widget _buildApprovedSection(double reward) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Approved!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reward credited: ₹${reward.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Approved',
                      style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Great job! Your submission was verified and ₹${reward.toStringAsFixed(2)} has been credited to your wallet balance.',
                    style: const TextStyle(color: Color(0xFF166534), fontSize: 12, height: 1.35, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rejected Section (Shown when task proof is rejected) ───────────────────
  Widget _buildRejectedSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Proof Rejected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Verification failed',
                        style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.close_rounded, size: 12, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      'Rejected',
                      style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The proof submitted for this task did not meet the required instructions.',
                    style: TextStyle(color: Color(0xFF9F1239), fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. Remember / Guidelines Section ───────────────────────────────────────
  Widget _buildRememberSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Text('🔔', style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remember',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Complete the task exactly as instructed to get your reward credited instantly.',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text('🎁', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  // ── Bottom Fixed Action Bar ────────────────────────────────────────────────
  Widget _buildBottomActionBar(String targetUrl, String platformName, String status) {
    final bool isApproved = status == 'APPROVED' || status == 'COMPLETED';
    final bool isRejected = status == 'REJECTED';
    final bool isUnderReview = _isSubmitted ||
        status == 'SUBMITTED' ||
        status == 'UNDER_REVIEW' ||
        status == 'IN_REVIEW';

    if (isApproved || isRejected || isUnderReview) {
      final Color btnColor = isApproved
          ? const Color(0xFF059669)
          : (isRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706));
      final IconData btnIcon = isApproved
          ? Icons.check_circle_rounded
          : (isRejected ? Icons.cancel_rounded : Icons.arrow_back_rounded);
      final String btnLabel = isApproved
          ? 'Back to Tasks (Approved ✓)'
          : (isRejected ? 'Back to Tasks (Rejected)' : 'Back to Tasks (In Review)');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: btnColor, width: 1.5),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(btnIcon, color: btnColor, size: 18),
                  label: Text(
                    btnLabel,
                    style: TextStyle(color: btnColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left: Save Task Bookmark Button
            InkWell(
              onTap: () {
                setState(() => _isSaved = !_isSaved);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isSaved ? 'Task saved to bookmarks!' : 'Task removed from bookmarks.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSaved ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSaved ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                      color: _isSaved ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSaved ? 'Saved' : 'Save Task',
                      style: TextStyle(
                        color: _isSaved ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Right: "Accept Task & Start" or "Submit Proof" Button
            Expanded(
              child: _isTaskAccepted
                  ? InkWell(
                      onTap: _onPressSubmit,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isSubmitting
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Task Proof',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                  : InkWell(
                      onTap: _isAccepting ? null : _onAcceptAndStart,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isAccepting
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Accept Task & Start',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        'Task will be locked for you',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
