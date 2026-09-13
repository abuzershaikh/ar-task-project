import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';

enum NotificationCategory {
  all,
  campaign,
  wallet,
  security,
}

class BuyerNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? entityType;
  final String? entityId;
  final dynamic data;
  final DateTime createdAt;
  bool isRead;

  BuyerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.entityType,
    this.entityId,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory BuyerNotification.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['createdAt'] ?? json['created_at'] ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return BuyerNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      entityType: json['entityType']?.toString() ?? json['entity_type']?.toString(),
      entityId: json['entityId']?.toString() ?? json['entity_id']?.toString(),
      data: json['data'],
      createdAt: parsedDate,
      isRead: json['isRead'] == true || json['is_read'] == 1 || json['is_read'] == true,
    );
  }

  NotificationCategory get category {
    final t = type.toUpperCase();
    final et = (entityType ?? '').toUpperCase();
    if (t.contains('ORDER') || t.contains('CAMPAIGN') || t.contains('TASK') || et == 'ORDER') {
      return NotificationCategory.campaign;
    }
    if (t.contains('WALLET') || t.contains('PAYMENT') || t.contains('CREDIT') || t.contains('DEBIT') || et == 'WALLET') {
      return NotificationCategory.wallet;
    }
    if (t.contains('SECURITY') || t.contains('FRAUD') || t.contains('SHIELD') || et == 'SECURITY') {
      return NotificationCategory.security;
    }
    return NotificationCategory.all;
  }

  String get categoryLabel {
    switch (category) {
      case NotificationCategory.campaign:
        return 'CAMPAIGN DISPATCH';
      case NotificationCategory.wallet:
        return 'ESCROW WALLET';
      case NotificationCategory.security:
        return 'SECURITY SHIELD';
      default:
        return 'SYSTEM ALERT';
    }
  }

  IconData get icon {
    switch (category) {
      case NotificationCategory.campaign:
        return Icons.rocket_launch_rounded;
      case NotificationCategory.wallet:
        return Icons.account_balance_wallet_rounded;
      case NotificationCategory.security:
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  List<Color> get iconGradient {
    switch (category) {
      case NotificationCategory.campaign:
        return const [Color(0xFF0284C7), Color(0xFF0EA5E9)];
      case NotificationCategory.wallet:
        return const [Color(0xFF059669), Color(0xFF10B981)];
      case NotificationCategory.security:
        return const [Color(0xFF7C3AED), Color(0xFF8B5CF6)];
      default:
        return const [Color(0xFF4F46E5), Color(0xFF6366F1)];
    }
  }

  Color get accentColor {
    switch (category) {
      case NotificationCategory.campaign:
        return const Color(0xFF0284C7);
      case NotificationCategory.wallet:
        return const Color(0xFF059669);
      case NotificationCategory.security:
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String? get metaChip {
    if (data is Map) {
      if (data['serviceCode'] != null) {
        return data['serviceCode'].toString().replaceAll('_', ' ');
      }
      if (data['amount'] != null) {
        return '₹${data['amount']}';
      }
      if (data['protection'] != null) {
        return 'Zero-Bot Shield';
      }
    }
    if (category == NotificationCategory.campaign) return 'Live Order';
    if (category == NotificationCategory.wallet) return 'Escrow';
    return null;
  }

  String? get route {
    if (category == NotificationCategory.campaign) return AppRouter.campaigns;
    if (category == NotificationCategory.wallet) return AppRouter.wallet;
    return null;
  }

  String? get actionLabel {
    if (category == NotificationCategory.campaign) return 'Track Campaign';
    if (category == NotificationCategory.wallet) return 'View Escrow';
    return null;
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationCategory _selectedFilter = NotificationCategory.all;
  bool _isLoading = true;
  String? _errorMessage;
  final List<BuyerNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.get(ApiEndpoints.notifications);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list =
            response.data['notifications'] ?? response.data['data'] ?? [];
        
        setState(() {
          _notifications.clear();
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              _notifications.add(BuyerNotification.fromJson(item));
            }
          }
          _isLoading = false;
        });
        return;
      }
      throw Exception('Failed to load notifications');
    } catch (e) {
      // Fallback to locally stored / verified notifications if server temporarily unreachable
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_notifications.isEmpty) {
            _errorMessage = 'Unable to refresh notifications. Tap to retry.';
          }
        });
      }
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<BuyerNotification> get _filteredNotifications {
    if (_selectedFilter == NotificationCategory.all) return _notifications;
    return _notifications.where((n) => n.category == _selectedFilter).toList();
  }

  Future<void> _markNotificationRead(BuyerNotification item) async {
    if (item.isRead) return;

    setState(() {
      item.isRead = true;
    });

    try {
      final dioClient = getIt<DioClient>();
      await dioClient.patch(ApiEndpoints.markNotificationRead(item.id));
    } catch (_) {
      // Ignore background network sync errors
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final dioClient = getIt<DioClient>();
      await dioClient.patch('/buyer/notifications/read-all');
    } catch (_) {
      // Background sync
    }
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
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: const Color(0xFFF8FAFC), // Pure clean light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Text(
              'Notification Center',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
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
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      blurRadius: 6,
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
          if (_notifications.isNotEmpty)
            IconButton(
              tooltip: 'Mark all as read',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.done_all_rounded,
                  size: 17,
                  color: Color(0xFF0284C7),
                ),
              ),
              onPressed: _markAllAsRead,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            onPressed: _fetchNotifications,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0284C7),
                strokeWidth: 2.5,
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF0284C7),
              backgroundColor: Colors.white,
              onRefresh: _fetchNotifications,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Filter bar
                  SliverToBoxAdapter(
                    child: _buildFilterChips(),
                  ),

                  // Content
                  if (_errorMessage != null && _notifications.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(),
                    )
                  else if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredList[index];
                            return _buildNotificationCard(item);
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Filter Chips Row
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('All Updates', NotificationCategory.all, _notifications.length),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Campaigns',
              NotificationCategory.campaign,
              _notifications.where((n) => n.category == NotificationCategory.campaign).length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Wallet',
              NotificationCategory.wallet,
              _notifications.where((n) => n.category == NotificationCategory.wallet).length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Security',
              NotificationCategory.security,
              _notifications.where((n) => n.category == NotificationCategory.security).length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationCategory cat, int count) {
    final isSelected = _selectedFilter == cat;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = cat;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Individual Notification Card (Pure White Theme)
  Widget _buildNotificationCard(BuyerNotification item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF0284C7).withValues(alpha: 0.4),
            width: item.isRead ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: item.isRead
                  ? const Color(0xFF0F172A).withValues(alpha: 0.04)
                  : const Color(0xFF0284C7).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _markNotificationRead(item);
              if (item.route != null) {
                Navigator.pushNamed(context, item.route!);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category tag + Icon + Time ago + Unread dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gradient Icon Container
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: item.iconGradient.first.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Category Label & Chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  item.categoryLabel,
                                  style: GoogleFonts.outfit(
                                    color: item.accentColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                if (item.metaChip != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      item.metaChip!,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF475569),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.timeAgo,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Unread Indicator
                      if (!item.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF0284C7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notification Title
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Notification Body
                  Text(
                    item.message,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),

                  // Action Footer
                  if (item.actionLabel != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.accentColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.actionLabel!,
                                style: GoogleFonts.outfit(
                                  color: item.accentColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: item.accentColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Clean Empty State
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications Yet',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up! Real-time updates about your marketing campaigns, task submissions, and escrow wallet will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Refresh Updates',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error State
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could Not Load Feed',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Check your network connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Retry',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
