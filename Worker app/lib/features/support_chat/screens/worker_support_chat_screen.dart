import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' hide PlayerState;
import '../models/worker_support_message.dart';
import '../services/worker_chat_service.dart';
import '../services/support_media_cache.dart';

class WorkerSupportChatScreen extends StatefulWidget {
  const WorkerSupportChatScreen({super.key});

  @override
  State<WorkerSupportChatScreen> createState() => _WorkerSupportChatScreenState();
}

class _WorkerSupportChatScreenState extends State<WorkerSupportChatScreen>
    with TickerProviderStateMixin {
  final _chatService = WorkerChatService.instance;
  final _mediaCache = SupportMediaCache.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AudioPlayer _audioPlayer;

  List<WorkerSupportMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showEmojiRow = false;

  // Audio playing state
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Inline YouTube player
  String? _activeInlineYoutubeId;
  YoutubePlayerController? _ytPlayerController;

  StreamSubscription? _msgSub;
  StreamSubscription? _readSub;
  StreamSubscription? _delSub;
  StreamSubscription? _allDelSub;

  // Animations
  late AnimationController _mascotFloatController;
  late Animation<double> _mascotFloatAnim;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<String> _quickEmojis = ['👋', '👍', '🙏', '😊', '❤️', '🔥', '✅', '✨'];

  // Media file cache map for instant synchronous UI display
  final Map<String, File> _cachedImageFiles = {};

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });

    // 3D Mascot gentle floating animation on empty screen
    _mascotFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _mascotFloatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _mascotFloatController, curve: Curves.easeInOutSine),
    );

    // Online status glowing beacon pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Instantly load messages from local disk cache
    final cached = await _chatService.getCachedMessages();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _messages = cached;
        _isLoading = false;
      });
      _scrollToBottom();
      _preloadCachedImages(cached);
    }

    await _chatService.initSocket();

    // 2. Refresh from server in background and update cache
    await _loadHistory(showLoadingSpinner: cached.isEmpty);

    _msgSub = _chatService.onNewMessage.listen((msg) {
      if (mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
          }
        });
        _scrollToBottom();
        _chatService.markRead();
        _chatService.saveMessagesToCache(_messages);
        if (msg.isImage && msg.mediaUrl != null) {
          _mediaCache.getOrDownloadMedia(msg.mediaUrl!).then((f) {
            if (f != null && mounted) setState(() => _cachedImageFiles[msg.mediaUrl!] = f);
          });
        }
      }
    });

    _readSub = _chatService.onMessagesRead.listen((_) {
      if (mounted) setState(() {});
    });

    _delSub = _chatService.onMessagesDeleted.listen((deletedIds) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => deletedIds.contains(m.id));
        });
        _chatService.saveMessagesToCache(_messages);
      }
    });

    _allDelSub = _chatService.onAllMessagesDeleted.listen((_) {
      if (mounted) {
        setState(() {
          _messages.clear();
        });
        _chatService.saveMessagesToCache([]);
      }
    });
  }

  void _preloadCachedImages(List<WorkerSupportMessage> msgs) {
    for (final m in msgs) {
      if (m.isImage && m.mediaUrl != null) {
        _mediaCache.getOrDownloadMedia(m.mediaUrl!).then((f) {
          if (f != null && mounted) {
            setState(() => _cachedImageFiles[m.mediaUrl!] = f);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _readSub?.cancel();
    _delSub?.cancel();
    _allDelSub?.cancel();
    _audioPlayer.dispose();
    _ytPlayerController?.close();
    _textController.dispose();
    _scrollController.dispose();
    _mascotFloatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool showLoadingSpinner = true}) async {
    if (showLoadingSpinner) setState(() => _isLoading = true);
    final history = await _chatService.getChatHistory();
    if (mounted) {
      setState(() {
        _messages = history;
        _isLoading = false;
      });
      _scrollToBottom();
      _chatService.markRead();
      _preloadCachedImages(history);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() {
      _isSending = true;
      _showEmojiRow = false;
    });

    final sent = await _chatService.sendTextMessage(text);
    if (sent != null && mounted) {
      setState(() {
        if (!_messages.any((m) => m.id == sent.id)) {
          _messages.add(sent);
        }
      });
      _scrollToBottom();
      _chatService.saveMessagesToCache(_messages);
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _toggleAudioPlay(WorkerSupportMessage msg) async {
    if (msg.mediaUrl == null) return;

    if (_currentlyPlayingId == msg.id && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      _currentlyPlayingId = msg.id;
      await _audioPlayer.stop();

      // Check local disk cache first!
      final localFile = await _mediaCache.getOrDownloadMedia(msg.mediaUrl!);
      if (localFile != null && await localFile.exists()) {
        debugPrint('[AudioPlayer] Playing from local disk cache: ${localFile.path}');
        await _audioPlayer.play(DeviceFileSource(localFile.path));
      } else {
        await _audioPlayer.play(UrlSource(msg.mediaUrl!));
      }
    }
  }

  void _playYoutubeInline(String ytId) {
    _ytPlayerController?.close();
    final controller = YoutubePlayerController.fromVideoId(
      videoId: ytId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    setState(() {
      _activeInlineYoutubeId = ytId;
      _ytPlayerController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B), // Official WhatsApp Dark Theme Background
      body: Stack(
        children: [
          // ── WhatsApp Dark Doodle Wallpaper ───────────────────────────────
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0B141B),
              child: const CustomPaint(
                painter: DarkNeonDoodlePainter(
                  color: Color(0x0CFFFFFF), // Subtle authentic WhatsApp doodle texture
                ),
              ),
            ),
          ),

          // ── Main Content Area ─────────────────────────────────────────────
          Column(
            children: [
              // Immersive Organic Top App Bar (extends to physical screen top)
              _buildCurvedAppBar(topPadding),

              // Inline YouTube Video Player
              if (_activeInlineYoutubeId != null && _ytPlayerController != null)
                _buildInlineYoutubePlayer(),

              // Messages List OR 3D Mascot Welcome (auto-hides on first message)
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00A884)),
                      )
                    : _messages.isEmpty
                        // 3D Mascot ONLY on empty screen
                        ? _buildWelcomeHeroState()
                        // Clean WhatsApp chat list without outline strokes
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _buildMessageRow(_messages[index]);
                            },
                          ),
              ),

              // Quick Emojis Row (if toggled)
              if (_showEmojiRow) _buildQuickEmojiRow(),

              // WhatsApp-Style Bottom Composer Dock
              _buildFloatingComposer(),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3D Organic Curved Top App Bar (Reaches physical top screen edge) ────────
  Widget _buildCurvedAppBar(double topPadding) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34), // WhatsApp Dark App Bar
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(6, topPadding + 4, 12, 14),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),

          // 3D Cute Robot Avatar (Clean WhatsApp Style, No Outline)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2A3942),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/support_robot_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _pulseAnim,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1F2C34), width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Title & Online Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Admin Support',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B4D8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _chatService.isConnected
                      ? 'Online • Typically replies in minutes'
                      : 'Connecting to support...',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Clean Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00A884), size: 23),
            tooltip: 'Refresh Chat',
            onPressed: () => _loadHistory(showLoadingSpinner: false),
          ),
        ],
      ),
    );
  }

  // ── Inline YouTube Video Player ────────────────────────────────────────────
  Widget _buildInlineYoutubePlayer() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          YoutubePlayer(
            controller: _ytPlayerController!,
            aspectRatio: 16 / 9,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2C34),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'YouTube',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'YouTube Video',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _ytPlayerController?.close();
                    setState(() {
                      _activeInlineYoutubeId = null;
                      _ytPlayerController = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Row with Clean WhatsApp Style ──────────────────────────────────
  Widget _buildMessageRow(WorkerSupportMessage msg) {
    final isWorker = msg.isWorker;
    final timeStr = msg.formattedIstTime;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isWorker ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: 3D Robot Avatar for Admin Support
          if (!isWorker) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 2, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A3942),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/support_robot_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          // Clean WhatsApp Chat Bubble (No Outline Stroke)
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                // WhatsApp Dark: Outgoing (#005C4B) vs Incoming (#1F2C34)
                color: isWorker ? const Color(0xFF005C4B) : const Color(0xFF1F2C34),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isWorker ? 16 : 2),
                  bottomRight: Radius.circular(isWorker ? 2 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header Label inside bubble
                  if (!isWorker)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Admin Support',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF53BDEB), // WhatsApp Cyan Header
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00B4D8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, size: 8, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                  // Message Content
                  if (msg.isYoutube)
                    _buildYouTubeCard(msg)
                  else if (msg.isAudio)
                    _buildAudioCard(msg)
                  else if (msg.isImage)
                    _buildImageCard(msg)
                  else
                    Text(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFFE9EDEF), // WhatsApp Crisp Text
                        height: 1.35,
                      ),
                    ),

                  const SizedBox(height: 3),

                  // Time & Double Checkmark
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF8696A0), // WhatsApp timestamp grey
                        ),
                      ),
                      if (isWorker) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 15,
                          color: Color(0xFF53BDEB), // WhatsApp Blue Read Ticks
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right: 3D Boy Avatar for Worker
          if (isWorker) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 2, left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A3942),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/support_worker_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/worker_avatar_3d.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── YouTube Bubble with Thumbnail & Inline Playback ────────────────────────
  Widget _buildYouTubeCard(WorkerSupportMessage msg) {
    final ytId = msg.youtubeId;
    final thumb = msg.youtubeThumbnailUrl;
    final url = msg.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thumb != null && ytId != null)
          GestureDetector(
            onTap: () => _playYoutubeInline(ytId),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    thumb,
                    width: double.infinity,
                    height: 145,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 145,
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text('YouTube', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: Text(
            url,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF38BDF8),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // ── Voice Audio Player Card with Local Cache Integration ───────────────────
  Widget _buildAudioCard(WorkerSupportMessage msg) {
    final isPlaying = _currentlyPlayingId == msg.id && _playerState == PlayerState.playing;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              size: 38,
              color: const Color(0xFF00E676),
            ),
            onPressed: () => _toggleAudioPlay(msg),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic_rounded, size: 14, color: Color(0xFF00E676)),
                  const SizedBox(width: 4),
                  Text(
                    'Voice Note (${msg.durationSeconds}s)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: 140,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isPlaying
                    ? LinearProgressIndicator(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                            : 0,
                        color: const Color(0xFF00E676),
                        backgroundColor: Colors.white12,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Local Disk Cached Image Card with Interactive Viewer ───────────────────
  Widget _buildImageCard(WorkerSupportMessage msg) {
    final mediaUrl = msg.mediaUrl;
    if (mediaUrl == null || mediaUrl.isEmpty) return const SizedBox.shrink();

    // Check if already in memory/disk cache
    final localFile = _cachedImageFiles[mediaUrl];

    Widget imageWidget;
    if (localFile != null && localFile.existsSync()) {
      imageWidget = Image.file(
        localFile,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
      );
    } else {
      // Load and cache in background
      imageWidget = FutureBuilder<File?>(
        future: _mediaCache.getOrDownloadMedia(mediaUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            _cachedImageFiles[mediaUrl] = snapshot.data!;
            return Image.file(
              snapshot.data!,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
            );
          }
          if (snapshot.hasError) {
            return Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1517),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Image unavailable', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                  ),
                ],
              ),
            );
          }
          return Container(
            width: 220,
            height: 220,
            color: const Color(0xFF131D21),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676), strokeWidth: 2.5),
            ),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black.withValues(alpha: 0.95),
              insetPadding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: localFile != null && localFile.existsSync()
                          ? Image.file(localFile, fit: BoxFit.contain)
                          : Image.network(mediaUrl, fit: BoxFit.contain),
                    ),
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
        child: imageWidget,
      ),
    );
  }

  // ── Welcome Hero State: 3D Mascot ONLY on Empty Screen ─────────────────────
  Widget _buildWelcomeHeroState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // 3D Animated Mascot Card in Dark Space with Neon Glow
          AnimatedBuilder(
            animation: _mascotFloatAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _mascotFloatAnim.value),
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/support_mascot_3d.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick suggestion chips with WhatsApp Dark style (No Outlines)
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickChip('👋 Hi, I need help with my task', 'Hello Admin, I need help regarding my task.'),
              _buildQuickChip('💰 Payment / Wallet Status', 'Hi, can you please check my withdrawal status?'),
              _buildQuickChip('🆔 KYC Verification', 'Hello, my KYC verification is pending.'),
              _buildQuickChip('⭐ Task Rating issue', 'Hi Admin, I have a question about my recent rating.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String message) {
    return ActionChip(
      backgroundColor: const Color(0xFF1F2C34),
      side: BorderSide.none,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE9EDEF),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: () {
        _textController.text = message;
      },
    );
  }

  // ── Quick Emoji Picker Row ─────────────────────────────────────────────────
  Widget _buildQuickEmojiRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _quickEmojis.map((emoji) {
          return InkWell(
            onTap: () {
              _textController.text += emoji;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── WhatsApp Dark Bottom Composer Dock ─────────────────────────────────────
  Widget _buildFloatingComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            // Main WhatsApp Dark Pill Bar (No Outline Stroke)
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2C34), // WhatsApp Dark Input Bar
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Emoji Toggle
                    IconButton(
                      icon: Icon(
                        _showEmojiRow ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded,
                        color: const Color(0xFF8696A0),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _showEmojiRow = !_showEmojiRow);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Color(0xFF8696A0), fontSize: 14.5),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // WhatsApp Teal Green Circular Send Button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00A884), // Official WhatsApp Send Button
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A884).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _isSending ? null : _handleSendMessage,
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

// ── WhatsApp Subtle Dark Doodle Custom Painter ──────────────────────────────
class DarkNeonDoodlePainter extends CustomPainter {
  final Color color;
  const DarkNeonDoodlePainter({this.color = const Color(0x0CFFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.fill;

    const double stepX = 130;
    const double stepY = 140;

    for (double y = 20; y < size.height + 60; y += stepY) {
      for (double x = 15; x < size.width + 60; x += stepX) {
        final patternIndex = ((x / stepX).floor() + (y / stepY).floor()) % 6;
        canvas.save();
        canvas.translate(x, y);

        switch (patternIndex) {
          case 0:
            // Cute Speech Bubble with Smile
            final rrect = RRect.fromRectAndRadius(
              const Rect.fromLTWH(0, 0, 32, 22),
              const Radius.circular(8),
            );
            canvas.drawRRect(rrect, paint);
            final tail = Path()
              ..moveTo(6, 22)
              ..lineTo(2, 27)
              ..lineTo(12, 22);
            canvas.drawPath(tail, paint);
            canvas.drawCircle(const Offset(10, 10), 1.2, fillPaint);
            canvas.drawCircle(const Offset(22, 10), 1.2, fillPaint);
            final smile = Path()
              ..moveTo(12, 14)
              ..quadraticBezierTo(16, 18, 20, 14);
            canvas.drawPath(smile, paint);
            break;

          case 1:
            // Paper Airplane
            canvas.rotate(-math.pi / 10);
            final plane = Path()
              ..moveTo(0, 0)
              ..lineTo(28, 8)
              ..lineTo(6, 20)
              ..close()
              ..moveTo(6, 20)
              ..lineTo(15, 12);
            canvas.drawPath(plane, paint);
            break;

          case 2:
            // Headset with Microphone
            canvas.drawArc(
              const Rect.fromLTWH(4, 0, 22, 22),
              math.pi,
              math.pi,
              false,
              paint,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(const Rect.fromLTWH(0, 9, 7, 12), const Radius.circular(3)),
              paint,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(const Rect.fromLTWH(23, 9, 7, 12), const Radius.circular(3)),
              paint,
            );
            final mic = Path()
              ..moveTo(25, 20)
              ..quadraticBezierTo(18, 26, 12, 24);
            canvas.drawPath(mic, paint);
            break;

          case 3:
            // Sparkle Star
            final star = Path()
              ..moveTo(14, 0)
              ..quadraticBezierTo(14, 10, 24, 10)
              ..quadraticBezierTo(14, 10, 14, 20)
              ..quadraticBezierTo(14, 10, 4, 10)
              ..quadraticBezierTo(14, 10, 14, 0);
            canvas.drawPath(star, paint);
            break;

          case 4:
            // Coffee / Support Mug
            canvas.drawRRect(
              RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 18, 20), const Radius.circular(4)),
              paint,
            );
            canvas.drawArc(
              const Rect.fromLTWH(16, 7, 9, 12),
              -math.pi / 2,
              math.pi,
              false,
              paint,
            );
            break;

          case 5:
            // Double Checkmark
            final check = Path()
              ..moveTo(3, 10)
              ..lineTo(8, 15)
              ..lineTo(18, 4)
              ..moveTo(8, 10)
              ..lineTo(13, 15)
              ..lineTo(23, 4);
            canvas.drawPath(check, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
