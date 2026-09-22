import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/support_conversation_model.dart';
import '../../data/models/support_message_model.dart';
import '../../data/services/support_chat_service.dart';

class AdminChatScreen extends StatefulWidget {
  final SupportConversationModel conversation;
  const AdminChatScreen({super.key, required this.conversation});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _chatService = SupportChatService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;

  List<SupportMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Voice recording state
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;

  // Audio playing state
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // ── Message Selection/Delete Mode ──────────────────────────────────────
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};
  bool _isDeleting = false;

  StreamSubscription? _msgSub;
  StreamSubscription? _delSub;
  StreamSubscription? _allDelSub;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
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

    _loadMessages();

    // Mark as read immediately
    _chatService.markRead(widget.conversation.id, widget.conversation.workerId);

    // Listen to real-time incoming messages
    _msgSub = _chatService.onNewMessage.listen((msg) {
      if (msg.conversationId == widget.conversation.id || msg.workerId == widget.conversation.workerId) {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
        _chatService.markRead(widget.conversation.id, widget.conversation.workerId);
      }
    });

    // Listen to real-time message deletions
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

    // Listen to real-time conversation clear
    _allDelSub = _chatService.onAllMessagesDeleted.listen((convId) {
      if (convId == widget.conversation.id && mounted) {
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
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final list = await _chatService.getMessages(widget.conversation.id);
    if (mounted) {
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom();
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

  // ── Selection Mode Helpers ─────────────────────────────────────────────────
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

  // ── Delete Selected Messages ───────────────────────────────────────────────
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
          'Are you sure you want to permanently delete $count selected message${count > 1 ? 's' : ''}?\n\nThis will remove them from the database and cannot be undone.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
    final result = await _chatService.deleteMessages(_selectedMessageIds.toList());

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _messages.removeWhere((m) => _selectedMessageIds.contains(m.id));
          _selectedMessageIds.clear();
          _isSelectionMode = false;
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00875A),
            content: Text('✅ $count message${count > 1 ? 's' : ''} deleted from database'),
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to delete messages'),
          ),
        );
      }
    }
  }

  // ── Delete ALL Messages in Conversation ─────────────────────────────────────
  Future<void> _handleDeleteAllMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete All Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ALL ${_messages.length} messages from this conversation?\n\n⚠️ This will permanently remove everything from the database and cannot be undone.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Delete All'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final result = await _chatService.deleteAllConversationMessages(widget.conversation.id);

    if (mounted) {
      if (result['success'] == true) {
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
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to delete messages'),
          ),
        );
      }
    }
  }

  // ── Send Message ───────────────────────────────────────────────────────────
  Future<void> _handleSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final sent = await _chatService.sendMessage(
      conversationId: widget.conversation.id,
      workerId: widget.conversation.workerId,
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

  // ── Send YouTube Link ──────────────────────────────────────────────────────
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
              'Paste a YouTube link. It will render with rich player cards in the chat:',
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
      conversationId: widget.conversation.id,
      workerId: widget.conversation.workerId,
      messageType: 'YOUTUBE',
      content: url,
    );
    if (sent != null && mounted) {
      setState(() {
        if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
      });
      _scrollToBottom();
    }
    if (mounted) setState(() => _isSending = false);
  }

  // ── Send Photo ─────────────────────────────────────────────────────────────
  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isSending = true);
    final file = File(image.path);
    final mediaUrl = await _chatService.uploadMedia(file);

    if (mediaUrl != null && mounted) {
      final sent = await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        workerId: widget.conversation.workerId,
        messageType: 'IMAGE',
        content: 'Photo',
        mediaUrl: mediaUrl,
      );
      if (sent != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
        });
        _scrollToBottom();
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  // ── Audio Recording ────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _recordDuration++);
        });
      }
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && File(path).existsSync()) {
        setState(() => _isSending = true);
        final file = File(path);
        final mediaUrl = await _chatService.uploadMedia(file);

        if (mediaUrl != null && mounted) {
          final sent = await _chatService.sendMessage(
            conversationId: widget.conversation.id,
            workerId: widget.conversation.workerId,
            messageType: 'AUDIO',
            content: 'Voice Note',
            mediaUrl: mediaUrl,
            durationSeconds: _recordDuration,
          );
          if (sent != null && mounted) {
            setState(() {
              if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
  }

  // ── Play / Pause Audio ─────────────────────────────────────────────────────
  Future<void> _toggleAudioPlay(SupportMessageModel msg) async {
    if (msg.mediaUrl == null) return;

    if (_currentlyPlayingId == msg.id && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      _currentlyPlayingId = msg.id;
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(msg.mediaUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEAE2), // WhatsApp Classic Chat Wallpaper Color
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(conv),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildChatStartBanner()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // Composer (hidden during selection mode)
          if (!_isSelectionMode) _buildComposer(),
        ],
      ),
    );
  }

  // ── Normal App Bar ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildNormalAppBar(SupportConversationModel conv) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white24,
            child: Text(
              conv.workerName.isNotEmpty ? conv.workerName[0].toUpperCase() : 'W',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.workerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  conv.workerPhone.isNotEmpty ? conv.workerPhone : (conv.workerEmail.isNotEmpty ? conv.workerEmail : 'Worker'),
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.task_alt_rounded, size: 14, color: Color(0xFF4ADE80)),
              const SizedBox(width: 4),
              Text(
                '${conv.totalTasksCompleted} tasks',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        // Delete All button in popup menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) {
            if (value == 'delete_all') {
              _handleDeleteAllMessages();
            } else if (value == 'select') {
              setState(() => _isSelectionMode = true);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text('Select Messages', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete All Messages', style: TextStyle(fontSize: 13, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Selection Mode App Bar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} selected',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Select All
        IconButton(
          icon: Icon(
            _selectedMessageIds.length == _messages.length
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            size: 22,
          ),
          tooltip: _selectedMessageIds.length == _messages.length ? 'Deselect All' : 'Select All',
          onPressed: () {
            if (_selectedMessageIds.length == _messages.length) {
              _exitSelectionMode();
            } else {
              _selectAll();
            }
          },
        ),
        // Delete Selected
        _isDeleting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                tooltip: 'Delete Selected',
                onPressed: _selectedMessageIds.isEmpty ? null : _handleDeleteSelected,
              ),
      ],
    );
  }

  Widget _buildChatStartBanner() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent_rounded, size: 36, color: Color(0xFF00875A)),
            const SizedBox(height: 8),
            Text(
              'Direct Support with ${widget.conversation.workerName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Send text messages, audio recordings, images, or YouTube video training links.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message Bubble ─────────────────────────────────────────────────────────
  Widget _buildMessageBubble(SupportMessageModel msg) {
    final isAdmin = msg.isAdmin;
    final timeStr = msg.formattedIstTime;
    final isSelected = _selectedMessageIds.contains(msg.id);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(msg.id);
        }
      },
      onTap: _isSelectionMode ? () => _toggleMessageSelection(msg.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected ? const Color(0xFF00875A).withValues(alpha: 0.15) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            // Selection Checkbox (visible in selection mode)
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFF00875A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) => _toggleMessageSelection(msg.id),
                ),
              ),

            // Message Bubble
            Expanded(
              child: Align(
                alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * (_isSelectionMode ? 0.68 : 0.78),
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin ? const Color(0xFFDCF8C6) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isAdmin ? 14 : 2),
                      bottomRight: Radius.circular(isAdmin ? 2 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin / Worker Tag
                      if (!isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            widget.conversation.workerName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),

                      // Content by Type
                      if (msg.isYoutube)
                        _buildYouTubeBubble(msg)
                      else if (msg.isAudio)
                        _buildAudioBubble(msg)
                      else if (msg.isImage)
                        _buildImageBubble(msg)
                      else
                        Text(
                          msg.content,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.3),
                        ),

                      const SizedBox(height: 4),

                      // Timestamp and Read Checkmarks
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Spacer(),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: msg.isRead ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                            ),
                          ],
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

  // ── YouTube Bubble (WhatsApp Card Style) ───────────────────────────────────
  Widget _buildYouTubeBubble(SupportMessageModel msg) {
    final thumb = msg.youtubeThumbnailUrl;
    final ytUrl = msg.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thumb != null)
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(ytUrl);
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    thumb,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.black12,
                      child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.red, size: 48)),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.smart_display_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
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
            final uri = Uri.parse(ytUrl);
            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: Text(
            ytUrl,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0369A1),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // ── Audio Bubble (Voice Note Style) ────────────────────────────────────────
  Widget _buildAudioBubble(SupportMessageModel msg) {
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
              color: const Color(0xFF00875A),
            ),
            onPressed: () => _toggleAudioPlay(msg),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Voice Note (${msg.durationSeconds}s)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 130,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isPlaying
                    ? LinearProgressIndicator(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                            : 0,
                        color: const Color(0xFF00875A),
                        backgroundColor: const Color(0xFFCBD5E1),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Image Bubble ───────────────────────────────────────────────────────────
  Widget _buildImageBubble(SupportMessageModel msg) {
    final mediaUrl = msg.mediaUrl;
    if (mediaUrl == null || mediaUrl.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black.withValues(alpha: 0.9),
              insetPadding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: Image.network(mediaUrl, fit: BoxFit.contain),
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
        child: Image.network(
          mediaUrl,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 220,
              height: 220,
              color: const Color(0xFFF1F5F9),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF00875A),
                  strokeWidth: 2.5,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.broken_image_rounded, color: Color(0xFFEF4444), size: 36),
                SizedBox(height: 6),
                Text(
                  'Image unavailable',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Composer Bar ───────────────────────────────────────────────────────────
  Widget _buildComposer() {
    if (_isRecording) {
      final mins = (_recordDuration ~/ 60).toString().padLeft(2, '0');
      final secs = (_recordDuration % 60).toString().padLeft(2, '0');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'Recording Voice Note ($mins:$secs)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cancelRecording,
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Color(0xFF00875A),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
                onPressed: _stopAndSendRecording,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach YouTube Link Button
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 26),
              tooltip: 'Send YouTube Video',
              onPressed: _showYouTubeDialog,
            ),

            // Attach Image Button
            IconButton(
              icon: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0284C7), size: 24),
              tooltip: 'Send Photo',
              onPressed: _pickAndSendImage,
            ),

            // Text Input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send / Mic Button
            _textController.text.trim().isNotEmpty || _isSending
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00875A),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _handleSendText,
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00875A),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                      tooltip: 'Record Voice Note',
                      onPressed: _startRecording,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
