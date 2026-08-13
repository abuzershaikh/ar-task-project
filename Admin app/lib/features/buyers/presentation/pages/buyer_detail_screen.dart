import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/buyer_detail_tabs/overview_tab.dart';
import '../widgets/buyer_detail_tabs/orders_tab.dart';
import '../widgets/buyer_detail_tabs/tasks_tab.dart';
import '../widgets/buyer_detail_tabs/payments_tab.dart';
import '../widgets/buyer_detail_tabs/reviews_tab.dart';
import '../widgets/buyer_detail_tabs/analytics_tab.dart';
import '../widgets/buyer_detail_tabs/activity_tab.dart';
import '../widgets/buyer_detail_tabs/risk_tab.dart';

class BuyerDetailScreen extends StatefulWidget {
  final String buyerId;

  const BuyerDetailScreen({
    super.key,
    required this.buyerId,
  });

  @override
  State<BuyerDetailScreen> createState() => _BuyerDetailScreenState();
}

class _BuyerDetailScreenState extends State<BuyerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buyer Details'),
            Text(
              widget.buyerId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              _handleAction(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text('Suspend Buyer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Block Buyer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_credit',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Add Credit'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Tasks'),
            Tab(text: 'Payments'),
            Tab(text: 'Reviews'),
            Tab(text: 'Analytics'),
            Tab(text: 'Activity'),
            Tab(text: 'Risk'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BuyerOverviewTab(buyerId: widget.buyerId),
          BuyerOrdersTab(buyerId: widget.buyerId),
          BuyerTasksTab(buyerId: widget.buyerId),
          BuyerPaymentsTab(buyerId: widget.buyerId),
          BuyerReviewsTab(buyerId: widget.buyerId),
          BuyerAnalyticsTab(buyerId: widget.buyerId),
          BuyerActivityTab(buyerId: widget.buyerId),
          BuyerRiskTab(buyerId: widget.buyerId),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'suspend':
        _showConfirmDialog('Suspend Buyer', 'Are you sure you want to suspend this buyer?');
        break;
      case 'block':
        _showConfirmDialog('Block Buyer', 'Are you sure you want to block this buyer?');
        break;
      case 'add_credit':
        _showAddCreditDialog();
        break;
    }
  }

  void _showConfirmDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason (Required)',
                hintText: 'Enter reason for this action',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Buyer Credit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Refund, Compensation, etc.',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Add Credit'),
          ),
        ],
      ),
    );
  }
}
