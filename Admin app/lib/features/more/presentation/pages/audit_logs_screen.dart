import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs Stream'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by admin, action, or entity ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchController.clear());
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filter Pills
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Worker Actions',
                  'Buyer Actions',
                  'Order Actions',
                  'Financial',
                  'Security',
                ].map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      backgroundColor: AppColors.gray100,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray300),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Audit Log Stream
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<MoreBloc>().add(LoadAuditLogsEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 50,
                itemBuilder: (context, index) {
                  return _buildAuditLogItem(index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogItem(int index) {
    final actions = [
      {
        'action': 'WORKER_SUSPENDED',
        'description': 'Suspended worker W-1024',
        'admin': 'Admin John (A-102)',
        'icon': Icons.pause_circle,
        'color': AppColors.warning,
        'category': 'Worker',
      },
      {
        'action': 'PAYOUT_APPROVED',
        'description': 'Approved payout WD-5678 (₹500)',
        'admin': 'Admin Sarah (A-103)',
        'icon': Icons.account_balance_wallet,
        'color': AppColors.success,
        'category': 'Financial',
      },
      {
        'action': 'TASK_REVIEWED',
        'description': 'Approved task T-10245',
        'admin': 'Admin Mike (A-104)',
        'icon': Icons.rate_review,
        'color': AppColors.info,
        'category': 'Review',
      },
      {
        'action': 'KYC_APPROVED',
        'description': 'Verified KYC for worker W-2045',
        'admin': 'Admin Lisa (A-105)',
        'icon': Icons.verified_user,
        'color': AppColors.success,
        'category': 'Security',
      },
      {
        'action': 'ORDER_CANCELLED',
        'description': 'Cancelled order ORD-1234 and refunded buyer',
        'admin': 'Admin Tom (A-106)',
        'icon': Icons.cancel,
        'color': AppColors.error,
        'category': 'Order',
      },
      {
        'action': 'BUYER_CREDIT_ADDED',
        'description': 'Added ₹5,000 credit to buyer B-102',
        'admin': 'Admin John (A-102)',
        'icon': Icons.add_circle,
        'color': AppColors.primary,
        'category': 'Financial',
      },
    ];

    final log = actions[index % actions.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (log['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(log['icon'] as IconData, color: log['color'] as Color, size: 20),
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
                          log['action'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log['category'] as String,
                          style: const TextStyle(fontSize: 10, color: AppColors.gray700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['description'] as String,
                    style: const TextStyle(fontSize: 13, color: AppColors.gray700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        log['admin'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                      ),
                      const Spacer(),
                      Text(
                        _getTimeAgo(index),
                        style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                      ),
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

  String _getTimeAgo(int index) {
    if (index < 5) return '${index + 1} min ago';
    if (index < 20) return '${index} min ago';
    if (index < 30) return '${(index / 2).floor()} hours ago';
    return '${index - 25} hours ago';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Action Type'),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Actions')),
                DropdownMenuItem(value: 'WORKER', child: Text('Worker Actions')),
                DropdownMenuItem(value: 'BUYER', child: Text('Buyer Actions')),
                DropdownMenuItem(value: 'FINANCIAL', child: Text('Financial Actions')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Admin User'),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Admins')),
                DropdownMenuItem(value: 'A-102', child: Text('Admin John')),
                DropdownMenuItem(value: 'A-103', child: Text('Admin Sarah')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Time Range'),
              items: const [
                DropdownMenuItem(value: '1H', child: Text('Last 1 Hour')),
                DropdownMenuItem(value: '24H', child: Text('Last 24 Hours')),
                DropdownMenuItem(value: '7D', child: Text('Last 7 Days')),
                DropdownMenuItem(value: '30D', child: Text('Last 30 Days')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Apply')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
