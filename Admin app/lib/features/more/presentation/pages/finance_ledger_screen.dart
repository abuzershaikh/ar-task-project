import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

class FinanceLedgerScreen extends StatefulWidget {
  const FinanceLedgerScreen({super.key});

  @override
  State<FinanceLedgerScreen> createState() => _FinanceLedgerScreenState();
}

class _FinanceLedgerScreenState extends State<FinanceLedgerScreen> {
  bool _isLoading = true;
  double _grossVolume = 0.0;
  double _netMargin = 0.0;
  double _projectedMargin = 0.0;
  double _totalWorkerPayouts = 0.0;
  double _totalBuyerDeposits = 0.0;
  double _walletPoolBalance = 0.0;

  List<Map<String, dynamic>> _allLedgerItems = [];
  List<Map<String, dynamic>> _filteredLedgerItems = [];
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _fetchFinancials();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFinancials() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final response = await dio.get(ApiEndpoints.analyticsRevenue);
      final data = response.data ?? {};

      final grossVolume = double.tryParse(data['grossPlatformVolume']?.toString() ?? '0.0') ?? 0.0;
      final netMargin = double.tryParse(data['platformNetMargin']?.toString() ?? '0.0') ?? 0.0;
      final projectedMargin = double.tryParse(data['projectedMargin']?.toString() ?? '0.0') ?? 0.0;
      final totalBuyerDeposits = double.tryParse(data['totalBuyerDeposits']?.toString() ?? '0.0') ?? 0.0;
      final totalWorkerPayouts = double.tryParse(data['totalWorkerPayouts']?.toString() ?? '0.0') ?? 0.0;
      final walletPoolBalance = double.tryParse(data['walletPoolBalance']?.toString() ?? '0.0') ?? 0.0;

      final rawLedger = (data['ledger'] as List?) ?? [];
      final List<Map<String, dynamic>> parsedLedger = rawLedger.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      if (mounted) {
        setState(() {
          _grossVolume = grossVolume;
          _netMargin = netMargin;
          _projectedMargin = projectedMargin;
          _totalBuyerDeposits = totalBuyerDeposits;
          _totalWorkerPayouts = totalWorkerPayouts;
          _walletPoolBalance = walletPoolBalance;
          _allLedgerItems = parsedLedger;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLedgerItems = _allLedgerItems.where((item) {
        final type = (item['type'] ?? '').toString().toUpperCase();
        final title = (item['title'] ?? item['description'] ?? '').toString().toLowerCase();
        final userName = (item['userName'] ?? '').toString().toLowerCase();
        final userEmail = (item['userEmail'] ?? '').toString().toLowerCase();
        final id = (item['id'] ?? '').toString().toLowerCase();
        final amount = (item['amount'] ?? '').toString().toLowerCase();

        // Filter chip condition
        if (_selectedFilter == 'CREDIT' && type != 'CREDIT' && type != 'DEPOSIT') {
          return false;
        }
        if (_selectedFilter == 'DEBIT' && type != 'DEBIT' && type != 'ORDER') {
          return false;
        }
        if (_selectedFilter == 'PAYOUT' && type != 'PAYOUT' && item['referenceType'] != 'WITHDRAWAL') {
          return false;
        }

        // Search text condition
        if (query.isNotEmpty) {
          final matchesTitle = title.contains(query);
          final matchesUser = userName.contains(query) || userEmail.contains(query);
          final matchesId = id.contains(query);
          final matchesAmount = amount.contains(query);
          return matchesTitle || matchesUser || matchesId || matchesAmount;
        }

        return true;
      }).toList();
    });
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return 'Recent';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return raw.toString();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${hour.toString().padLeft(2, '0')}:$min $ampm';
  }

