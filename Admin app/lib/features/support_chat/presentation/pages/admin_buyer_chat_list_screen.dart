import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../buyers/presentation/pages/buyer_detail_screen.dart';
import '../../../buyers/presentation/pages/buyer_directory_screen.dart';
import '../../data/models/buyer_support_conversation_model.dart';
import '../../data/services/buyer_support_chat_service.dart';
import 'admin_buyer_chat_screen.dart';

enum BuyerChatFilter {
  all,
  unread,
  activeToday,
}

class AdminBuyerChatListScreen extends StatefulWidget {
  const AdminBuyerChatListScreen({super.key});

  @override
  State<AdminBuyerChatListScreen> createState() => _AdminBuyerChatListScreenState();
}

class _AdminBuyerChatListScreenState extends State<AdminBuyerChatListScreen> {
  final _chatService = BuyerSupportChatService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<BuyerSupportConversationModel> _conversations = [];
  bool _isLoading = true;
  int _totalUnread = 0;
  BuyerChatFilter _selectedFilter = BuyerChatFilter.all;

  // Selection & Delete Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedConversationIds = {};
  bool _isDeleting = false;

  StreamSubscription? _msgSub;
  StreamSubscription? _convSub;
  StreamSubscription? _readSub;
  StreamSubscription? _convDelSub;

  bool _isToday(DateTime dt) {
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return ist.year == nowIst.year && ist.month == nowIst.month && ist.day == nowIst.day;
  }

  List<BuyerSupportConversationModel> get _filteredConversations {
    switch (_selectedFilter) {
      case BuyerChatFilter.all:
        return _conversations;
      case BuyerChatFilter.unread:
        return _conversations.where((c) => c.unreadAdminCount > 0).toList();
      case BuyerChatFilter.activeToday:
        return _conversations.where((c) => _isToday(c.lastMessageAt)).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _chatService.initSocket();
    _loadConversations();

    // Listen to real-time events
    _msgSub = _chatService.onNewMessage.listen((_) {
      _loadConversations(silent: true);
    });

    _convSub = _chatService.onConversationUpdated.listen((_) {
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
          if (_selectedConversationIds.isEmpty) _isSelectionMode = false;
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final list = await _chatService.getConversations(
      search: _searchController.text.trim(),
    );

    if (mounted) {
      int unread = 0;
      for (final c in list) {
        unread += c.unreadAdminCount;
      }
      setState(() {
        _conversations = list;
        _totalUnread = unread;
        _isLoading = false;
      });
    }
  }

  void _openBuyerProfile(BuyerSupportConversationModel conv) {
    if (conv.buyerId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BuyerDetailScreen(buyerId: conv.buyerId)),
      );
    }
  }

  void _openChat(BuyerSupportConversationModel conv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminBuyerChatScreen(conversation: conv)),
    ).then((_) => _loadConversations(silent: true));
  }

  // ── Selection Mode ─────────────────────────────────────────────────────────
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
        if (_selectedConversationIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedConversationIds.add(convId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedConversationIds.addAll(_conversations.map((c) => c.id));
    });
  }

  Future<void> _handleDeleteSelected() async {
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
          'Permanently delete $count buyer conversation${count > 1 ? 's' : ''} and all associated messages?\n\nThis cannot be undone.',
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
    final ok = await _chatService.deleteConversations(_selectedConversationIds.toList());

    if (mounted) {
      if (ok) {
        setState(() {
          _conversations.removeWhere((c) => _selectedConversationIds.contains(c.id));
          _selectedConversationIds.clear();
          _isSelectionMode = false;
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00875A),
            content: Text('✅ $count conversation${count > 1 ? 's' : ''} deleted'),
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Failed to delete conversations')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime dt) {
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

    if (ist.year == nowIst.year && ist.month == nowIst.month && ist.day == nowIst.day) {
      final hour = ist.hour;
      final minute = ist.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:$minute $period';
    }

    final diffDays = nowIst.difference(ist).inDays;
    if (diffDays == 1) return 'Yesterday';
    if (diffDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[ist.weekday - 1];
    }
    return '${ist.day.toString().padLeft(2, '0')}/${ist.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _filteredConversations;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // Search & Filter header
          _buildSearchAndFilterHeader(),

          // Conversation List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadConversations(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: displayedList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: Color(0xFFE2E8F0)),
                          itemBuilder: (ctx, i) {
                            final conv = displayedList[i];
                            final isSelected = _selectedConversationIds.contains(conv.id);
                            return _buildConversationTile(conv, isSelected);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Floating Action Button to initiate new chat from Buyer Directory (NO BROADCAST)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
        label: const Text('Start Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuyerDirectoryScreen()),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Buyer Support Chat',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (_totalUnread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_totalUnread',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const Text(
            'Direct 1-on-1 buyer messaging',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: () => _loadConversations(),
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
        '${_selectedConversationIds.length} Selected',
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

  Widget _buildSearchAndFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchController,
            onChanged: (val) {
              _loadConversations(silent: true);
            },
            decoration: InputDecoration(
              hintText: 'Search buyer name, email, phone...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadConversations();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Buyers (${_conversations.length})', BuyerChatFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Unread (${_totalUnread > 0 ? _conversations.where((c) => c.unreadAdminCount > 0).length : 0})', BuyerChatFilter.unread),
                const SizedBox(width: 8),
                _buildFilterChip('Active Today', BuyerChatFilter.activeToday),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BuyerChatFilter filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
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
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Buyer Conversations Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'When buyers send support inquiries or you message a buyer from their profile, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.people_outline_rounded, size: 18),
              label: const Text('Browse Buyer Directory'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyerDirectoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuyerSupportConversationModel conv, bool isSelected) {
    final hasUnread = conv.unreadAdminCount > 0;

    return InkWell(
      onLongPress: () => _enterSelectionMode(conv.id),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(conv.id);
        } else {
          _openChat(conv);
        }
      },
      child: Container(
        color: isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
            : hasUnread
                ? const Color(0xFFF5F3FF)
                : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Checkbox in selection mode
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                  size: 22,
                ),
              ),

            // Buyer Avatar
            GestureDetector(
              onTap: () => _openBuyerProfile(conv),
              child: Stack(
                children: [
                  AppAvatar(
                    name: conv.buyerName,
                    imageUrl: conv.buyerAvatarUrl,
                    userId: conv.buyerId,
                    radius: 24,
                    border: Border.all(
                      color: hasUnread ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Buyer info & message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.buyerName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimestamp(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          color: hasUnread ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessageText.isNotEmpty ? conv.lastMessageText : 'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unreadAdminCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
