import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/support_conversation_model.dart';
import '../../data/services/support_chat_service.dart';
import 'admin_chat_screen.dart';
import 'admin_bulk_broadcast_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final _chatService = SupportChatService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<SupportConversationModel> _conversations = [];
  bool _isLoading = true;
  int _totalUnread = 0;

  // ── Selection & Delete Mode ───────────────────────────────────────────────
  bool _isSelectionMode = false;
  final Set<String> _selectedConversationIds = {};
  bool _isDeleting = false;

  StreamSubscription? _msgSub;
  StreamSubscription? _convSub;
  StreamSubscription? _readSub;
  StreamSubscription? _convDelSub;
  StreamSubscription? _allConvDelSub;

  @override
  void initState() {
    super.initState();
    _chatService.initSocket();
    _loadConversations();

    // Listen to real-time events
    _msgSub = _chatService.onNewMessage.listen((msg) {
      _loadConversations(silent: true);
    });

    _convSub = _chatService.onConversationUpdated.listen((updatedConv) {
      _loadConversations(silent: true);
    });

    _readSub = _chatService.onMessagesRead.listen((_) {
      _loadConversations(silent: true);
    });

    _convDelSub = _chatService.onConversationsDeleted.listen((deletedIds) {
      if (mounted) {
        setState(() {
          _conversations.removeWhere((c) => deletedIds.contains(c.id));
          _selectedConversationIds.removeWhere((id) => deletedIds.contains(id));
          if (_selectedConversationIds.isEmpty && _isSelectionMode) {
            _isSelectionMode = false;
          }
        });
      }
    });

    _allConvDelSub = _chatService.onAllConversationsDeleted.listen((_) {
      if (mounted) {
        setState(() {
          _conversations.clear();
          _selectedConversationIds.clear();
          _isSelectionMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _convSub?.cancel();
    _readSub?.cancel();
    _convDelSub?.cancel();
    _allConvDelSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String convId) {
    setState(() {
      _isSelectionMode = true;
      _selectedConversationIds.add(convId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedConversationIds.clear();
    });
  }

  void _toggleSelection(String convId) {
    setState(() {
      if (_selectedConversationIds.contains(convId)) {
        _selectedConversationIds.remove(convId);
        if (_selectedConversationIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversationIds.add(convId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedConversationIds.length == _conversations.length) {
        _selectedConversationIds.clear();
      } else {
        _selectedConversationIds.addAll(_conversations.map((c) => c.id));
      }
    });
  }

  // ── Delete Selected Conversations ──────────────────────────────────────────
  Future<void> _handleDeleteSelectedConversations() async {
    if (_selectedConversationIds.isEmpty) return;

    final count = _selectedConversationIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Conversations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected conversation${count > 1 ? 's' : ''} and all their messages?\n\nThis will remove them from the database.',
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
    final ids = _selectedConversationIds.toList();
    final res = await _chatService.deleteConversations(ids);

    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          _conversations.removeWhere((c) => _selectedConversationIds.contains(c.id));
          _selectedConversationIds.clear();
          _isSelectionMode = false;
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00875A),
            content: Text('✅ $count conversation${count > 1 ? 's' : ''} deleted from database'),
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to delete conversations'),
          ),
        );
      }
    }
  }

  // ── Delete ALL Workers' Messages & Chats ────────────────────────────────────
  Future<void> _handleDeleteAllWorkersChats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete All Worker Chats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '⚠️ Are you sure you want to permanently delete ALL messages & chats for ALL workers?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 10),
            Text(
              '• Every conversation will be removed from the database.\n'
              '• All messages across all workers will be permanently deleted from SQL.\n'
              '• Worker app screens and local caches will be cleared in real-time.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF64748B)),
            ),
          ],
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
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Everything'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final res = await _chatService.deleteAllWorkersChats();

    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          _conversations.clear();
          _selectedConversationIds.clear();
          _isSelectionMode = false;
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00875A),
            content: Text('✅ All messages and chats deleted for all workers from database'),
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to delete all chats'),
          ),
        );
      }
    }
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final res = await _chatService.getConversations(
      search: _searchController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _conversations = (res['conversations'] as List<SupportConversationModel>?) ?? [];
        _totalUnread = (res['totalUnread'] as int?) ?? 0;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime dt) {
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final today = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final messageDate = DateTime(ist.year, ist.month, ist.day);

    if (messageDate == today) {
      final hour = ist.hour;
      final minute = ist.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM').format(ist);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadConversations(),
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 74,
                      color: Color(0xFFE2E8F0),
                    ),
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00875A), // WhatsApp Emerald Green
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign_rounded, size: 22),
              label: const Text(
                'Bulk Broadcast',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBulkBroadcastScreen()),
                );
                if (result == true) {
                  _loadConversations();
                }
              },
            ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final allSelected = _conversations.isNotEmpty && _selectedConversationIds.length == _conversations.length;
    return AppBar(
      backgroundColor: const Color(0xFF00875A), // WhatsApp Green
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedConversationIds.length} Selected',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: Icon(allSelected ? Icons.deselect_rounded : Icons.select_all_rounded),
          tooltip: allSelected ? 'Deselect All' : 'Select All',
          onPressed: _selectAll,
        ),
        if (_isDeleting)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Delete Selected',
            onPressed: _selectedConversationIds.isNotEmpty ? _handleDeleteSelectedConversations : null,
          ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text(
            'Support Chats',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (_totalUnread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_totalUnread',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _chatService.isConnected ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _chatService.isConnected ? Colors.green : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _chatService.isConnected ? 'LIVE' : 'SYNCING',
                  style: TextStyle(
                    color: _chatService.isConnected ? Colors.green : Colors.amber[800],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _loadConversations(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'select') {
              setState(() => _isSelectionMode = true);
            } else if (val == 'delete_all') {
              _handleDeleteAllWorkersChats();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'select',
              child: Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 20, color: Color(0xFF1E293B)),
                  SizedBox(width: 10),
                  Text('Select Chats', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Delete All Worker Chats',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadConversations(silent: true),
              decoration: InputDecoration(
                hintText: 'Search workers by name, email, phone...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadConversations();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Conversations Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'When workers message support or you send a broadcast,\nthey will appear here in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: const Text('Send First Broadcast'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBulkBroadcastScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(SupportConversationModel conv) {
    final hasUnread = conv.unreadAdminCount > 0;
    final isNew = conv.totalTasksCompleted == 0;

    // Snippet icon
    Widget snippetIcon = const SizedBox.shrink();
    if (conv.lastMessageType == 'YOUTUBE') {
      snippetIcon = const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.play_circle_fill_rounded, size: 14, color: Colors.red),
      );
    } else if (conv.lastMessageType == 'AUDIO') {
      snippetIcon = const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.mic_rounded, size: 14, color: Color(0xFF0284C7)),
      );
    } else if (conv.lastMessageType == 'IMAGE') {
      snippetIcon = const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.photo_camera_rounded, size: 14, color: Color(0xFF16A34A)),
      );
    }

    final isSelected = _selectedConversationIds.contains(conv.id);

    return InkWell(
      onTap: () async {
        if (_isSelectionMode) {
          _toggleSelection(conv.id);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminChatScreen(conversation: conv),
            ),
          );
          _loadConversations(silent: true);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(conv.id);
        }
      },
      child: Container(
        color: isSelected
            ? const Color(0xFFE8F5E9)
            : hasUnread
                ? const Color(0xFFF0FDF4)
                : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (_isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                activeColor: const Color(0xFF00875A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => _toggleSelection(conv.id),
              ),
              const SizedBox(width: 4),
            ],
            // Avatar with Google profile photo support
            AppAvatar(
              name: conv.workerName,
              imageUrl: conv.workerAvatarUrl,
              radius: 25,
              showOnlineBadge: true,
              isOnline: true,
            ),
            const SizedBox(width: 14),

            // Middle Column: Name, phone/email, last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conv.workerName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      snippetIcon,
                      Expanded(
                        child: Text(
                          conv.lastMessageText.isNotEmpty ? conv.lastMessageText : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Column: Timestamp & Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(conv.lastMessageAt),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                    color: hasUnread ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conv.unreadAdminCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
