import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/enums.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        title: const Text('Order Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withAlpha(178),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Payment Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Paused'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(status: null),
          _OrdersList(status: OrderStatus.paymentPending),
          _OrdersList(status: OrderStatus.active),
          _OrdersList(status: OrderStatus.paused),
          _OrdersList(status: OrderStatus.completed),
          _OrdersList(status: OrderStatus.cancelled),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final OrderStatus? status;

  const _OrdersList({this.status});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        final orderStatus = status ??
            [
              OrderStatus.active,
              OrderStatus.paymentPending,
              OrderStatus.paused,
              OrderStatus.completed
            ][index % 4];

        return _OrderCard(
          orderId: 'CAMP-${10025 + index}',
          buyerName: 'Company ${index + 1}',
          serviceName: 'Product Testing',
          totalTasks: 100,
          completed: 72 - (index * 2),
          inProgress: 12,
          pending: 8 + (index * 2),
          totalAmount: 2500,
          status: orderStatus,
          onTap: () {},
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String buyerName;
  final String serviceName;
  final int totalTasks;
  final int completed;
  final int inProgress;
  final int pending;
  final int totalAmount;
  final OrderStatus status;
  final VoidCallback onTap;

  const _OrderCard({
    required this.orderId,
    required this.buyerName,
    required this.serviceName,
    required this.totalTasks,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.totalAmount,
    required this.status,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case OrderStatus.draft:
        return AppColors.gray400;
      case OrderStatus.paymentPending:
        return AppColors.warning;
      case OrderStatus.active:
        return AppColors.success;
      case OrderStatus.paused:
        return AppColors.info;
      case OrderStatus.completed:
        return AppColors.gray600;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    return status.name.toUpperCase().replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = (completed / totalTasks * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                orderId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          buyerName,
                          style: const TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: AppColors.gray600),
                    const SizedBox(width: 6),
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.assignment, size: 16, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      '$totalTasks Tasks',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: completionRate / 100,
                                  backgroundColor: AppColors.gray200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    completionRate > 80
                                        ? AppColors.success
                                        : completionRate > 50
                                            ? AppColors.info
                                            : AppColors.warning,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$completionRate%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                      Text(
                        '₹$totalAmount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatusBadge(
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    value: completed.toString(),
                    color: AppColors.success,
                  ),
                  _StatusBadge(
                    icon: Icons.timelapse,
                    label: 'In Progress',
                    value: inProgress.toString(),
                    color: AppColors.info,
                  ),
                  _StatusBadge(
                    icon: Icons.pending_outlined,
                    label: 'Pending',
                    value: pending.toString(),
                    color: AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}
