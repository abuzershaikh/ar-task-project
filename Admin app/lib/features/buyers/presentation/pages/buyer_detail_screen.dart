import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/buyers_bloc.dart';
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
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _creditAmountController = TextEditingController();
  final TextEditingController _creditReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    context.read<BuyersBloc>().add(LoadBuyerDetailEvent(widget.buyerId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _creditAmountController.dispose();
    _creditReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.buyerId.length > 14
        ? '#${widget.buyerId.substring(0, 8)}...${widget.buyerId.substring(widget.buyerId.length - 4)}'
        : widget.buyerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        titleSpacing: 14,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: BlocBuilder<BuyersBloc, BuyersState>(
          builder: (context, state) {
            String name = 'Buyer Commercial Profile';
            String email = shortId;
            if (state is BuyerDetailLoaded && state.buyer.id == widget.buyerId) {
              name = state.buyer.name.isNotEmpty ? state.buyer.name : 'Buyer Profile';
              email = state.buyer.email.isNotEmpty ? state.buyer.email : shortId;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text(
                  email,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFEDE9FE), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              _handleAction(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text('Suspend Buyer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text('Block Buyer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_credit',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Color(0xFF16A34A), size: 20),
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
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14.0),
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
      body: BlocBuilder<BuyersBloc, BuyersState>(
        builder: (context, state) {
          if (state is BuyersLoading || state is BuyerDetailLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
          }
          if (state is BuyersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Color(0xFFDC2626))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                    onPressed: () {
                      context.read<BuyersBloc>().add(LoadBuyerDetailEvent(widget.buyerId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is BuyerDetailLoaded) {
            final detailState = state as BuyerDetailLoaded;
            if (detailState.buyer.id != widget.buyerId) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
            }
            return TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(buyer: detailState.buyer, orders: detailState.orders, payments: detailState.payments),
                OrdersTab(buyer: detailState.buyer, orders: detailState.orders),
                TasksTab(tasks: detailState.tasks),
                PaymentsTab(buyer: detailState.buyer, payments: detailState.payments),
                ReviewsTab(buyer: detailState.buyer),
                AnalyticsTab(buyer: detailState.buyer, orders: detailState.orders),
                ActivityTab(activity: detailState.activity),
                RiskTab(buyer: detailState.buyer),
              ],
            );
          }
          
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
        },
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
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final status = title.toLowerCase().contains('block') ? 'BANNED' : 'SUSPENDED';
              context.read<BuyersBloc>().add(
                UpdateBuyerStatusEvent(buyerId: widget.buyerId, status: status),
              );
              Navigator.pop(dialogContext);
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Buyer Credit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _creditAmountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _creditReasonController,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_creditAmountController.text.trim()) ?? 0.0;
              final reason = _creditReasonController.text.trim();
              if (amount > 0) {
                context.read<BuyersBloc>().add(
                  AdjustBuyerBalanceEvent(buyerId: widget.buyerId, amount: amount, reason: reason),
                );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Add Credit'),
          ),
        ],
      ),
    );
  }
}
