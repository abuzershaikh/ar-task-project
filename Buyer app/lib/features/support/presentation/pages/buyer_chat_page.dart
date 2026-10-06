import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' hide PlayerState;
import '../../../../core/di/injection.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/buyer_chat_service.dart';
import '../../data/support_media_cache.dart';

class BuyerChatPage extends StatefulWidget {
  const BuyerChatPage({super.key});

  @override
  State<BuyerChatPage> createState() => _BuyerChatPageState();
}

class _BuyerChatPageState extends State<BuyerChatPage> {
  final _chatService = BuyerChatService.instance;
  final _mediaCache = SupportMediaCache.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AudioPlayer _audioPlayer;

  List<BuyerChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _adminIsTyping = false;
  Timer? _typingTimer;

  // Audio playback state
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Inline YouTube player state
  String? _activeInlineYoutubeId;
  YoutubePlayerController? _ytPlayerController;

  // Media file cache map for instant UI display
  final Map<String, File> _cachedImageFiles = {};

  StreamSubscription? _msgSub;
  StreamSubscription? _readSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _delSub;
  StreamSubscription? _allDelSub;

  String get _buyerId {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser?.uid != null && authUser!.uid.isNotEmpty) return authUser.uid;
    final storageId = getIt<LocalStorageService>().getUserId();
    if (storageId != null && storageId.isNotEmpty) return storageId;
    return 'buyer_${authUser?.email?.split('@')[0] ?? 'guest'}';
  }

  String get _buyerName {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) return authUser.displayName!;
    final biz = getIt<LocalStorageService>().getBusinessName();
    if (biz != null && biz.isNotEmpty) return biz;
    return authUser?.email?.split('@')[0] ?? 'Buyer';
  }

  String get _buyerEmail => FirebaseAuth.instance.currentUser?.email ?? getIt<LocalStorageService>().getUserEmail() ?? '';
  String? get _buyerAvatar => FirebaseAuth.instance.currentUser?.photoURL ?? getIt<LocalStorageService>().getUserPhoto();

  @override
  void initState() {
    super.initState();
    NotificationService.isChatPageOpen = true;
    NotificationService.instance.syncUserToken(_buyerId);

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

    _chatService.initSocket(_buyerId);
    _loadChat();

    _msgSub = _chatService.onNewMessage.listen((msg) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx >= 0) {
            _messages[idx] = msg;
          } else {
            _messages.add(msg);
          }
        });
        _scrollToBottom();
        if (_conversationId != null) {
          _chatService.markRead(_conversationId!, _buyerId);
        }
        if (msg.isImage && msg.mediaUrl != null) {
          _mediaCache.getOrDownloadMedia(msg.mediaUrl!).then((f) {
            if (f != null && mounted) setState(() => _cachedImageFiles[msg.mediaUrl!] = f);
          });
        }
      }
    });

    _readSub = _chatService.onMessagesRead.listen((_) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].isBuyer && !_messages[i].isRead) {
              _messages[i] = _messages[i].copyWith(isRead: true);
            }
          }
        });
      }
    });

    _typingSub = _chatService.onTyping.listen((data) {
      if (data['senderType'] == 'ADMIN') {
        final isTyping = data['isTyping'] == true;
        if (mounted) {
          setState(() => _adminIsTyping = isTyping);
          if (isTyping) {
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 4), () {
              if (mounted) setState(() => _adminIsTyping = false);
            });
          }
        }
      }
    });

    _delSub = _chatService.onMessagesDeleted.listen((deletedIds) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => deletedIds.contains(m.id));
        });
      }
    });

    _allDelSub = _chatService.onAllMessagesDeleted.listen((_) {
      if (mounted) {
        setState(() {
          _messages.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    NotificationService.isChatPageOpen = false;
    _msgSub?.cancel();
    _readSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _delSub?.cancel();
    _allDelSub?.cancel();
    _audioPlayer.dispose();
    _ytPlayerController?.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    setState(() => _isLoading = true);
    final res = await _chatService.getChat(
      _buyerId,
      name: _buyerName,
      email: _buyerEmail,
      avatarUrl: _buyerAvatar,
    );

    if (mounted) {
      setState(() {
        _conversationId = res?['conversationId'];
        _messages = (res?['messages'] as List<BuyerChatMessage>?) ?? [];
        _isLoading = false;
      });
      _scrollToBottom();
      if (_conversationId != null) {
        _chatService.markRead(_conversationId!, _buyerId);
      }
      _preloadCachedImages(_messages);
    }
  }

  void _preloadCachedImages(List<BuyerChatMessage> msgs) {
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final sent = await _chatService.sendMessage(
      buyerId: _buyerId,
      conversationId: _conversationId,
      content: text,
    );

    if (sent != null && mounted) {
      setState(() {
        if (!_messages.any((m) => m.id == sent.id)) {
          _messages.add(sent);
        }
      });
      _scrollToBottom();
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _toggleAudioPlay(BuyerChatMessage msg) async {
    final url = msg.mediaUrl;
    if (url == null || url.isEmpty) return;

    if (_currentlyPlayingId == msg.id && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_currentlyPlayingId == msg.id && _playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      _currentlyPlayingId = msg.id;
      await _audioPlayer.stop();

      // Check local disk cache first!
      final localFile = await _mediaCache.getOrDownloadMedia(url);
      if (localFile != null && await localFile.exists()) {
        debugPrint('[BuyerAudioPlayer] Playing from local disk cache: ${localFile.path}');
        await _audioPlayer.play(DeviceFileSource(localFile.path));
      } else {
        await _audioPlayer.play(UrlSource(url));
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
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Lottie.asset(
                'assets/animations/customercare.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Support Desk',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
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
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _adminIsTyping ? 'typing...' : 'Online • Avg Response < 5m',
                        style: GoogleFonts.outfit(
                          color: _adminIsTyping ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Inline YouTube Video Player
          if (_activeInlineYoutubeId != null && _ytPlayerController != null)
            _buildInlineYoutubePlayer(),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
                      ),
          ),

          // Typing banner
          if (_adminIsTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Admin Desk is typing...',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF38BDF8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar
          _buildInputBar(),
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
              color: Color(0xFF0F172A),
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
                      'Admin Shared Video',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 18),
            Text(
              'How can we help your business today?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask anything about campaign speed, volume discounts, keywords, or custom tasks. Our desk responds instantly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuyerChatMessage msg) {
    final isBuyer = msg.isBuyer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isBuyer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: Admin Support Avatar
          if (!isBuyer) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 2, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.support_agent_rounded, size: 20, color: Color(0xFF38BDF8)),
              ),
            ),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isBuyer
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isBuyer ? null : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBuyer ? 16 : 4),
                  bottomRight: Radius.circular(isBuyer ? 4 : 16),
                ),
                border: isBuyer
                    ? null
                    : Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isBuyer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Header Label
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBuyer ? 'You' : 'Admin Support',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isBuyer ? const Color(0xFFE0E7FF) : const Color(0xFF38BDF8),
                        ),
                      ),
                      if (!isBuyer) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00B4D8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 7, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Message Content based on type
                  if (msg.isYoutube)
                    _buildYouTubeCard(msg)
                  else if (msg.isAudio)
                    _buildAudioCard(msg)
                  else if (msg.isImage)
                    _buildImageCard(msg)
                  else
                    Text(
                      msg.content,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.formattedTime,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isBuyer ? const Color(0xFFC7D2FE) : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isBuyer) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 14,
                          color: msg.isRead ? const Color(0xFF38BDF8) : const Color(0xFFC7D2FE),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Voice Audio Player Card with Local Cache Integration ───────────────────
  Widget _buildAudioCard(BuyerChatMessage msg) {
    final isPlaying = _currentlyPlayingId == msg.id && _playerState == PlayerState.playing;
    final isBuyer = msg.isBuyer;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              size: 38,
              color: isBuyer ? Colors.white : const Color(0xFF10B981),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _toggleAudioPlay(msg),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 14,
                    color: isBuyer ? Colors.white70 : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Voice Note (${msg.durationSeconds > 0 ? '${msg.durationSeconds}s' : 'Audio'})',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: 140,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isPlaying
                    ? LinearProgressIndicator(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                            : 0,
                        color: isBuyer ? Colors.white : const Color(0xFF10B981),
                        backgroundColor: Colors.white24,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── YouTube Bubble with Thumbnail & Inline Playback ────────────────────────
  Widget _buildYouTubeCard(BuyerChatMessage msg) {
    final ytId = msg.effectiveYoutubeId;
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
                          Text(
                            'YouTube',
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

  // ── Local Disk Cached Image Card ───────────────────────────────────────────
  Widget _buildImageCard(BuyerChatMessage msg) {
    final mediaUrl = msg.mediaUrl;
    if (mediaUrl == null || mediaUrl.isEmpty) return const SizedBox.shrink();

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
          return Image.network(
            mediaUrl,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 220,
              height: 120,
              color: const Color(0xFF1E293B),
              child: const Icon(Icons.broken_image_rounded, color: Colors.white38),
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  cursorColor: const Color(0xFF38BDF8),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask Support Desk...',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isSending ? null : _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
