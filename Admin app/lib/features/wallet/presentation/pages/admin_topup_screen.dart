import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/admin_wallet_repository.dart';

class AdminTopupScreen extends StatefulWidget {
  const AdminTopupScreen({super.key});

  @override
  State<AdminTopupScreen> createState() => _AdminTopupScreenState();
}

class _AdminTopupScreenState extends State<AdminTopupScreen> {
  final AdminWalletRepository _walletRepo = AdminWalletRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _buyers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyers() async {
    setState(() => _isLoading = true);
    final buyers = await _walletRepo.getBuyersWithWallet(search: _searchQuery);
    if (mounted) {
      setState(() {
        _buyers = buyers;
        _isLoading = false;
      });
    }
  }

  double _calculateTotalBuyerBalance() {
    double total = 0;
    for (var b in _buyers) {
      final w = b['wallet'];
      if (w != null && w['availableBalance'] != null) {
        total += (w['availableBalance'] as num).toDouble();
      }
    }
    return total;
  }

  void _openTopupSheet(Map<String, dynamic> buyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BuyerTopupModal(
        buyer: buyer,
        walletRepo: _walletRepo,
        onSuccess: () {
          _loadBuyers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _calculateTotalBuyerBalance();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Buyer Wallet & Top-Up',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadBuyers,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadBuyers,
        child: Column(
          children: [
            // ── Top Summary Header Card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Buyer Wallet Pool',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${totalBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_buyers.length} Buyers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search & Filter Input ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _loadBuyers();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search buyer by name, email or ID...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadBuyers();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Buyer List ──────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _buyers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No buyers matching "$_searchQuery"'
                                    : 'No registered buyers found',
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _buyers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final buyer = _buyers[index];
                            final fullName = buyer['fullName'] ?? 'Buyer User';
                            final email = buyer['email'] ?? '';
                            final wallet = buyer['wallet'] ?? {};
                            final double available = (wallet['availableBalance'] ?? 0.0).toDouble();

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'B',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'ID: ${(buyer['id'] ?? '').toString().substring(0, 10)}...',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF475569),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Balance & Top-up Button
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${available.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Color(0xFF00875A),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Text(
                                          'Wallet Balance',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          icon: const Icon(Icons.add_card_rounded, size: 14),
                                          label: const Text('Top-Up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () => _openTopupSheet(buyer),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerTopupModal extends StatefulWidget {
  final Map<String, dynamic> buyer;
  final AdminWalletRepository walletRepo;
  final VoidCallback onSuccess;

  const _BuyerTopupModal({
    required this.buyer,
    required this.walletRepo,
    required this.onSuccess,
  });

  @override
  State<_BuyerTopupModal> createState() => _BuyerTopupModalState();
}

class _BuyerTopupModalState extends State<_BuyerTopupModal> {
  final TextEditingController _amountController = TextEditingController(text: '1000');
  final TextEditingController _notesController = TextEditingController(text: 'Admin Wallet Top-up');
  String _type = 'CREDIT';
  bool _isProcessing = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTxns = true;

  final List<double> _quickAmounts = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final buyerId = widget.buyer['id'].toString();
    final txns = await widget.walletRepo.getBuyerTransactions(buyerId);
    if (mounted) {
      setState(() {
        _transactions = txns;
        _isLoadingTxns = false;
      });
    }
  }

  Future<void> _processTopup() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final buyerId = widget.buyer['id'].toString();
      final res = await widget.walletRepo.topupBuyer(
        buyerId: buyerId,
        amount: amount,
        type: _type,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (res != null && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${res['message'] ?? 'Top-up processed successfully!'}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
        Navigator.pop(context);
      } else {
        throw Exception('Operation failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      String errorMsg = e.toString();
      try {
        final dynamic err = e;
        if (err.response?.data != null) {
          final data = err.response.data;
          errorMsg = data['error']?['message'] ?? data['message'] ?? errorMsg;
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ $errorMsg'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.buyer['fullName'] ?? 'Buyer User';
    final email = widget.buyer['email'] ?? '';
    final wallet = widget.buyer['wallet'] ?? {};
    final double available = (wallet['availableBalance'] ?? 0.0).toDouble();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle pill
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
            const SizedBox(height: 16),

            // Header info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'B',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${available.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF00875A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode Selector (Credit vs Debit)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'CREDIT'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _type == 'CREDIT' ? const Color(0xFF00875A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '+ Credit (Add Balance)',
                            style: TextStyle(
                              color: _type == 'CREDIT' ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'DEBIT'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _type == 'DEBIT' ? Colors.red.shade600 : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '- Debit (Deduct)',
                            style: TextStyle(
                              color: _type == 'DEBIT' ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Amount Pills
            const Text('Quick Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAmounts.map((amt) {
                  final isSelected = _amountController.text == amt.toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('₹${amt.toStringAsFixed(0)}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _amountController.text = amt.toStringAsFixed(0);
                          });
                        }
                      },
                      selectedColor: _type == 'CREDIT' ? const Color(0xFFE6F4EA) : const Color(0xFFFEE2E2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (_type == 'CREDIT' ? const Color(0xFF00875A) : Colors.red.shade700)
                            : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Amount TextField
            const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Remarks TextField
            const Text('Remarks / Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. Promotional credit, correction...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'CREDIT' ? const Color(0xFF00875A) : Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _processTopup,
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _type == 'CREDIT' ? 'Credit Balance to Buyer' : 'Deduct Balance from Buyer',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Transactions List
            const Text('Recent Buyer Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            if (_isLoadingTxns)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('No transaction history yet', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final txn = _transactions[i];
                  final isCredit = txn['type'] == 'CREDIT';
                  final amount = (txn['amount'] ?? 0.0).toString();
                  final desc = txn['description'] ?? 'Transaction';
                  final date = (txn['createdAt'] ?? '').toString().split('T').first;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isCredit ? const Color(0xFFE6F4EA) : const Color(0xFFFEE2E2),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 16,
                        color: isCredit ? const Color(0xFF00875A) : Colors.red.shade700,
                      ),
                    ),
                    title: Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    subtitle: Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    trailing: Text(
                      '${isCredit ? '+' : '-'}₹$amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isCredit ? const Color(0xFF00875A) : Colors.red.shade700,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
