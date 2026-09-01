import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/services/api_service.dart';
import '../../profile/screens/kyc_bank_details_screen.dart';

/// Withdrawal Screen:
/// - Allows worker to enter payout amount, select dynamic quick chips, verify linked UPI/Bank, and request instant payout.
/// - Fixes dark theme input decoration leakage (black stripe overlay).
/// - Styled with Royal Light Blue & Sapphire premium theme tokens.
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
  late final TextEditingController _amountController;
  late final TextEditingController _upiController;
  bool _isLoading = false;
  double _minLimit = 100.0;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profileData;
    final wallet = context.read<TaskProvider>().walletData;

    _minLimit = double.tryParse(wallet['minWithdrawalLimit']?.toString() ?? '') ?? 100.0;
    final defaultAmt = widget.availableBalance >= _minLimit ? _minLimit.toInt().toString() : '100';
    _amountController = TextEditingController(text: defaultAmt);

    // Extract real UPI ID or fallback to profile email/phone UPI
    final realUpi = profile['upiId'] ?? 
                    profile['bankDetails']?['upiId'] ?? 
                    (profile['phone'] != null && profile['phone'].toString().isNotEmpty ? '${profile['phone']}@upi' : '');
    _upiController = TextEditingController(text: realUpi.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _requestPayout() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid withdrawal amount'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final profile = context.read<ProfileProvider>().profileData;
    final kycStatus = (profile['kycStatus'] ?? 'DRAFT').toString().toUpperCase();

    if (kycStatus != 'VERIFIED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add and verify your bank/UPI details before withdrawing.'),
          backgroundColor: const Color(0xFFDC2626),
          action: SnackBarAction(
            label: 'Add Details',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
              ).then((_) {
                if (mounted) {
                  context.read<ProfileProvider>().fetchProfile();
                }
              });
            },
          ),
        ),
      );
      return;
    }

    if (amount < _minLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal amount is ₹${_minLimit.toStringAsFixed(0)}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entered amount exceeds your available balance'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final upi = _upiController.text.trim();
    if (upi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a valid UPI ID for payout destination'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.requestPayout(amount, upi);
    setState(() => _isLoading = false);

    if (mounted) {
      final bool isSuccess = response['error'] == null && (response['success'] == true || response['status'] != null);
      if (isSuccess) {
        // Refresh wallet and profile in background
        context.read<TaskProvider>().fetchWalletData();
        context.read<ProfileProvider>().fetchProfile();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Payout Initiated', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              'Your withdrawal request of ₹${amount.toStringAsFixed(2)} has been submitted successfully to $upi. Funds will be credited shortly.',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? response['error'] ?? 'Failed to submit withdrawal request'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profileData;
    final kycStatus = (profile['kycStatus'] ?? 'DRAFT').toString().toUpperCase();
    final isKycVerified = kycStatus == 'VERIFIED';
    final double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;

    // Dynamic quick chips
    final List<int> quickChips = [];
    if (_minLimit.toInt() > 0) quickChips.add(_minLimit.toInt());
    if (!quickChips.contains(250) && widget.availableBalance >= 250) quickChips.add(250);
    if (!quickChips.contains(500) && widget.availableBalance >= 500) quickChips.add(500);
    if (!quickChips.contains(1000) && widget.availableBalance >= 1000) quickChips.add(1000);
    if (quickChips.isEmpty) quickChips.addAll([100, 200, 500, 1000]);

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                        SizedBox(height: 3),
                        Text(
                          'Ready for Instant Withdrawal',
                          style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
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



              const SizedBox(height: 16),

              // Form Section Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount Input Box — Cleaned of dark theme overlay artifact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4), width: 1.5),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              cursorColor: const Color(0xFF2563EB),
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                hintText: '0',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 18),
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
                                'Max Balance',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickChips.map((amt) {
                        final isSelected = _amountController.text == amt.toString();
                        return InkWell(
                          onTap: () {
                            _amountController.text = amt.toString();
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

                    // Destination Box (UPI ID / Bank Details)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payout Destination (UPI / Bank)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
                            ).then((_) {
                              if (mounted) {
                                context.read<ProfileProvider>().fetchProfile();
                              }
                            });
                          },
                          child: Text(
                            isKycVerified ? 'Change' : 'Link Method',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              color: isKycVerified ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isKycVerified ? Icons.verified_user_rounded : Icons.account_balance_wallet_outlined,
                              color: isKycVerified ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _upiController,
                              cursorColor: const Color(0xFF2563EB),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: isKycVerified ? 'Enter UPI ID' : 'Add verified UPI ID in KYC',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ),
                          ),
                          if (isKycVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
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
                          Icon(Icons.shield_outlined, size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Instant, automated & secure payout directly to your bank/UPI.',
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

                    const SizedBox(height: 16),

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
                                      color: Color(0xFF16A34A),
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

                    const SizedBox(height: 18),

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
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
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
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
