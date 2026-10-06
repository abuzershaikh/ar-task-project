import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../buyers/presentation/pages/buyer_detail_screen.dart';
import '../../data/models/buyer_support_conversation_model.dart';
import '../../data/models/buyer_support_message_model.dart';
import '../../data/services/buyer_support_chat_service.dart';

class AdminBuyerChatScreen extends StatefulWidget {
  final BuyerSupportConversationModel? conversation;
  final String? buyerId;
  final String? buyerName;
  final String? buyerPhone;
  final String? buyerEmail;
  final String? buyerAvatarUrl;

  const AdminBuyerChatScreen({
    super.key,
    this.conversation,
    this.buyerId,
    this.buyerName,
    this.buyerPhone,
    this.buyerEmail,
    this.buyerAvatarUrl,
  });

  @override
  State<AdminBuyerChatScreen> createState() => _AdminBuyerChatScreenState();
}

class _AdminBuyerChatScreenState extends State<AdminBuyerChatScreen> {
  final _chatService = BuyerSupportChatService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;

  BuyerSupportConversationModel? _activeConversation;
  List<BuyerSupportMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasText = false;
  bool _buyerIsTyping = false;
  Timer? _typingDebounceTimer;

  // Voice recording state
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;

  // Audio playing state
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;

  // Selection & Delete Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};
  bool _isDeleting = false;

  StreamSubscription? _msgSub;
  StreamSubscription? _delSub;
  StreamSubscription? _allDelSub;
  StreamSubscription? _readSub;
  StreamSubscription? _typingSub;

  String get _effectiveBuyerId =>
      _activeConversation?.buyerId ?? widget.buyerId ?? '';

  String get _effectiveBuyerName {
    if (_activeConversation != null && _activeConversation!.buyerName.isNotEmpty) {
      return _activeConversation!.buyerName;
    }
    return widget.buyerName?.isNotEmpty == true ? widget.buyerName! : 'Buyer';
  }

  String get _effectiveBuyerEmail =>
      _activeConversation?.buyerEmail ?? widget.buyerEmail ?? '';

  String get _effectiveBuyerPhone =>
      _activeConversation?.buyerPhone ?? widget.buyerPhone ?? '';

  String? get _effectiveBuyerAvatar =>
      _activeConversation?.buyerAvatarUrl ?? widget.buyerAvatarUrl;

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void initState() {
    super.initState();
    _activeConversation = widget.conversation;
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _textController.addListener(_onTextChanged);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _chatService.initSocket();
    _loadChat();

    // Real-time message listener
    _msgSub = _chatService.onNewMessage.listen((msg) {
      if (msg.buyerId == _effectiveBuyerId ||
          (_activeConversation != null && msg.conversationId == _activeConversation!.id)) {
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
          if (_activeConversation != null) {
            _chatService.markRead(_activeConversation!.id, _effectiveBuyerId);
          }
        }
      }
    });