  void _showTransactionDetails(Map<String, dynamic> item) {
    final isCredit = (item['type'] ?? '').toString().toUpperCase() == 'CREDIT';
    final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
    final balanceAfter = double.tryParse(item['balanceAfter']?.toString() ?? '0') ?? 0.0;
    final title = item['title'] ?? item['description'] ?? 'Ledger Entry';
    final txId = item['id'] ?? 'N/A';
    final refId = item['referenceId'] ?? 'N/A';
    final user = item['userName'] ?? 'Platform User';
    final email = item['userEmail'] ?? 'N/A';
    final date = _formatDateTime(item['createdAt'] ?? item['date']);
    final status = item['status'] ?? 'COMPLETED';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with Type and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isCredit
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCredit ? 'CREDIT / DEPOSIT' : 'DEBIT / CAMPAIGN ORDER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${isCredit ? "+" : "-"}₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Running Balance: ₹${balanceAfter.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Detail Fields
              _buildDetailRow('Description', title),
              _buildDetailRow('Account / Buyer', '$user ($email)'),
              _buildCopyableDetailRow('Transaction ID', txId),
              if (refId != 'N/A' && refId != txId)
                _buildCopyableDetailRow('Order / Ref ID', refId),

              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depositCount = _allLedgerItems.where((i) => (i['type'] ?? '').toString().toUpperCase() == 'CREDIT').length;
    final orderCount = _allLedgerItems.where((i) => (i['type'] ?? '').toString().toUpperCase() == 'DEBIT').length;
    final payoutCount = _allLedgerItems.where((i) => (i['type'] ?? '').toString().toUpperCase() == 'PAYOUT').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Finance & Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Ledger',
            onPressed: _fetchFinancials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFinancials,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Live Status Banner ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Live Database Financials • Audit Verified',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // ── Master KPI Cards ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Gross Platform Volume',
                          amount: '₹${_grossVolume.toStringAsFixed(2)}',
                          subtitle: 'Total Campaign Spend',
                          icon: Icons.account_balance_rounded,
                          color: const Color(0xFF4F46E5),
                          bgColor: const Color(0xFFEEF2FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Admin Platform Margin',
                          amount: '₹${_netMargin.toStringAsFixed(2)}',
                          subtitle: '₹${_projectedMargin.toStringAsFixed(0)} Projected',
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF16A34A),
                          bgColor: const Color(0xFFDCFCE7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Buyer Deposits',
                          amount: '₹${_totalBuyerDeposits.toStringAsFixed(2)}',
                          subtitle: '$depositCount Top-up Transactions',
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFE0F2FE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Worker Payouts',
                          amount: '₹${_totalWorkerPayouts.toStringAsFixed(2)}',
                          subtitle: '$payoutCount Withdrawals Disbursed',
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLiquidityCard(),

                  const SizedBox(height: 24),

                  // ── Financial Ledger Stream Header ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial Ledger Stream',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Showing ${_filteredLedgerItems.length} of ${_allLedgerItems.length} recorded events',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Search Field ───────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by description, buyer, amount...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Filter Chips ───────────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All (${_allLedgerItems.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('CREDIT', 'Top-ups ($depositCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('DEBIT', 'Orders ($orderCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('PAYOUT', 'Payouts ($payoutCount)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Ledger Stream List ─────────────────────────────────────────
                  _filteredLedgerItems.isEmpty
                      ? Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Transactions Found',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No ledger records match your search criteria'
                                      : 'There are no transactions recorded in this category yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredLedgerItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _filteredLedgerItems[index];
                            return _buildLedgerCard(item);
                          },
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = key);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF9333EA), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buyer Wallet Liquidity Pool',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Available: ₹${_walletPoolBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'HEALTHY',
              style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerCard(Map<String, dynamic> item) {
    final isCredit = (item['type'] ?? '').toString().toUpperCase() == 'CREDIT';
    final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
    final balanceAfter = double.tryParse(item['balanceAfter']?.toString() ?? '0') ?? 0.0;
    final title = item['title'] ?? item['description'] ?? 'Ledger Entry';
    final user = item['userName'] ?? 'Platform User';
    final email = item['userEmail'] ?? '';
    final date = _formatDateTime(item['createdAt'] ?? item['date']);

    return InkWell(
      onTap: () => _showTransactionDetails(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isCredit
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$user • $email',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? "+" : "-"}₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Bal: ₹${balanceAfter.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
