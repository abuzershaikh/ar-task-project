import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/more_models.dart';
import '../bloc/more_bloc.dart';

class PayoutsQueueScreen extends StatefulWidget {
  const PayoutsQueueScreen({super.key});

  @override
  State<PayoutsQueueScreen> createState() => _PayoutsQueueScreenState();
}

class _PayoutsQueueScreenState extends State<PayoutsQueueScreen> with SingleTickerProviderStateMixin {
  final Set<String> _selectedItems = {};
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
    context.read<MoreBloc>().add(LoadPayoutsQueueEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF00875A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM yyyy, hh:mm a').format(ist);
  }

  List<PayoutItemModel> _filterList(List<PayoutItemModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) {
      final name = item.workerName.toLowerCase();
      final email = item.workerEmail.toLowerCase();
      final id = item.id.toLowerCase();
      final method = item.paymentMethod.toLowerCase();
      final txn = (item.transactionId ?? '').toLowerCase();
      final phone = (item.workerPhone ?? '').toLowerCase();
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          id.contains(_searchQuery) ||
          method.contains(_searchQuery) ||
          txn.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Payouts Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Payouts',
            onPressed: () => context.read<MoreBloc>().add(LoadPayoutsQueueEvent()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions_rounded, size: 20),
              text: 'Pending Requests',
            ),
            Tab(
              icon: Icon(Icons.verified_rounded, size: 20),
              text: 'Paid Records',
            ),
          ],
        ),
      ),
      body: BlocBuilder<MoreBloc, MoreState>(
        builder: (context, state) {
          if (state is MoreLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MoreError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<MoreBloc>().add(LoadPayoutsQueueEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PayoutsQueueLoaded) {
            final pendingItems = state.items;
            final historyItems = state.historyItems;
            final stats = state.stats;

            final totalPendingAmount = pendingItems.fold(0.0, (sum, i) => sum + i.amount);
            final totalPaidAmount = historyItems.fold(0.0, (sum, i) => sum + i.amount);

            final displayPendingCount = stats['pendingCount'] ?? pendingItems.length;
            final displayPaidCount = stats['paidCount'] ?? historyItems.length;

            final filteredPending = _filterList(pendingItems);
            final filteredHistory = _filterList(historyItems);

            return Column(
              children: [
                // Summary Stat Cards
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Pending Requests',
                              count: '$displayPendingCount',
                              amount: '₹${totalPendingAmount.toStringAsFixed(2)}',
                              icon: Icons.hourglass_top_rounded,
                              color: const Color(0xFFD97706),
                              bgColor: const Color(0xFFFEF3C7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Paid Out (Records)',
                              count: '$displayPaidCount',
                              amount: '₹${totalPaidAmount.toStringAsFixed(2)}',
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF16A34A),
                              bgColor: const Color(0xFFDCFCE7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by worker, UPI ID, or Txn ID...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Pending Queue
                      _buildPendingTab(filteredPending),

                      // Tab 2: Paid History Records
                      _buildPaidHistoryTab(filteredHistory),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String count,
    required String amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      count,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        amount,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending Queue Tab ───────────────────────────────────────────────────────
  Widget _buildPendingTab(List<PayoutItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No pending requests match your search' : 'No pending payouts in queue!',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItems.contains(item.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.amber.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Checkbox, ID, Status
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItems.add(item.id);
                          } else {
                            _selectedItems.remove(item.id);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          AppAvatar(
                            name: item.workerName,
                            imageUrl: item.avatarUrl,
                            userId: item.workerId,
                            radius: 17,
                            fontSize: 12,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.workerName.isNotEmpty ? item.workerName : 'Worker Account',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.workerEmail.isNotEmpty
                                      ? item.workerEmail
                                      : (item.workerPhone ?? (item.workerId.length > 8 ? '#${item.workerId.substring(0, 8)}' : item.workerId)),
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amount & Payment Method Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Requested Amount', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '₹${item.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Payout Destination', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _copyToClipboard(item.paymentMethod, 'UPI/Bank details'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.paymentMethod,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF0369A1),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF0369A1)),
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

                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Requested: ${_formatDateTime(item.requestedAt)}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons: Decline vs Approve & Process
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(context, item),
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                        label: const Text(
                          'Decline',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<MoreBloc>().add(ProcessPayoutEvent(item.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Processing payout for ${item.workerName}...'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                        label: const Text('Approve & Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Paid Records Tab (Jinko Payout Gaya Hai) ────────────────────────────────
  Widget _buildPaidHistoryTab(List<PayoutItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No paid records match your search' : 'No payout records found.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFBBF7D0), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Worker Avatar, Name, Email, Status Badge
                Row(
                  children: [
                    AppAvatar(
                      name: item.workerName,
                      imageUrl: item.avatarUrl,
                      userId: item.workerId,
                      radius: 19,
                      fontSize: 13,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.workerName.isNotEmpty ? item.workerName : 'Worker Account',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF16A34A)),
                            ],
                          ),
                          Text(
                            item.workerEmail.isNotEmpty
                                ? item.workerEmail
                                : (item.workerPhone ?? (item.workerId.length > 8 ? '#${item.workerId.substring(0, 8)}' : item.workerId)),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF15803D)),
                          SizedBox(width: 4),
                          Text(
                            'PAID',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amount & Payout Destination
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Paid Amount', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                '₹${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Paid via / Destination', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 3),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(item.paymentMethod, 'UPI/Bank details'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.paymentMethod,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (item.transactionId != null && item.transactionId!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Txn Reference:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            GestureDetector(
                              onTap: () => _copyToClipboard(item.transactionId!, 'Transaction ID'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.transactionId!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF0369A1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Timestamps (Requested & Paid At)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Requested: ${_formatDateTime(item.requestedAt)}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF15803D)),
                        const SizedBox(width: 4),
                        Text(
                          'Paid: ${_formatDateTime(item.paidAt ?? item.requestedAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, PayoutItemModel item) {
    String selectedReason = 'Invalid UPI ID / Bank account details';
    final customReasonController = TextEditingController();
    bool isCustom = false;

    final reasons = [
      'Invalid UPI ID / Bank account details',
      'Account holder name mismatch',
      'Suspicious / fraudulent activity detected',
      'KYC or identity verification required',
      'Other reason (type below)',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Decline Withdrawal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decline payout of ₹${item.amount.toStringAsFixed(2)} for ${item.workerName.isNotEmpty ? item.workerName : 'Worker'}?',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select decline reason:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...reasons.map((r) => RadioListTile<String>(
                      title: Text(r, style: const TextStyle(fontSize: 12.5)),
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReason = val;
                            isCustom = val.startsWith('Other');
                          });
                        }
                      },
                    )),
                if (isCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter specific decline reason...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The requested amount will be automatically refunded back to the worker\'s wallet balance.',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reasonToSubmit = isCustom
                    ? (customReasonController.text.trim().isNotEmpty
                        ? customReasonController.text.trim()
                        : 'Admin declined payout request')
                    : selectedReason;

                Navigator.pop(dialogContext);
                context.read<MoreBloc>().add(RejectPayoutEvent(item.id, reasonToSubmit));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payout declined. ₹${item.amount.toStringAsFixed(2)} refunded to worker.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Decline & Refund', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