    // Real-time read listener
    _readSub = _chatService.onMessagesRead.listen((data) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].isAdmin && !_messages[i].isRead) {
              _messages[i] = _messages[i].copyWith(isRead: true);
            }
          }
        });
      }
    });

    // Real-time typing listener
    _typingSub = _chatService.onTyping.listen((data) {
      if (data['buyerId'] == _effectiveBuyerId && data['senderType'] == 'BUYER') {
        final isTyping = data['isTyping'] == true;
        if (mounted) {
          setState(() => _buyerIsTyping = isTyping);
          if (isTyping) {
            _typingDebounceTimer?.cancel();
            _typingDebounceTimer = Timer(const Duration(seconds: 4), () {
              if (mounted) setState(() => _buyerIsTyping = false);
            });
          }
        }
      }
    });

    // Real-time message deletions
    _delSub = _chatService.onMessagesDeleted.listen((deletedIds) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => deletedIds.contains(m.id));
          _selectedMessageIds.removeWhere((id) => deletedIds.contains(id));
          if (_selectedMessageIds.isEmpty && _isSelectionMode) {
            _isSelectionMode = false;
          }
        });
      }
    });

    // Real-time clear conversation
    _allDelSub = _chatService.onAllMessagesDeleted.listen((convId) {
      if (_activeConversation != null && convId == _activeConversation!.id && mounted) {
        setState(() {
          _messages.clear();
          _selectedMessageIds.clear();
          _isSelectionMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _delSub?.cancel();
    _allDelSub?.cancel();
    _readSub?.cancel();
    _typingSub?.cancel();
    _typingDebounceTimer?.cancel();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    setState(() => _isLoading = true);

    if (_activeConversation != null) {
      final list = await _chatService.getMessages(_activeConversation!.id);
      if (mounted) {
        setState(() {
          _messages = list;
          _isLoading = false;
        });
        _scrollToBottom();
        _chatService.markRead(_activeConversation!.id, _effectiveBuyerId);
      }
    } else if (widget.buyerId != null) {
      final res = await _chatService.getBuyerChat(
        widget.buyerId!,
        name: widget.buyerName,
        email: widget.buyerEmail,
        phone: widget.buyerPhone,
        avatarUrl: widget.buyerAvatarUrl,
      );
      if (mounted && res != null) {
        setState(() {
          _activeConversation = res['conversation'] as BuyerSupportConversationModel;
          _messages = (res['messages'] as List<BuyerSupportMessageModel>?) ?? [];
          _isLoading = false;
        });
        _scrollToBottom();
        _chatService.markRead(_activeConversation!.id, _effectiveBuyerId);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Selection Mode ─────────────────────────────────────────────────────────
  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedMessageIds.addAll(_messages.map((m) => m.id));
    });
  }

  Future<void> _handleDeleteSelected() async {
    if (_selectedMessageIds.isEmpty) return;
    final count = _selectedMessageIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Permanently delete $count selected message${count > 1 ? 's' : ''}?\nThis will remove them from the database.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('Delete $count'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final ok = await _chatService.deleteMessages(
      _selectedMessageIds.toList(),
      conversationId: _activeConversation?.id,
    );

    if (mounted) {
      if (ok) {
        setState(() {
          _messages.removeWhere((m) => _selectedMessageIds.contains(m.id));
          _selectedMessageIds.clear();
          _isSelectionMode = false;
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00875A),
            content: Text('✅ $count message${count > 1 ? 's' : ''} deleted'),
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Failed to delete messages')),
        );
      }
    }
  }

  Future<void> _handleClearChat() async {
    if (_activeConversation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Clear Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete ALL messages with this buyer?\n\nThis cannot be undone.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Clear All'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final ok = await _chatService.clearConversationMessages(_activeConversation!.id);

    if (mounted) {
      if (ok) {
        setState(() {
          _messages.clear();
          _selectedMessageIds.clear();
          _isSelectionMode = false;
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00875A),
            content: Text('✅ All messages deleted from database'),
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Failed to clear chat')),
        );
      }
    }
  }

  // ── Send Message Logic ─────────────────────────────────────────────────────
  Future<void> _handleSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final sent = await _chatService.sendMessage(
      buyerId: _effectiveBuyerId,
      conversationId: _activeConversation?.id,
      messageType: 'TEXT',
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

  Future<void> _handlePickAndSendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isSending = true);
    final file = File(picked.path);
    final publicUrl = await _chatService.uploadMedia(file);

    if (publicUrl != null && mounted) {
      final sent = await _chatService.sendMessage(
        buyerId: _effectiveBuyerId,
        conversationId: _activeConversation?.id,
        messageType: 'IMAGE',
        content: 'Photo',
        mediaUrl: publicUrl,
      );

      if (sent != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages.add(sent);
          }
        });
        _scrollToBottom();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Failed to upload image')),
      );
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _showYouTubeDialog() async {
    final ytController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Share YouTube Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a YouTube link to share with buyer:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ytController,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Video'),
            onPressed: () {
              final url = ytController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _sendYouTubeMessage(url);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendYouTubeMessage(String url) async {
    setState(() => _isSending = true);
    final sent = await _chatService.sendMessage(
      buyerId: _effectiveBuyerId,
      conversationId: _activeConversation?.id,
      messageType: 'YOUTUBE',
      content: url,
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

  // ── Voice Recording ────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for voice notes')),
        );
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    final duration = _recordDuration;

    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });

    if (path == null || duration < 1) return;

    setState(() => _isSending = true);
    final file = File(path);
    final publicUrl = await _chatService.uploadMedia(file);

    if (publicUrl != null && mounted) {
      final sent = await _chatService.sendMessage(
        buyerId: _effectiveBuyerId,
        conversationId: _activeConversation?.id,
        messageType: 'AUDIO',
        content: 'Voice Note (${_formatDuration(duration)})',
        mediaUrl: publicUrl,
        durationSeconds: duration,
      );

      if (sent != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages.add(sent);
          }
        });
        _scrollToBottom();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Failed to upload voice note')),
      );
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
  }

  // ── Audio Playback ─────────────────────────────────────────────────────────
  Future<void> _toggleAudioPlay(BuyerSupportMessageModel message) async {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) return;

    if (_currentlyPlayingId == message.id && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_currentlyPlayingId == message.id && _playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingId = message.id;
      });
      await _audioPlayer.play(UrlSource(url));
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _openBuyerProfile() {
    if (_effectiveBuyerId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BuyerDetailScreen(buyerId: _effectiveBuyerId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isSelected = _selectedMessageIds.contains(msg.id);
                          return _buildMessageRow(msg, isSelected);
                        },
                      ),
          ),

          // Typing indicator banner
          if (_buyerIsTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_effectiveBuyerName is typing...',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 1,
      titleSpacing: 0,
      title: InkWell(
        onTap: _openBuyerProfile,
        child: Row(
          children: [
            AppAvatar(
              name: _effectiveBuyerName,
              imageUrl: _effectiveBuyerAvatar,
              userId: _effectiveBuyerId,
              radius: 19,
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _effectiveBuyerName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _buyerIsTyping
                        ? 'typing...'
                        : _effectiveBuyerEmail.isNotEmpty
                            ? _effectiveBuyerEmail
                            : (_effectiveBuyerPhone.isNotEmpty ? _effectiveBuyerPhone : 'Buyer Support'),
                    style: TextStyle(
                      fontSize: 11,
                      color: _buyerIsTyping ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          tooltip: 'View Buyer Profile',
          onPressed: _openBuyerProfile,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (val) {
            if (val == 'clear') _handleClearChat();
            if (val == 'refresh') _loadChat();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Refresh Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Clear History', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} Selected',
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all_rounded, color: Colors.white),
          tooltip: 'Select All',
          onPressed: _selectAll,
        ),
        IconButton(
          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
          tooltip: 'Delete Selected',
          onPressed: _isDeleting ? null : _handleDeleteSelected,
        ),
      ],
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
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with $_effectiveBuyerName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Direct 1-on-1 support chat.\nSend a message, photo, voice note, or video below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(BuyerSupportMessageModel msg, bool isSelected) {
    final isAdmin = msg.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onLongPress: () => _enterSelectionMode(msg.id),
        onTap: _isSelectionMode ? () => _toggleMessageSelection(msg.id) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: _isSelectionMode ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 8),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                    size: 20,
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAdmin ? const Color(0xFF4F46E5) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                      bottomRight: Radius.circular(isAdmin ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Sender tag
                      Text(
                        isAdmin ? 'Admin' : _effectiveBuyerName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? Colors.white70 : const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Content according to type
                      if (msg.isImage) _buildImageContent(msg, isAdmin),
                      if (msg.isYoutube) _buildYoutubeContent(msg, isAdmin),
                      if (msg.isAudio) _buildAudioContent(msg, isAdmin),
                      if (!msg.isImage && !msg.isYoutube && !msg.isAudio)
                        Text(
                          msg.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isAdmin ? Colors.white : const Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Timestamp & read status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.formattedIstTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: isAdmin ? Colors.white60 : const Color(0xFF94A3B8),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            Icon(
                              msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 14,
                              color: msg.isRead ? const Color(0xFF38BDF8) : Colors.white60,
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
        ),
      ),
    );
  }

  Widget _buildImageContent(BuyerSupportMessageModel msg, bool isAdmin) {
    final url = msg.mediaUrl ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 160,
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: Colors.black12,
              child: const Center(child: Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey)),
            ),
          ),
        ),
        if (msg.content.isNotEmpty && msg.content != 'Photo') ...[
          const SizedBox(height: 6),
          Text(msg.content, style: TextStyle(color: isAdmin ? Colors.white : Colors.black87, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildYoutubeContent(BuyerSupportMessageModel msg, bool isAdmin) {
    final thumb = msg.youtubeThumbnailUrl;
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(msg.content);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumb != null)
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(thumb, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            msg.content,
            style: TextStyle(
              fontSize: 12,
              color: isAdmin ? const Color(0xFFBAE6FD) : const Color(0xFF0284C7),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(BuyerSupportMessageModel msg, bool isAdmin) {
    final isPlaying = _currentlyPlayingId == msg.id && _playerState == PlayerState.playing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
            color: isAdmin ? Colors.white : const Color(0xFF6366F1),
            size: 36,
          ),
          onPressed: () => _toggleAudioPlay(msg),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Note',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isAdmin ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              _formatDuration(msg.durationSeconds),
              style: TextStyle(
                fontSize: 11,
                color: isAdmin ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Text(
                'Recording ${_formatDuration(_recordDuration)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8)),
                onPressed: _cancelRecording,
              ),
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
                onPressed: _stopAndSendRecording,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach image
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 22),
              tooltip: 'Attach Image',
              onPressed: _isSending ? null : _handlePickAndSendImage,
            ),

            // Share YouTube
            IconButton(
              icon: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF94A3B8), size: 22),
              tooltip: 'Share YouTube Video',
              onPressed: _isSending ? null : _showYouTubeDialog,
            ),

            // Text Input (Single pill, no double outline, theme overridden)
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Message buyer...',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Mic or Send Button (Gradient circular button matching Buyer & Worker style)
            if (_hasText)
              Container(
                width: 40,
                height: 40,
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
                  onPressed: _isSending ? null : _handleSendText,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                  onPressed: _startRecording,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
