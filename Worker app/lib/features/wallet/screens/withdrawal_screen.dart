import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

/// Separate Withdrawal Screen:
/// - Allows user to enter payout amount, select quick chips, verify UPI ID, and request instant payout.
/// - Styled with royal light blue & sapphire premium theme tokens.
class WithdrawalScreen extends StatefulWidget {
  final double availableBalance;

  const WithdrawalScreen({
    super.key,
    required this.availableBalance,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController(text: '100');
  final _upiController = TextEditingController(text: 'worker@upi');
  bool _isLoading = false;

  void _requestPayout() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payout amount')),
      );
      return;
    }

    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum withdrawal amount is ₹100'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entered amount exceeds available balance'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response =
        await ApiService.requestPayout(amount, _upiController.text.trim());
    setState(() => _isLoading = false);

    if (mounted) {
      final bool isSuccess = response['error'] == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Payout Request Submitted!'),
          backgroundColor:
              isSuccess ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
        ),
      );
      if (isSuccess) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double enteredAmount = double.tryParse(_amountController.text) ?? 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Withdraw Money',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ready to withdraw',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      '₹${widget.availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Section Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Withdrawal Amount',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount Input Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          // All Balance Pill Button
                          InkWell(
                            onTap: () {
                              final maxBal = widget.availableBalance.toInt();
                              _amountController.text = maxBal.toString();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: const Text(
                                'All Balance',
                                style: TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Chips Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [100, 200, 500, 1000].map((amt) {
                        final isSelected = _amountController.text == amt.toString();
                        return InkWell(
                          onTap: () {
                            _amountController.text = amt.toString();
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '₹$amt',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Destination Box (UPI ID)
                    const Text(
                      'Payout Destination (UPI ID)',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFF0284C7),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _upiController.text,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Security Note
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Instant & safe withdrawal via UPI transfer.',
                              style: TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Summary Breakdown Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Withdrawal Amount',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              Text('₹${enteredAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Processing Fee',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              Text('₹0.00 (Free)',
                                  style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Net Payout Amount',
                                  style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              Text('₹${enteredAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payout CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestPayout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Request Instant Payout',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
      ),
    );
  }
}
