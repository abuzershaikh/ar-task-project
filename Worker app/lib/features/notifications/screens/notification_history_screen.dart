import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../data/models/notification_model.dart';
import '../../wallet/screens/wallet_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<WorkerNotificationModel> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // 'ALL', 'TASKS', 'EARNINGS', 'SYSTEM'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final rawList = await ApiService.getNotifications();
      final parsed = rawList.map((j) => WorkerNotificationModel.fromJson(j)).toList();
      if (mounted) {
        setState(() {
          _notifications = parsed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    await ApiService.markAllNotificationsAsRead();
    setState(() {
      _notifications = _notifications
          .map((n) => WorkerNotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
                entityType: n.entityType,
                entityId: n.entityId,
                data: n.data,
              ))
          .toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All notifications marked as read',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onNotificationTap(WorkerNotificationModel item) async {
    if (!item.isRead) {
      ApiService.markNotificationAsRead(item.id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == item.id);
        if (idx != -1) {
          _notifications[idx] = WorkerNotificationModel(
            id: item.id,
            title: item.title,
            message: item.message,
            type: item.type,
            isRead: true,
            createdAt: item.createdAt,
            entityType: item.entityType,
            entityId: item.entityId,
            data: item.data,
          );
        }
      });
    }

    final type = item.type.toUpperCase();
    if (type.contains('TASK') || type == 'NEW_TASK') {
      Navigator.of(context).pop(); // Go back to feed to view and accept tasks
    } else if (type.contains('EARNING') || type.contains('WITHDRAWAL') || type.contains('PAYOUT')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WalletScreen()),
      );
    }
  }

  List<WorkerNotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'TASKS') {
      return _notifications
          .where((n) => n.type.toUpperCase().contains('TASK') || n.type == 'NEW_TASK')
          .toList();
    } else if (_selectedFilter == 'EARNINGS') {
      return _notifications
          .where((n) =>
              n.type.toUpperCase().contains('EARNING') ||
              n.type.toUpperCase().contains('WITHDRAWAL'))
          .toList();
    } else if (_selectedFilter == 'SYSTEM') {
      return _notifications
          .where((n) =>
              n.type.toUpperCase().contains('KYC') ||
              n.type.toUpperCase().contains('SYSTEM') ||
              n.type.toUpperCase().contains('REVIEW'))
          .toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF2563EB)),
              label: Text(
                'Mark Read',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('ALL', 'All (${_notifications.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('TASKS', 'Tasks 🎁'),
                const SizedBox(width: 8),
                _buildFilterChip('EARNINGS', 'Earnings 💰'),
                const SizedBox(width: 8),
                _buildFilterChip('SYSTEM', 'System 🛡️'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: const Color(0xFF2563EB),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: _filteredNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _filteredNotifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(WorkerNotificationModel item) {
    final cfg = _getNotificationConfig(item.type);

    return InkWell(
      onTap: () => _onNotificationTap(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC),
            width: item.isRead ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Icon Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cfg.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(cfg.icon, color: cfg.iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0F172A),
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.timeAgo,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF475569),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread Dot
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New task alerts and wallet payouts will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotifStyle _getNotificationConfig(String type) {
    final t = type.toUpperCase();
    if (t.contains('NEW_TASK') || t.contains('TASK_ASSIGNED')) {
      return _NotifStyle(
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
      );
    } else if (t.contains('TASK_APPROVED') || t.contains('EARNING')) {
      return _NotifStyle(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      );
    } else if (t.contains('TASK_REJECTED') || t.contains('REVIEW')) {
      return _NotifStyle(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEF2F2),
      );
    } else if (t.contains('WITHDRAWAL') || t.contains('PAYOUT')) {
      return _NotifStyle(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF0284C7),
        bgColor: const Color(0xFFF0F9FF),
      );
    } else if (t.contains('KYC')) {
      return _NotifStyle(
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF9333EA),
        bgColor: const Color(0xFFFAF5FF),
      );
    }
    return _NotifStyle(
      icon: Icons.notifications_rounded,
      iconColor: const Color(0xFF64748B),
      bgColor: const Color(0xFFF8FAFC),
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _NotifStyle({required this.icon, required this.iconColor, required this.bgColor});
}
