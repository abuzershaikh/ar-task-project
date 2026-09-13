import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';

enum NotificationCategory {
  all,
  campaign,
  wallet,
  proof,
  security,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final String categoryLabel;
  final IconData icon;
  final List<Color> iconGradient;
  final Color accentColor;
  final String timeAgo;
  final String? metaChip;
  final String? route;
  final String? actionLabel;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.categoryLabel,
    required this.icon,
    required this.iconGradient,
    required this.accentColor,
    required this.timeAgo,
    this.metaChip,
    this.route,
    this.actionLabel,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationCategory _selectedFilter = NotificationCategory.all;

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'notif_1',
      title: 'Campaign #CAMP-9024 Is Live & Dispatching',
      message:
          'Your Google Play Store 5-Star Rating & Review campaign has reached 72% allocation with 18 verified worker submissions.',
      category: NotificationCategory.campaign,
      categoryLabel: 'CAMPAIGN DISPATCH',
      icon: Icons.rocket_launch_rounded,
      iconGradient: const [Color(0xFF0284C7), Color(0xFF0EA5E9)],
      accentColor: const Color(0xFF38BDF8),
      timeAgo: '15m ago',
      metaChip: 'Play Store 5★',
      route: AppRouter.campaigns,
      actionLabel: 'Track Campaign',
      isRead: false,
    ),
    NotificationItem(
      id: 'notif_2',
      title: 'Escrow Deposit ₹500.00 Confirmed',
      message:
          'Funds successfully credited to your Escrow balance via Instant UPI Gateway. Payment reference: UPI-9842109.',
      category: NotificationCategory.wallet,
      categoryLabel: 'ESCROW WALLET',
      icon: Icons.account_balance_wallet_rounded,
      iconGradient: const [Color(0xFF059669), Color(0xFF10B981)],
      accentColor: const Color(0xFF34D399),
      timeAgo: '1h ago',
      metaChip: 'UPI Auto-Verify',
      route: AppRouter.wallet,
      actionLabel: 'View Balance',
      isRead: false,
    ),
    NotificationItem(
      id: 'notif_3',
      title: 'YouTube Growth Combo Proofs Verified',
      message:
          '25 worker task submissions for your YouTube channel promotion passed automated OCR proof checks and anti-cheat validation.',
      category: NotificationCategory.proof,
      categoryLabel: 'VERIFIED PROOFS',
      icon: Icons.verified_user_rounded,
      iconGradient: const [Color(0xFFDC2626), Color(0xFFEF4444)],
      accentColor: const Color(0xFFFB7185),
      timeAgo: '3h ago',
      metaChip: 'YouTube Combo',
      route: AppRouter.campaigns,
      actionLabel: 'Review Proofs',
      isRead: false,
    ),
    NotificationItem(
      id: 'notif_4',
      title: 'Google Maps 5-Star Listing Impact',
      message:
          '10 authentic local business reviews were successfully posted on Google Maps by geo-located Indian users.',
      category: NotificationCategory.campaign,
      categoryLabel: 'LOCAL SEO',
      icon: Icons.add_location_alt_rounded,
      iconGradient: const [Color(0xFF1D4ED8), Color(0xFF2563EB)],
      accentColor: const Color(0xFF60A5FA),
      timeAgo: '1d ago',
      metaChip: 'Google Maps',
      route: AppRouter.campaigns,
      actionLabel: 'View Ranking',
      isRead: true,
    ),
    NotificationItem(
      id: 'notif_5',
      title: 'Zero-Bot Fraud Shield Audit Complete',
      message:
          'System scanned 10,000+ active worker devices. No emulators or proxy farms detected. All campaign tasks guaranteed 100% human.',
      category: NotificationCategory.security,
      categoryLabel: 'SECURITY SHIELD',
      icon: Icons.security_rounded,
      iconGradient: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      accentColor: const Color(0xFFA78BFA),
      timeAgo: '2d ago',
      metaChip: '100% Real Hardware',
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == NotificationCategory.all) return _notifications;
    return _notifications.where((n) => n.category == _selectedFilter).toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAllNotifications() {
    if (_notifications.isEmpty) return;
    final backup = List<NotificationItem>.from(_notifications);
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications cleared',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {
            setState(() {
              _notifications.addAll(backup);
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _deleteNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final item = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification dismissed',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {
            setState(() {
              _notifications.insert(index, item);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFF080E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080E1E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Text(
              'Notification Center',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$_unreadCount NEW',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              tooltip: 'Mark all as read',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(
                  Icons.done_all_rounded,
                  size: 17,
                  color: Color(0xFF38BDF8),
                ),
              ),
              onPressed: _markAllAsRead,
            ),
            IconButton(
              tooltip: 'Clear all',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  size: 17,
                  color: Color(0xFF94A3B8),
                ),
              ),
              onPressed: _clearAllNotifications,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // ── Real-Time Status Banner ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFF38BDF8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Automated Escrow & Task Feed',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Real-time alerts for orders, worker reviews & balance updates',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filter Chips Row ──
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All', NotificationCategory.all, _notifications.length),
                    _buildFilterChip(
                      'Campaigns',
                      NotificationCategory.campaign,
                      _notifications.where((n) => n.category == NotificationCategory.campaign).length,
                    ),
                    _buildFilterChip(
                      'Wallet & Escrow',
                      NotificationCategory.wallet,
                      _notifications.where((n) => n.category == NotificationCategory.wallet).length,
                    ),
                    _buildFilterChip(
                      'Verified Proofs',
                      NotificationCategory.proof,
                      _notifications.where((n) => n.category == NotificationCategory.proof).length,
                    ),
                    _buildFilterChip(
                      'Security',
                      NotificationCategory.security,
                      _notifications.where((n) => n.category == NotificationCategory.security).length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Notifications List or Empty State ──
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _buildNotificationCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    NotificationCategory category,
    int count,
  ) {
    final isSelected = _selectedFilter == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF080E1E) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF080E1E).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    color: isSelected ? const Color(0xFF080E1E) : const Color(0xFF94A3B8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.isRead
                ? const [Color(0xFF0B132B), Color(0xFF111D35)]
                : const [Color(0xFF0F1A3A), Color(0xFF14244B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? Colors.white.withValues(alpha: 0.06)
                : item.accentColor.withValues(alpha: 0.35),
            width: item.isRead ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: item.isRead
                  ? Colors.black.withValues(alpha: 0.25)
                  : item.accentColor.withValues(alpha: 0.12),
              blurRadius: item.isRead ? 8 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() => item.isRead = !item.isRead);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Category Tag Badge + Timestamp + Unread Dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Glowing Icon Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: item.iconGradient.first.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 10),

                      // Category Pill Label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.accentColor.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          item.categoryLabel,
                          style: GoogleFonts.outfit(
                            color: item.accentColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Timestamp
                      Text(
                        item.timeAgo,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Unread Glowing Dot
                      if (!item.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.accentColor.withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Title
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Row 3: Description Message
                  Text(
                    item.message,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row 4: Meta Chip & Action CTA
                  Row(
                    children: [
                      if (item.metaChip != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            item.metaChip!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),

                      if (item.route != null && item.actionLabel != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, item.route!);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  item.accentColor.withValues(alpha: 0.2),
                                  item.accentColor.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: item.accentColor.withValues(alpha: 0.35),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.actionLabel!,
                                  style: GoogleFonts.outfit(
                                    color: item.accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: item.accentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.done_all_rounded,
                color: Color(0xFF38BDF8),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "You're All Caught Up!",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No notifications in this category. We will alert you the moment workers submit task proofs or campaigns reach new milestones.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
