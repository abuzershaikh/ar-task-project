import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/platform_logo.dart';
import '../../../shared/widgets/marquee_text.dart';
import '../../../core/services/package_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

/// Premium 3D Realistic Task Detail & Execution Screen
/// - Exact visual layout matching reference UI image
/// - Dynamic platform adaptation (YouTube, Instagram, Facebook, Google/PlayStore, X, Telegram)
/// - Full lifecycle: Accept Task API, Live Timer, Screenshot Picker, Text Proof, Submit Proof API
/// - Fixed horizontal layout & alignments to prevent any overflows
class TaskDetailPremiumScreen extends StatefulWidget {
  final dynamic task;

  const TaskDetailPremiumScreen({super.key, required this.task});

  @override
  State<TaskDetailPremiumScreen> createState() =>
      _TaskDetailPremiumScreenState();
}

class _TaskDetailPremiumScreenState extends State<TaskDetailPremiumScreen>
    with WidgetsBindingObserver {
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

  // YouTube watch time tracking state
  int _elapsedWatchSeconds = 0;
  DateTime? _watchStartTime;
  bool _isWatchingOnYouTube = false;
  bool _isWatchCompleted = false;
  Timer? _inAppWatchTimer;

  // Admin Voice Guide Audio Player State
  AudioPlayer? _audioPlayer;
  PlayerState _audioPlayerState = PlayerState.stopped;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isAudioBuffering = false;

  String? _fetchedAppIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchPlayStoreIconIfNeeded();
    final status = _getTaskStatus();
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();
    final isAssignedToUser =
        widget.task['assignedTo'] != null &&
        widget.task['assignedTo'].toString().isNotEmpty;
    final isAlreadyInMyTasks = taskProvider.myTasks.any(
      (t) => (t['id'] ?? t['_id'] ?? '').toString() == taskId,
    );

    final isSubmittedState =
        status == 'SUBMITTED' ||
        status == 'UNDER_REVIEW' ||
        status == 'IN_REVIEW' ||
        status == 'APPROVED' ||
        status == 'COMPLETED' ||
        status == 'REJECTED';

    if (isSubmittedState) {
      _isSubmitted = true;
      _isTaskAccepted = false;
      _isWatchCompleted = true;
    } else if (status == 'ACCEPTED' ||
        status == 'ASSIGNED' ||
        status == 'IN_PROGRESS' ||
        isAssignedToUser ||
        isAlreadyInMyTasks) {
      _isTaskAccepted = true;
      _startTimer();
      _loadWatchTimeState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inAppWatchTimer?.cancel();
    _countdownTimer?.cancel();
    _proofTextController.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isWatchingOnYouTube &&
        !_isWatchCompleted) {
      _handleReturnFromYouTube();
    }
  }

  bool _isYouTubeTask() {
    final p = _getPlatform();
    if (p == 'youtube') return true;
    final target = _getTargetUrl().toLowerCase();
    return target.contains('youtube.com') || target.contains('youtu.be');
  }

  bool _isCommentRequiredTask() {
    final t = widget.task;
    if (t == null) return false;
    final type = (t['taskType'] ?? t['type'] ?? t['serviceCode'] ?? '')
        .toString()
        .toUpperCase();

    // Instagram Combo is strictly Like + Follow, NO COMMENT!
    if (type.contains('INSTA') && type.contains('COMBO')) {
      return false;
    }

    // Instagram Follow or Like only
    if (type == 'INSTAGRAM_FOLLOW' ||
        type == 'INSTAGRAM_LIKE' ||
        (type.contains('FOLLOW') && !type.contains('COMMENT'))) {
      if (!type.contains('COMMENT') && !type.contains('COMBO')) return false;
    }

    // YouTube Subscribe only
    if (type == 'YOUTUBE_SUBSCRIBE' ||
        type == 'YOUTUBE_LIKE' ||
        type == 'YOUTUBE_WATCH_TIME') {
      return false;
    }

    // YouTube Combo DOES require comment!
    if ((type.contains('YT') || type.contains('YOUTUBE')) &&
        type.contains('COMBO')) {
      return true;
    }

    // Check actions if available from backend
    if (t['actions'] is Map) {
      final act = t['actions'] as Map;
      if (act['comment'] == true || act['review'] == true) return true;
      if (act['comment'] == false && act['review'] == false) return false;
    }

    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['actions'] is Map) {
        final act = req['actions'] as Map;
        if (act['comment'] == true || act['review'] == true) return true;
        if (act['comment'] == false && act['review'] == false) return false;
      }
      if (req['aiGeneratorEnabled'] == true) return true;
    }

    // Standard comment and review tasks
    if (type.contains('COMMENT') || type.contains('REVIEW')) return true;

    final p = _getPlatform();
    if (p == 'google_business') {
      if (type.contains('RATING') && !type.contains('REVIEW')) return false;
      return true;
    }
    if (p == 'playstore') {
      if (type.contains('INSTALL') || type.contains('RATING')) return false;
      return true;
    }

    return false;
  }

  int _getRequiredWatchSeconds() {
    final t = widget.task;
    int duration = 0;
    if (t is Map) {
      if (t['videoDurationSeconds'] is int && t['videoDurationSeconds'] > 0) {
        duration = t['videoDurationSeconds'];
      } else if (t['requirements'] is Map &&
          t['requirements']['videoDurationSeconds'] is int &&
          t['requirements']['videoDurationSeconds'] > 0) {
        duration = t['requirements']['videoDurationSeconds'];
      } else if (t['watchTimeSeconds'] is int && t['watchTimeSeconds'] > 0) {
        duration = t['watchTimeSeconds'];
      } else if (t['requirements'] is Map &&
          t['requirements']['watchTimeSeconds'] is int &&
          t['requirements']['watchTimeSeconds'] > 0) {
        duration = t['requirements']['watchTimeSeconds'];
      } else if (t['watchTimeSeconds'] != null) {
        duration = int.tryParse(t['watchTimeSeconds'].toString()) ?? 0;
      }
    }

    // 5-Minute Cap Rule:
    // If video > 5 minutes (300 seconds), required watch time is capped at 300 seconds (5 min).
    // If video <= 5 minutes (300s) and > 0, required watch time is the complete video.
    if (duration > 300) return 300;
    if (duration > 0) return duration;
    return 120; // fallback 2 minutes (120 seconds)
  }

  Future<void> _loadWatchTimeState() async {
    if (!_isYouTubeTask()) {
      setState(() => _isWatchCompleted = true);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();
      final savedElapsed = prefs.getInt('yt_watch_elapsed_$taskId') ?? 0;
      final required = _getRequiredWatchSeconds();
      if (mounted) {
        setState(() {
          _elapsedWatchSeconds = savedElapsed;
          if (_elapsedWatchSeconds >= required) {
            _isWatchCompleted = true;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveWatchTimeProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();
      await prefs.setInt('yt_watch_elapsed_$taskId', _elapsedWatchSeconds);
    } catch (_) {}
  }

  void _startWatchingYouTubeVideo() {
    final targetUrl = _getTargetUrl();
    _watchStartTime = DateTime.now();
    _isWatchingOnYouTube = true;

    _startInAppWatchTimer();
    _launchURL(targetUrl.isNotEmpty ? targetUrl : 'https://youtube.com');
  }

  void _startInAppWatchTimer() {
    _inAppWatchTimer?.cancel();
    _inAppWatchTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final required = _getRequiredWatchSeconds();
      if (_elapsedWatchSeconds >= required) {
        t.cancel();
        if (mounted) {
          setState(() {
            _isWatchCompleted = true;
            _isWatchingOnYouTube = false;
          });
        }
        _saveWatchTimeProgress();
      } else {
        if (mounted) {
          setState(() {
            _elapsedWatchSeconds++;
          });
        }
      }
    });
  }

  void _handleReturnFromYouTube() {
    if (_watchStartTime != null) {
      final secondsAway = DateTime.now().difference(_watchStartTime!).inSeconds;
      _elapsedWatchSeconds += secondsAway;
      _watchStartTime = null;
    }
    _isWatchingOnYouTube = false;
    _saveWatchTimeProgress();

    final required = _getRequiredWatchSeconds();
    if (_elapsedWatchSeconds >= required) {
      if (mounted) {
        setState(() {
          _isWatchCompleted = true;
        });
      }
    } else {
      // User returned before completing the video!
      // Do NOT reveal exact seconds/minutes - strictly instruct user to watch complete video:
      if (mounted) {
        _showPleaseWatchCompleteVideoDialog();
      }
    }
  }

  void _showPleaseWatchCompleteVideoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Please Watch Complete Video!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have not finished watching the video yet! To unlock and submit your task proof, please watch the complete video.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                height: 1.45,
              ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFE11D48),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Proof submission remains locked until you finish watching the complete video.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9F1239),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Wait in App',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 2,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _startWatchingYouTubeVideo();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'Watch Video on YouTube',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  String _getTaskStatus() {
    final raw =
        (widget.task['status'] ??
                widget.task['stage'] ??
                widget.task['currentTabStage'] ??
                widget.task['submissionStatus'] ??
                widget.task['state'] ??
                'AVAILABLE')
            .toString()
            .trim()
            .toUpperCase();
    if (raw == 'DONE' ||
        raw == 'SUCCESS' ||
        raw == 'APPROVED' ||
        raw == 'COMPLETED')
      return 'APPROVED';
    if (raw == 'REJECTED' || raw == 'CANCELLED' || raw == 'FAILED')
      return 'REJECTED';
    if (raw == 'UNDER_REVIEW' ||
        raw == 'IN_REVIEW' ||
        raw == 'REVIEW' ||
        raw == 'PENDING_REVIEW')
      return 'UNDER_REVIEW';
    if (raw == 'SUBMITTED') return 'SUBMITTED';
    if (raw == 'ACCEPTED' ||
        raw == 'ASSIGNED' ||
        raw == 'IN_PROGRESS' ||
        raw == 'CLAIMED')
      return 'ACCEPTED';
    return raw;
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    final execTime =
        widget.task['executionTimeSeconds'] ??
        ((widget.task['timeToCompleteHours'] ?? 1) * 3600);
    setState(
      () => _secondsRemaining = (execTime is int && execTime > 0)
          ? execTime
          : 180,
    );

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
  void _fetchPlayStoreIconIfNeeded() async {
    if (_getPlatform() == 'google_business') return;
    final direct = _getAppIcon();
    if (direct.isNotEmpty && !direct.contains('/assets/icons/')) return;
    final url = _getTargetUrl();
    if (url.contains('play.google.com') ||
        url.contains('market://') ||
        url.contains('id=')) {
      try {
        final response = await http
            .post(
              Uri.parse(
                'http://65.20.77.112:3000/api/v1/buyer/orders/playstore-app-info',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'url': url}),
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['appIcon'] != null &&
              data['appIcon'].toString().isNotEmpty) {
            if (mounted) {
              setState(() {
                _fetchedAppIcon = data['appIcon'].toString().trim();
              });
            }
          }
        }
      } catch (_) {}
    }
  }

  String _getPlatform() {
    final t = widget.task;
    if (t == null) return 'playstore';

    final type = (t['taskType'] ?? t['type'] ?? t['serviceCode'] ?? '')
        .toString()
        .toLowerCase();
    String reqStr = '';
    if (t['requirements'] is Map) {
      reqStr = t['requirements'].toString().toLowerCase();
    }
    final metaStr = (t['metadata'] != null)
        ? t['metadata'].toString().toLowerCase()
        : '';
    final titleStr = (t['title'] ?? t['serviceName'] ?? t['serviceTitle'] ?? '')
        .toString()
        .toLowerCase();
    final descStr = (t['description'] ?? t['body'] ?? '')
        .toString()
        .toLowerCase();
    final targetUrl = _getTargetUrl().toLowerCase();
    final combined = '$type $reqStr $metaStr $titleStr $descStr $targetUrl';

    // 0. Google Business / Maps MUST take priority before Play Store
    if (type.contains('google_business') ||
        type.contains('google_maps') ||
        type.contains('gmb') ||
        titleStr.contains('google business') ||
        titleStr.contains('google maps') ||
        titleStr.contains('business review') ||
        targetUrl.contains('maps.google') ||
        targetUrl.contains('goo.gl/maps') ||
        targetUrl.contains('maps.app.goo.gl') ||
        combined.contains('google_business') ||
        combined.contains('google_maps') ||
        combined.contains('gmb_') ||
        (t['platform'] != null &&
            (t['platform'].toString().toLowerCase().contains('business') ||
                t['platform'].toString().toLowerCase().contains('maps')))) {
      return 'google_business';
    }

    // 1. Play Store & App Install MUST ALWAYS take priority over raw platform tag
    if (type.contains('install') ||
        type.contains('app_install') ||
        titleStr.contains('install') ||
        titleStr.contains('play store') ||
        titleStr.contains('app review') ||
        targetUrl.contains('play.google.com') ||
        targetUrl.contains('market://') ||
        combined.contains('playstore') ||
        combined.contains('google_play') ||
        combined.contains('play_store') ||
        combined.contains('play.google')) {
      return 'playstore';
    }

    if (t['platform'] != null && t['platform'].toString().trim().isNotEmpty) {
      final p = t['platform'].toString().toLowerCase().trim();
      if (p.contains('play') ||
          p.contains('google_play') ||
          p.contains('google') ||
          p.contains('install') ||
          p.contains('app'))
        return 'playstore';
      if (p.contains('instagram') ||
          (p.contains('insta') && !p.contains('install')))
        return 'instagram';
      return p;
    }

    // 2. YouTube
    if (combined.contains('youtube') ||
        combined.contains('yt_') ||
        type.contains('yt'))
      return 'youtube';

    // 3. Instagram (Strict check: ensure word does not contain 'install')
    if (combined.contains('instagram') ||
        (combined.contains('insta') && !combined.contains('install')))
      return 'instagram';

    // 4. Facebook
    if (combined.contains('facebook') || combined.contains('fb'))
      return 'facebook';

    // 5. Google / Maps
    if (combined.contains('google') || combined.contains('maps'))
      return 'playstore';

    // 6. X
    if (combined.contains('twitter') ||
        combined.contains(' x ') ||
        combined.contains('x.com'))
      return 'x';

    // 7. Telegram
    if (combined.contains('telegram')) return 'telegram';

    return 'playstore';
  }

  String _getAppIcon() {
    if (_fetchedAppIcon != null && _fetchedAppIcon!.isNotEmpty) {
      return _fetchedAppIcon!;
    }
    final t = widget.task;
    if (t == null) return '';
    final isPlay = _getPlatform() == 'playstore';

    bool isAllowedIcon(dynamic iconVal) {
      if (iconVal == null) return false;
      final c = iconVal.toString().trim();
      if (c.isEmpty) return false;
      if (isPlay && c.contains('instagram')) return false;
      return true;
    }

    if (isAllowedIcon(t['appIcon'])) {
      return t['appIcon'].toString().trim();
    }
    if (isAllowedIcon(t['icon'])) {
      return t['icon'].toString().trim();
    }
    if (isAllowedIcon(t['imageUrl'])) {
      return t['imageUrl'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (isAllowedIcon(req['appIcon'])) {
        return req['appIcon'].toString().trim();
      }
      if (isAllowedIcon(req['icon'])) {
        return req['icon'].toString().trim();
      }
      if (isAllowedIcon(req['imageUrl'])) {
        return req['imageUrl'].toString().trim();
      }
    }
    if (t['metadata'] is Map) {
      final meta = t['metadata'] as Map;
      if (isAllowedIcon(meta['appIcon'])) {
        return meta['appIcon'].toString().trim();
      }
      if (isAllowedIcon(meta['icon'])) {
        return meta['icon'].toString().trim();
      }
      if (isAllowedIcon(meta['imageUrl'])) {
        return meta['imageUrl'].toString().trim();
      }
    }
    return '';
  }

  String _getAppName() {
    final t = widget.task;
    if (t == null) return '';
    if (t['appName'] != null && t['appName'].toString().trim().isNotEmpty) {
      return t['appName'].toString().trim();
    }
    if (t['requirements'] is Map && t['requirements']['appName'] != null) {
      return t['requirements']['appName'].toString().trim();
    }
    if (t['metadata'] is Map && t['metadata']['appName'] != null) {
      return t['metadata']['appName'].toString().trim();
    }
    return '';
  }

  String _formatTitle() {
    final t = widget.task;
    if (t == null) return 'Task Details';
    final appName = _getAppName();
    final type = (t['taskType'] ?? t['type'] ?? t['serviceCode'] ?? '')
        .toString()
        .toUpperCase();
    final isInstall =
        type.contains('INSTALL') ||
        (t['requirements'] is Map &&
            t['requirements']['serviceName']?.toString().toLowerCase().contains(
                  'install',
                ) ==
                true);

    if (appName.isNotEmpty) {
      if (isInstall) {
        return 'Install & Open: $appName 📱';
      }
      return 'Rate & Review: $appName ⭐⭐⭐⭐⭐';
    }
    if (t['title'] != null && t['title'].toString().trim().isNotEmpty) {
      return t['title'].toString().trim();
    }
    if (t['serviceTitle'] != null &&
        t['serviceTitle'].toString().trim().isNotEmpty) {
      return t['serviceTitle'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['serviceName'] != null &&
          req['serviceName'].toString().trim().isNotEmpty) {
        return req['serviceName'].toString().trim();
      }
      if (req['title'] != null && req['title'].toString().trim().isNotEmpty) {
        return req['title'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('heading') ||
                k.contains('title') ||
                k.contains('name')) &&
            v.isNotEmpty) {
          return v;
        }
      }
    }
    final p = _getPlatform();
    if (p == 'google_business') {
      final tUpper =
          (widget.task['taskType'] ??
                  widget.task['type'] ??
                  widget.task['serviceCode'] ??
                  '')
              .toString()
              .toUpperCase();
      if (tUpper.contains('REVIEW')) {
        return '5-Star Rating & Review on Google Maps ⭐⭐⭐⭐⭐';
      }
      return '5-Star Rating on Google Maps ⭐⭐⭐⭐⭐';
    }
    if (p == 'playstore') {
      final tUpper =
          (widget.task['taskType'] ??
                  widget.task['type'] ??
                  widget.task['serviceCode'] ??
                  '')
              .toString()
              .toUpperCase();
      if (tUpper.contains('INSTALL')) {
        return 'Install & Open App from Play Store 📱';
      }
      return '5-Star Rating & App Review on Play Store ⭐⭐⭐⭐⭐';
    }
    if (p == 'instagram') {
      final tUpper =
          (widget.task['taskType'] ??
                  widget.task['type'] ??
                  widget.task['serviceCode'] ??
                  '')
              .toString()
              .toUpperCase();
      if (tUpper.contains('COMBO')) return 'Instagram Combo: Like & Follow 📸';
      if (tUpper.contains('LIKE')) return 'Like Instagram Post / Reel ❤️';
      if (tUpper.contains('COMMENT')) return 'Comment on Instagram Post 💬';
      return 'Instagram Task (Follow & Like) 📸';
    }
    if (p == 'youtube') {
      final tUpper =
          (widget.task['taskType'] ??
                  widget.task['type'] ??
                  widget.task['serviceCode'] ??
                  '')
              .toString()
              .toUpperCase();
      if (tUpper.contains('COMBO'))
        return 'YouTube Combo: Watch, Like, Sub & Comment 🎬';
      if (tUpper.contains('COMMENT')) return 'Comment on YouTube Video 💬';
      if (tUpper.contains('SUB')) return 'Subscribe to YouTube Channel 🔔';
      if (tUpper.contains('LIKE')) return 'Like YouTube Video 👍';
      return 'Watch & Engage on YouTube 🎬';
    }
    return 'Complete ${p[0].toUpperCase()}${p.substring(1)} Task';
  }

  String _getBadgeText() {
    final t = widget.task;
    final p = _getPlatform();
    if (t['badge'] != null && t['badge'].toString().trim().isNotEmpty) {
      final b = t['badge'].toString().trim().toUpperCase();
      if (!b.contains('INSTA') || p == 'instagram') {
        return b;
      }
    }
    final type = (t['taskType'] ?? t['type'] ?? t['serviceCode'] ?? 'COMMENT')
        .toString()
        .toUpperCase();
    if (p == 'google_business') {
      if (type.contains('REVIEW')) {
        return 'GOOGLE MAPS REVIEW';
      }
      return 'GOOGLE MAPS RATING';
    }
    if (p == 'playstore' ||
        type.contains('PLAYSTORE') ||
        type.contains('GOOGLE_PLAY') ||
        type.contains('APP_INSTALL') ||
        type.contains('INSTALL') ||
        type.contains('APP_REVIEW') ||
        type.contains('RATING')) {
      if (type.contains('INSTALL') ||
          (t['title'] ?? '').toString().toLowerCase().contains('install')) {
        return 'PLAY STORE APP';
      }
      return 'PLAY STORE REVIEW';
    }
    if (type.contains('INSTA') && type.contains('COMBO'))
      return 'LIKE + FOLLOW';
    if ((type.contains('YT') || type.contains('YOUTUBE')) &&
        type.contains('COMBO'))
      return 'LIKE + SUB + COMMENT';
    if (type.contains('COMBO')) return '$p COMBO'.toUpperCase();
    if (type.contains('COMMENT')) return '$p COMMENT'.toUpperCase();
    if (type.contains('LIKE')) return '$p LIKE'.toUpperCase();
    if (type.contains('SUBSCRIBE') || type.contains('FOLLOW'))
      return '$p FOLLOW'.toUpperCase();
    if (type.contains('INSTALL') || type.contains('APP'))
      return 'PLAY STORE APP';
    return '$p TASK'.toUpperCase();
  }

  String _getTaskId() {
    final t = widget.task;
    final id = (t['taskId'] ?? t['task_id'] ?? t['id'] ?? t['_id'] ?? '')
        .toString();
    if (id.isEmpty) return '#TS8921';
    if (id.length > 6) {
      final p = _getPlatform();
      final prefix = p == 'youtube'
          ? 'YT'
          : (p == 'instagram'
              ? 'IG'
              : (p == 'google_business'
                  ? 'GM'
                  : (p == 'playstore' ? 'GP' : 'TS')));
      return '#$prefix${id.substring(id.length - 4).toUpperCase()}';
    }
    return '#$id'.toUpperCase();
  }

  double _getReward() {
    final t = widget.task;
    final raw =
        t['rewardAmount'] ??
        t['rewardPerTask'] ??
        t['reward'] ??
        t['workerReward'] ??
        t['payout'];
    if (raw is num) return raw.toDouble();
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    if (t['metadata'] is Map &&
        (t['metadata'] as Map)['rewardSnapshot'] is Map) {
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
    final sec =
        t['executionTimeSeconds'] ?? ((t['timeToCompleteHours'] ?? 0) * 3600);
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
    if (t['description'] != null &&
        t['description'].toString().trim().isNotEmpty) {
      return t['description'].toString().trim();
    }
    if (t['instructions'] != null &&
        t['instructions'].toString().trim().isNotEmpty) {
      return t['instructions'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['description'] != null &&
          req['description'].toString().trim().isNotEmpty) {
        return req['description'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('desc') ||
                k.contains('paragraph') ||
                k.contains('instruction')) &&
            v.isNotEmpty) {
          return v;
        }
      }
    }
    final p = _getPlatform();
    if (p == 'google_business') {
      final tUpper =
          (widget.task['taskType'] ??
                  widget.task['type'] ??
                  widget.task['serviceCode'] ??
                  '')
              .toString()
              .toUpperCase();
      if (tUpper.contains('REVIEW')) {
        return 'Open Google Maps listing, give 5-star rating ⭐⭐⭐⭐⭐ and write the copied genuine review.';
      }
      return 'Open Google Maps listing and give a 5-star rating ⭐⭐⭐⭐⭐.';
    }
    if (p == 'playstore') {
      return 'Open the App on Google Play Store, give 5-star rating ⭐⭐⭐⭐⭐ and submit genuine review text.';
    }
    return 'Watch the video on ${p[0].toUpperCase()}${p.substring(1)} and post a genuine comment using the text provided.';
  }

  String _getCustomText() {
    return _sanitizeWorkerReview(_getRawCustomText());
  }

  String _getRawCustomText() {
    final t = widget.task;
    if (t['commentText'] != null &&
        t['commentText'].toString().trim().isNotEmpty) {
      return t['commentText'].toString().trim();
    }
    if (t['generatedContent'] != null &&
        t['generatedContent'].toString().trim().isNotEmpty) {
      return t['generatedContent'].toString().trim();
    }
    if (t['customText'] != null &&
        t['customText'].toString().trim().isNotEmpty) {
      return t['customText'].toString().trim();
    }
    if (t['comment'] != null && t['comment'].toString().trim().isNotEmpty) {
      return t['comment'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['commentText'] != null &&
          req['commentText'].toString().trim().isNotEmpty) {
        return req['commentText'].toString().trim();
      }
      if (req['generatedContent'] != null &&
          req['generatedContent'].toString().trim().isNotEmpty) {
        return req['generatedContent'].toString().trim();
      }
      if (req['customText'] != null &&
          req['customText'].toString().trim().isNotEmpty) {
        return req['customText'].toString().trim();
      }
      if (req['comment'] != null &&
          req['comment'].toString().trim().isNotEmpty) {
        return req['comment'].toString().trim();
      }
      for (final entry in req.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value.toString().trim();
        if ((k.contains('textfield') ||
                k.contains('text') ||
                k.contains('comment') ||
                k.contains('custom')) &&
            v.isNotEmpty) {
          return v;
        }
      }
    }
    final p = _getPlatform();
    if (p == 'google_business') {
      return 'Excellent service and great experience! Very polite and professional staff.';
    }
    if (p == 'playstore') {
      return 'Super smooth app with fantastic UI! Very fast and helpful.';
    }
    return 'Amazing video! Very useful information. Thanks for sharing.';
  }

  String _sanitizeWorkerReview(String text) {
    return text
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}⭐★🌟✨🌠🎖️🏅🏆💯🔥👍👎]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\b5\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b5\s*\/\s*5\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfive\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b5-star\s*(rating)?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfull\s*5\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+([.,!?])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _getTargetUrl() {
    final t = widget.task;
    String rawUrl = '';
    if (t['targetUrl'] != null && t['targetUrl'].toString().trim().isNotEmpty) {
      rawUrl = t['targetUrl'].toString().trim();
    } else if (t['url'] != null && t['url'].toString().trim().isNotEmpty) {
      rawUrl = t['url'].toString().trim();
    } else if (t['packageId'] != null &&
        t['packageId'].toString().trim().isNotEmpty) {
      rawUrl = t['packageId'].toString().trim();
    } else if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['targetUrl'] != null &&
          req['targetUrl'].toString().trim().isNotEmpty) {
        rawUrl = req['targetUrl'].toString().trim();
      } else if (req['packageId'] != null &&
          req['packageId'].toString().trim().isNotEmpty) {
        rawUrl = req['packageId'].toString().trim();
      } else if (req['packageName'] != null &&
          req['packageName'].toString().trim().isNotEmpty) {
        rawUrl = req['packageName'].toString().trim();
      } else if (req['buttonUrl'] != null &&
          req['buttonUrl'].toString().trim().isNotEmpty) {
        rawUrl = req['buttonUrl'].toString().trim();
      } else {
        for (final entry in req.entries) {
          final k = entry.key.toString().toLowerCase();
          final v = entry.value.toString().trim();
          if ((k.contains('actionbutton') ||
                  k.contains('url') ||
                  k.contains('link') ||
                  k.contains('package')) &&
              v.isNotEmpty) {
            rawUrl = v;
            break;
          }
        }
      }
    }
    if (rawUrl.isNotEmpty) {
      if (rawUrl.contains('.') &&
          !rawUrl.contains('/') &&
          !rawUrl.startsWith('http')) {
        return 'https://play.google.com/store/apps/details?id=$rawUrl';
      }
      return rawUrl;
    }
    final p = _getPlatform();
    if (p == 'google_business') return 'https://maps.google.com';
    if (p == 'instagram') return 'https://instagram.com';
    if (p == 'facebook') return 'https://facebook.com';
    if (p == 'playstore' || p == 'google')
      return 'https://play.google.com/store';
    return 'https://youtube.com';
  }

  String _getVideoTutorialUrl() {
    final t = widget.task;
    if (t['instructionVideoUrl'] != null &&
        t['instructionVideoUrl'].toString().trim().isNotEmpty) {
      return t['instructionVideoUrl'].toString().trim();
    }
    if (t['instruction_video_url'] != null &&
        t['instruction_video_url'].toString().trim().isNotEmpty) {
      return t['instruction_video_url'].toString().trim();
    }
    if (t['videoTutorialUrl'] != null &&
        t['videoTutorialUrl'].toString().trim().isNotEmpty) {
      return t['videoTutorialUrl'].toString().trim();
    }
    if (t['video_tutorial_url'] != null &&
        t['video_tutorial_url'].toString().trim().isNotEmpty) {
      return t['video_tutorial_url'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['instructionVideoUrl'] != null &&
          req['instructionVideoUrl'].toString().trim().isNotEmpty) {
        return req['instructionVideoUrl'].toString().trim();
      }
      if (req['instruction_video_url'] != null &&
          req['instruction_video_url'].toString().trim().isNotEmpty) {
        return req['instruction_video_url'].toString().trim();
      }
      if (req['videoTutorialUrl'] != null &&
          req['videoTutorialUrl'].toString().trim().isNotEmpty) {
        return req['videoTutorialUrl'].toString().trim();
      }
      if (req['video_tutorial_url'] != null &&
          req['video_tutorial_url'].toString().trim().isNotEmpty) {
        return req['video_tutorial_url'].toString().trim();
      }
    }
    return '';
  }

  String _extractAudioGuideUrl() {
    final t = widget.task;
    if (t == null) return '';
    if (t['audioGuideUrl'] != null &&
        t['audioGuideUrl'].toString().trim().isNotEmpty) {
      return t['audioGuideUrl'].toString().trim();
    }
    if (t['audio_guide_url'] != null &&
        t['audio_guide_url'].toString().trim().isNotEmpty) {
      return t['audio_guide_url'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['audioGuideUrl'] != null &&
          req['audioGuideUrl'].toString().trim().isNotEmpty) {
        return req['audioGuideUrl'].toString().trim();
      }
      if (req['audio_guide_url'] != null &&
          req['audio_guide_url'].toString().trim().isNotEmpty) {
        return req['audio_guide_url'].toString().trim();
      }
    }
    if (t['metadata'] is Map) {
      final meta = t['metadata'] as Map;
      if (meta['audioGuideUrl'] != null &&
          meta['audioGuideUrl'].toString().trim().isNotEmpty) {
        return meta['audioGuideUrl'].toString().trim();
      }
      if (meta['audio_guide_url'] != null &&
          meta['audio_guide_url'].toString().trim().isNotEmpty) {
        return meta['audio_guide_url'].toString().trim();
      }
    }
    return '';
  }

  String _extractAdminInstructions() {
    final t = widget.task;
    if (t == null) return '';
    if (t['adminInstructions'] != null &&
        t['adminInstructions'].toString().trim().isNotEmpty) {
      return t['adminInstructions'].toString().trim();
    }
    if (t['admin_instructions'] != null &&
        t['admin_instructions'].toString().trim().isNotEmpty) {
      return t['admin_instructions'].toString().trim();
    }
    if (t['requirements'] is Map) {
      final req = t['requirements'] as Map;
      if (req['adminInstructions'] != null &&
          req['adminInstructions'].toString().trim().isNotEmpty) {
        return req['adminInstructions'].toString().trim();
      }
      if (req['admin_instructions'] != null &&
          req['admin_instructions'].toString().trim().isNotEmpty) {
        return req['admin_instructions'].toString().trim();
      }
    }
    if (t['metadata'] is Map) {
      final meta = t['metadata'] as Map;
      if (meta['adminInstructions'] != null &&
          meta['adminInstructions'].toString().trim().isNotEmpty) {
        return meta['adminInstructions'].toString().trim();
      }
      if (meta['admin_instructions'] != null &&
          meta['admin_instructions'].toString().trim().isNotEmpty) {
        return meta['admin_instructions'].toString().trim();
      }
    }
    return '';
  }

  Future<void> _initAudioPlayer() async {
    if (_audioPlayer != null) return;
    _audioPlayer = AudioPlayer();

    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _audioPlayerState = state);
    });

    _audioPlayer!.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _audioDuration = newDuration);
    });

    _audioPlayer!.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _audioPosition = newPosition);
    });

    _audioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _audioPosition = Duration.zero;
          _audioPlayerState = PlayerState.stopped;
        });
      }
    });
  }

  Future<void> _toggleAudioPlayback(String url) async {
    if (url.trim().isEmpty) return;
    await _initAudioPlayer();

    if (_audioPlayerState == PlayerState.playing) {
      await _audioPlayer!.pause();
    } else if (_audioPlayerState == PlayerState.paused) {
      await _audioPlayer!.resume();
    } else {
      try {
        setState(() => _isAudioBuffering = true);
        await _audioPlayer!.play(UrlSource(url.trim()));
      } catch (e) {
        debugPrint('[AudioPlayer Error] $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not play audio guide: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isAudioBuffering = false);
      }
    }
  }

  Future<void> _seekAudio(double value) async {
    if (_audioPlayer != null && _audioDuration.inMilliseconds > 0) {
      final newPos = Duration(
        milliseconds: (value * _audioDuration.inMilliseconds).round(),
      );
      await _audioPlayer!.seek(newPos);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String? _extractYouTubeId(String url) {
    if (url.isEmpty) return null;
    final regExp = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri uri = Uri.parse(
      urlString.startsWith('http') ? urlString : 'https://$urlString',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Opening: $urlString')));
      }
    }
  }

  // ── 1. Accept Task API & Start ─────────────────────────────────────────────
  void _onAcceptAndStart() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskId = (widget.task['id'] ?? widget.task['_id'] ?? '').toString();

    setState(() => _isAccepting = true);

    bool success = false;
    String? errorMsg;

    try {
      if (taskId.isNotEmpty) {
        final taskMap = widget.task is Map<String, dynamic>
            ? (widget.task as Map<String, dynamic>)
            : (widget.task is Map ? Map<String, dynamic>.from(widget.task) : null);
        success = await taskProvider.acceptTask(taskId, taskData: taskMap);
        if (success) {
          await taskProvider.startTask(taskId);
          await taskProvider.fetchAvailableTasks();
          await taskProvider.fetchMyTasks('assigned');
        } else {
          errorMsg = (taskProvider.error != null && taskProvider.error!.isNotEmpty)
              ? taskProvider.error!
              : 'Failed to accept task';
        }
      }
    } catch (e) {
      errorMsg = e.toString().replaceAll('Exception: ', '');
    }

    if (!mounted) return;

    if (!success) {
      setState(() => _isAccepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'You cannot accept this task.'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

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
        content: Text(
          '✓ Task Accepted! Moved to Accepted Tasks tab. Submit proof below.',
        ),
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
    // YouTube Watch Time Check (Strict: Proof cannot be submitted until full watch requirement is met)
    if (_isYouTubeTask() && !_isWatchCompleted) {
      _showPleaseWatchCompleteVideoDialog();
      return;
    }

    final textProof = _proofTextController.text.trim();

    if (_selectedProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Please tap "Tap to Upload Screenshot Proof" first to attach your proof image.',
          ),
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
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
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
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
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
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                          size: 22,
                        ),
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
                            onTap: () =>
                                _showFullScreenImage(_selectedProofImage!),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tap to Zoom',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
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
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              textProof,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                              ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                          onPressed: () =>
                              _executeSubmitProof(textProof, dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
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

    // Pre-flight check: If this is an App Install task, verify it is actually installed!
    if (widget.task is Map &&
        PackageTrackerService.isAppInstallTask(
          Map<String, dynamic>.from(widget.task),
        )) {
      final pkg =
          PackageTrackerService.extractPackageName(
            widget.task['requirements'],
          ) ??
          PackageTrackerService.extractPackageName(widget.task['metadata']) ??
          PackageTrackerService.extractPackageName(
            widget.task['targetUrl'] ?? widget.task['url'],
          );
      if (pkg != null && pkg.isNotEmpty) {
        final isInstalled = await PackageTrackerService.isAppInstalled(pkg);
        if (!isInstalled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ App Not Installed: Please install "$pkg" from Google Play Store before submitting proof!',
                ),
                backgroundColor: const Color(0xFFDC2626),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          setState(() => _isSubmitting = false);
          return;
        }
      }
    }

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
      await taskProvider.fetchMyTasks('under_review', forceRefresh: true);
      await taskProvider.fetchMyTasks('assigned', forceRefresh: true);
      await taskProvider.fetchAvailableTasks();
    } catch (_) {}

    if (!mounted) return;
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
      case 'google_business':
      case 'google_maps':
        return 'Google Maps';
      case 'youtube':
        return 'YouTube';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'playstore':
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
    final audioGuideUrl = _extractAudioGuideUrl();
    final platformName = _getPlatformDisplayName();
    final status = _getTaskStatus();
    final bool isApprovedOrCompleted =
        status == 'APPROVED' || status == 'COMPLETED';
    final bool isRejected = status == 'REJECTED';
    final bool isUnderReviewOrSubmitted =
        _isSubmitted ||
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
                if (_isTaskAccepted &&
                    !isUnderReviewOrSubmitted &&
                    !isApprovedOrCompleted &&
                    !isRejected) ...[
                  _buildLiveTimerBanner(),
                  const SizedBox(height: 14),
                ],

                // ── 1. Hero Card (3D Character + Title + Trophy + Stage Pill) ───
                _buildHeroCard(title, description, badge, status),
                const SizedBox(height: 14),

                // ── 2. 4-Item Quick Stats Row ──────────────────────────────
                _buildStatsRow(reward, timeEst, taskId, successRate),
                const SizedBox(height: 16),

                // ── 2.5 Admin Voice Guide Audio Player ──────────────────────
                if (audioGuideUrl.isNotEmpty) ...[
                  _buildAdminVoiceGuideSection(audioGuideUrl),
                  const SizedBox(height: 16),
                ],

                // ── 3. Video Tutorial & Instruction Cards ──────────────────
                _buildVideoCardsSection(videoTutorialUrl),
                const SizedBox(height: 16),

                // ── 4. Task Instructions List with 3D Notepad ──────────────
                _buildTaskInstructionsSection(platformName),
                const SizedBox(height: 16),

                // ── 5. Comment Text (Copy & Paste) Box (Only when task requires comment) ─
                if (_isCommentRequiredTask()) ...[
                  _buildCommentCopySection(customText),
                  const SizedBox(height: 16),
                ],

                // ── 6. Where to Perform / Comment & Open Platform ──────────
                _buildWhereToCommentSection(platformName, targetUrl),
                const SizedBox(height: 16),

                // ── 7. Submit Proof / Status Section ───────────────────────
                if (_isTaskAccepted &&
                    !isUnderReviewOrSubmitted &&
                    !isApprovedOrCompleted &&
                    !isRejected) ...[
                  if (_isYouTubeTask() && !_isWatchCompleted) ...[
                    _buildYouTubeWatchCard(targetUrl),
                    const SizedBox(height: 16),
                    // Semi-transparent locked proof card (user sees what proof to submit, but locked until watched)
                    _buildLockedProofSubmissionCard(),
                    const SizedBox(height: 16),
                  ] else ...[
                    if (_isYouTubeTask()) ...[
                      _buildYouTubeWatchCompletedBanner(),
                      const SizedBox(height: 12),
                    ],
                    _buildProofSubmissionCard(),
                    const SizedBox(height: 16),
                  ],
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

                // ── App Install Retention Warning Banner ───
                if (widget.task is Map &&
                    PackageTrackerService.isAppInstallTask(
                      Map<String, dynamic>.from(widget.task),
                    )) ...[
                  _buildRetentionNoticeBanner(),
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
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
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
                const SnackBar(
                  content: Text('Task reported for review to admin.'),
                ),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFBBF24),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'TASK IN PROGRESS',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      SizedBox(
                        width: double.infinity,
                        child: MarqueeText(
                          text: 'Complete task & submit proof below',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFFFDE047),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  _secondsRemaining > 0
                      ? _formatTimer(_secondsRemaining)
                      : '00:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
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
  Widget _buildHeroCard(
    String title,
    String description,
    String badge,
    String status,
  ) {
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
                // Badge Pill Wrap (Category + Stage)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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
    final appIcon = _getAppIcon();
    if (appIcon.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                appIcon,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    PlatformLogo(platform: platform, size: 36),
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: PlatformLogo(platform: platform, size: 14),
              ),
            ),
          ],
        ),
      );
    }

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
          const Icon(
            Icons.face_retouching_natural_rounded,
            size: 34,
            color: Color(0xFF6D28D9),
          ),
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
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 26,
              color: Color(0xFFD97706),
            ),
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
              Icon(
                Icons.signal_cellular_alt_rounded,
                size: 9,
                color: Color(0xFF059669),
              ),
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
  Widget _buildStatsRow(
    double reward,
    String timeEst,
    String taskId,
    String successRate,
  ) {
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

  // ── 3. Instructions Video Card ─────────────────────────────────────────────
  Widget _buildVideoCardsSection(String videoTutorialUrl) {
    final ytId = _extractYouTubeId(videoTutorialUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Subtitle + Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions Video',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      'Watch step-by-step instructions before starting',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00875A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00875A).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Guide',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00875A),
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Video Preview Container
          InkWell(
            onTap: () {
              if (videoTutorialUrl.isNotEmpty) {
                _launchURL(videoTutorialUrl);
              } else {
                _launchURL('https://youtube.com');
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 145,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E3A8A),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: ytId != null
                    ? DecorationImage(
                        image: NetworkImage(
                          'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (ytId != null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                  // Glowing Center Play Button
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.55),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  // Duration / badge
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '01:45',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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

          // Action Button
          InkWell(
            onTap: () {
              if (videoTutorialUrl.isNotEmpty) {
                _launchURL(videoTutorialUrl);
              } else {
                _launchURL('https://youtube.com');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Watch Instructions Video',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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

  // ── 3.5 Admin Voice Guide Player ──────────────────────────────────────────
  Widget _buildAdminVoiceGuideSection(String audioGuideUrl) {
    final bool isPlaying = _audioPlayerState == PlayerState.playing;
    final double maxSec = _audioDuration.inMilliseconds > 0
        ? _audioDuration.inMilliseconds.toDouble()
        : 1.0;
    final double currentSec = _audioPosition.inMilliseconds.toDouble().clamp(
      0.0,
      maxSec,
    );
    final double sliderValue = (maxSec > 0)
        ? (currentSec / maxSec).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF818CF8).withOpacity(0.5),
                  ),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Voice Instruction',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Listen to complete this task correctly',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlaying) ...[
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      isPlaying ? 'PLAYING' : 'AUDIO GUIDE',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Player Controls Row
          Row(
            children: [
              // Big Play / Pause Button
              GestureDetector(
                onTap: () => _toggleAudioPlayback(audioGuideUrl),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isAudioBuffering
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Slider & Duration Row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: const Color(0xFF38BDF8),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: sliderValue,
                        onChanged: (val) => _seekAudio(val),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_audioPosition),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF38BDF8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _audioDuration.inSeconds > 0
                                ? _formatDuration(_audioDuration)
                                : '--:--',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 10.5,
                            ),
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
    );
  }

  // ── 4. Task Instructions Section ───────────────────────────────────────────
  Widget _buildTaskInstructionsSection(String platformName) {
    final List<String> steps = [];
    final bool isPlayStore = _getPlatform() == 'playstore';
    final adminInstructions = _extractAdminInstructions();
    if (adminInstructions.isNotEmpty) {
      final customLines = adminInstructions
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (customLines.isNotEmpty) {
        steps.addAll(customLines);
      }
    }

    if (steps.isEmpty &&
        widget.task != null &&
        widget.task['requirements'] is Map) {
      final req = widget.task['requirements'] as Map;
      for (int i = 1; i <= 10; i++) {
        if (req['heading_$i'] != null &&
            req['heading_$i'].toString().trim().isNotEmpty) {
          steps.add(req['heading_$i'].toString().trim());
        } else if (req['step_$i'] != null &&
            req['step_$i'].toString().trim().isNotEmpty) {
          steps.add(req['step_$i'].toString().trim());
        }
      }
    }
    final type =
        (widget.task['taskType'] ??
                widget.task['type'] ??
                widget.task['serviceCode'] ??
                '')
            .toString()
            .toUpperCase();
    final bool isInstaCombo = type.contains('INSTA') && type.contains('COMBO');
    final bool isYtCombo =
        (type.contains('YT') || type.contains('YOUTUBE')) &&
        type.contains('COMBO');

    if (steps.isEmpty) {
      if (isInstaCombo) {
        steps.addAll([
          'Click on the "Open Instagram" button below.',
          'Follow the creator profile specified in the link.',
          'Like the latest post or reel of the creator.',
          'Take a clear screenshot showing that you followed the profile and liked the post/reel.',
          'Return to this app and upload the screenshot proof to receive your instant reward.',
        ]);
      } else if (isYtCombo) {
        steps.addAll([
          'Click on the "Watch on YouTube" button below.',
          'Watch the video completely (watch timer will unlock proof submission).',
          'Like the YouTube video and Subscribe to the channel.',
          'Copy the assigned comment text above and post it on the video.',
          'Take a clear screenshot showing your Like, Subscribe, and Comment.',
          'Return to this app and upload the screenshot proof to receive your instant reward.',
        ]);
      } else if (isPlayStore) {
        steps.addAll([
          'Click on the "Open Play Store" button below.',
          'Install or open the application page on Google Play Store.',
          'Give a 5-Star Rating (⭐⭐⭐⭐⭐) to the app.',
          'Copy the provided review text and paste it into the review section.',
          'Post your review and take a clear screenshot showing your 5-star rating & review.',
          'Return to this app and upload the screenshot proof to receive your instant reward.',
        ]);
      } else if (_getPlatform() == 'google_business') {
        final bool isReview = type.contains('REVIEW');
        if (isReview) {
          steps.addAll([
            'Click on the "Open Google Maps" button below.',
            'Locate the business profile on Google Maps.',
            'Give a 5-Star Rating (⭐⭐⭐⭐⭐) to the business.',
            'Copy the provided genuine review text and paste it in the review box.',
            'Post your review and take a clear screenshot showing your rating & review.',
            'Return to this app and upload the screenshot proof to receive your instant reward.',
          ]);
        } else {
          steps.addAll([
            'Click on the "Open Google Maps" button below.',
            'Locate the business profile on Google Maps.',
            'Give a 5-Star Rating (⭐⭐⭐⭐⭐) to the business.',
            'Take a clear screenshot showing your 5-star rating.',
            'Return to this app and upload the screenshot proof to receive your instant reward.',
          ]);
        }
      } else {
        steps.addAll([
          'Click on the "Open $platformName" button below.',
          'Follow the instructions in the task description carefully.',
          'Copy and paste the comment/text provided if required.',
          'Take a clear screenshot of completed task and submit proof.',
        ]);
      }
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
          const Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
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
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF059669),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInstaCombo
                        ? 'Make sure you have followed the profile and liked the post/reel before submitting proof.'
                        : (isYtCombo
                              ? 'Make sure you watch the video, like, subscribe, and post the assigned comment.'
                              : (_getPlatform() == 'google_business'
                                    ? 'Ensure your 5-star rating and review are posted on Google Maps before submitting proof.'
                                    : (isPlayStore
                                          ? 'Ensure your 5-star rating and review are posted on the app page before submitting proof.'
                                          : 'Make sure your submission is genuine. Spam or incomplete tasks will get rejected.'))),
                    style: const TextStyle(
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
    final bool isGoogleBusiness = _getPlatform() == 'google_business';
    final bool isPlayStore = _getPlatform() == 'playstore';
    final bool isReview = isPlayStore || isGoogleBusiness;

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
              Row(
                children: [
                  Icon(
                    isReview
                        ? Icons.star_rate_rounded
                        : Icons.chat_bubble_rounded,
                    color: isGoogleBusiness
                        ? const Color(0xFF2563EB)
                        : (isPlayStore
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF7C3AED)),
                    size: isReview ? 20 : 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReview ? '5-Star Review Text' : 'Comment Text',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGoogleBusiness
                        ? '(Copy & Paste into Google Maps)'
                        : (isPlayStore
                            ? '(Copy & Paste into Play Store)'
                            : '(Copy & Paste)'),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                isReview ? '⭐' : '💬',
                style: const TextStyle(fontSize: 16),
              ),
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
                      SnackBar(
                        content: Text(
                          isReview
                              ? '✓ 5-Star review text copied to clipboard!'
                              : '✓ Comment text copied to clipboard!',
                        ),
                        backgroundColor: isGoogleBusiness
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF059669),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            (isGoogleBusiness
                                    ? const Color(0xFF2563EB)
                                    : (isPlayStore
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF7C3AED)))
                                .withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isGoogleBusiness
                                      ? const Color(0xFF2563EB)
                                      : (isPlayStore
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF7C3AED)))
                                  .withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          color: isGoogleBusiness
                              ? const Color(0xFF2563EB)
                              : (isPlayStore
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF7C3AED)),
                          size: 16,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Copy',
                          style: TextStyle(
                            color: isGoogleBusiness
                                ? const Color(0xFF2563EB)
                                : (isPlayStore
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF7C3AED)),
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

          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isGoogleBusiness
                      ? "Give 5-Star rating ⭐⭐⭐⭐⭐ and paste this review on Google Maps as it is."
                      : (isPlayStore
                          ? "Give 5-Star rating ⭐⭐⭐⭐⭐ and paste this review text as it is."
                          : "Don't change the text. Copy and paste as it is."),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 6. Where to Perform Action & Open Platform (Overflow-Proof Layout) ─────
  Widget _buildWhereToCommentSection(String platformName, String targetUrl) {
    final bool isGoogleBusiness = _getPlatform() == 'google_business';
    final bool isPlayStore = _getPlatform() == 'playstore';
    final bool isCommentReq = _isCommentRequiredTask();
    final type =
        (widget.task['taskType'] ??
                widget.task['type'] ??
                widget.task['serviceCode'] ??
                '')
            .toString()
            .toUpperCase();
    final bool isInstaCombo = type.contains('INSTA') && type.contains('COMBO');

    String headerText = 'Where to Perform Task';
    String subText = 'On $platformName';
    String iconEmoji = '🔗';
    Color iconBg = const Color(0xFFEFF6FF);

    if (isGoogleBusiness) {
      headerText = isCommentReq
          ? 'Where to Rate & Review'
          : 'Where to Rate Business';
      subText = 'On Google Maps Business Profile';
      iconEmoji = '📍';
      iconBg = const Color(0xFFE0F2FE);
    } else if (isPlayStore) {
      headerText = isCommentReq
          ? 'Where to Rate & Review'
          : 'Where to Rate App';
      subText = 'On Google Play Store App Page';
      iconEmoji = '⭐';
      iconBg = const Color(0xFFD1FAE5);
    } else if (isInstaCombo) {
      headerText = 'Where to Like & Follow';
      subText = 'On Instagram Profile & Recent Post/Reel';
      iconEmoji = '📸';
      iconBg = const Color(0xFFFCE7F3);
    } else if (isCommentReq) {
      headerText = 'Where to Comment';
      subText = 'On $platformName – Video/Post Section';
      iconEmoji = '💬';
      iconBg = const Color(0xFFFEF3C7);
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(iconEmoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),

          // Middle Text (Expanded so it wraps and never overflows)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headerText,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subText,
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
            onTap: () {
              if (_isYouTubeTask() && _isTaskAccepted && !_isWatchCompleted) {
                _startWatchingYouTubeVideo();
              } else {
                _launchURL(targetUrl);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGoogleBusiness
                      ? const [Color(0xFF2563EB), Color(0xFF3B82F6)]
                      : (isPlayStore
                          ? const [Color(0xFF059669), Color(0xFF10B981)]
                          : const [Color(0xFFEA580C), Color(0xFFF97316)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isGoogleBusiness
                                ? const Color(0xFF3B82F6)
                                : (isPlayStore
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF97316)))
                            .withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
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

  // ── YouTube Video Watch Requirement Card (Submit proof locked until watched) ──
  Widget _buildYouTubeWatchCard(String targetUrl) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch Complete Video',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Complete watching to unlock proof submission',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFDC2626),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Informational Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF475569),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please watch the full video. Proof attachment and submission will be unlocked after watching.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big "Watch on YouTube" Action Button
          InkWell(
            onTap: _startWatchingYouTubeVideo,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Watch Video on YouTube',
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
          ),
        ],
      ),
    );
  }

  // ── YouTube Watch Completed Banner ──────────────────────────────────────────
  Widget _buildYouTubeWatchCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Watched Successfully! ✓',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Proof submission is now unlocked. Please attach your screenshot below.',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Locked & Semi-Transparent Submit Proof Card ───────────────────────────
  // Shows proof card with semi-transparency so user knows what proof to submit,
  // while keeping it locked with an overlay until the full video is watched.
  Widget _buildLockedProofSubmissionCard() {
    return GestureDetector(
      onTap: _showPleaseWatchCompleteVideoDialog,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Semi-transparent Proof Card (User clearly sees screenshot picker & requirements)
          Opacity(
            opacity: 0.38,
            child: IgnorePointer(
              ignoring: true,
              child: _buildProofSubmissionCard(),
            ),
          ),

          // 2. Centered Floating Lock Badge / Card
          Positioned(
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFF87171),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Submit Proof (Locked)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Watch the complete video to unlock proof attachment and submission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFFFCA5A5),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tap to Watch Complete Video',
                          style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
        border: Border.all(
          color: const Color(0xFF818CF8).withOpacity(0.5),
          width: 1.5,
        ),
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
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
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
                  color: _selectedProofImage != null
                      ? const Color(0xFF10B981)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: _selectedProofImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedProofImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to Change',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 30,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to Upload Screenshot Proof',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'PNG, JPG from gallery',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
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
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Submit Task Proof',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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

  // ── Under Review Section (Shown when task proof is submitted) ──────────────
  Widget _buildUnderReviewSection(double reward) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.4),
          width: 1.5,
        ),
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
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
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
                    Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have already submitted proof for this task. Once verified by admin, ₹${reward.toStringAsFixed(2)} will be credited to your wallet.',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedProofImage != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Submitted Screenshot Proof:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullScreenImage(_selectedProofImage!),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(
                        _selectedProofImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Zoom',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.4),
          width: 1.5,
        ),
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
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Approved',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Great job! Your submission was verified and ₹${reward.toStringAsFixed(2)} has been credited to your wallet balance.',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
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

  // ── Rejected Section (Shown when task proof is rejected) ───────────────────
  Widget _buildRejectedSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.4),
          width: 1.5,
        ),
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
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Rejected',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The proof submitted for this task did not meet the required instructions.',
                    style: TextStyle(
                      color: Color(0xFF9F1239),
                      fontSize: 12,
                      height: 1.35,
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

  // ── Retention Policy Banner for App Install Tasks ──────────────────────────
  Widget _buildRetentionNoticeBanner() {
    final req = (widget.task is Map && widget.task['requirements'] is Map)
        ? widget.task['requirements']
        : {};
    final hours = req['minRetentionHours'] ?? req['min_retention_hours'] ?? 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft Amber warning
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Minimum Retention Requirement',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'You must keep this app installed on your phone for at least $hours hours after completion. If uninstalled early, task rewards will be deducted automatically.',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11.5,
                    height: 1.35,
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
  Widget _buildBottomActionBar(
    String targetUrl,
    String platformName,
    String status,
  ) {
    final bool isApproved = status == 'APPROVED' || status == 'COMPLETED';
    final bool isRejected = status == 'REJECTED';
    final bool isUnderReview =
        _isSubmitted ||
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
          : (isRejected
                ? 'Back to Tasks (Rejected)'
                : 'Back to Tasks (In Review)');

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: btnColor, width: 1.5),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(btnIcon, color: btnColor, size: 18),
                  label: Text(
                    btnLabel,
                    style: TextStyle(
                      color: btnColor,
                      fontWeight: FontWeight.bold,
                    ),
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
                    content: Text(
                      _isSaved
                          ? 'Task saved to bookmarks!'
                          : 'Task removed from bookmarks.',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isSaved
                      ? const Color(0xFFEDE9FE)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSaved
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSaved
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isSaved
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF475569),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSaved ? 'Saved' : 'Save Task',
                      style: TextStyle(
                        color: _isSaved
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Right: "Accept Task & Start" or "Submit Proof" or "Watch on YouTube" Button
            Expanded(
              child: _isTaskAccepted
                  ? (_isYouTubeTask() && !_isWatchCompleted
                        ? InkWell(
                            onTap: _startWatchingYouTubeVideo,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFDC2626),
                                    Color(0xFFEF4444),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFDC2626,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Watch Video on YouTube',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: _onPressSubmit,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF059669),
                                    Color(0xFF10B981),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF059669,
                                    ).withOpacity(0.35),
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
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_upload_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
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
                          ))
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
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
