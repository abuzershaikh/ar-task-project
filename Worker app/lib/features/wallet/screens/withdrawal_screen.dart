import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/services/api_service.dart';
import '../../profile/screens/kyc_bank_details_screen.dart';

/// Withdrawal Screen:
/// - Allows worker to enter payout amount, select dynamic quick chips, verify linked UPI/Bank/PayPal, and request instant payout.
/// - Shows real saved payout methods from live KYC/profile data.
/// - Styled with White & Sapphire/Royal Blue premium fin-tech tokens.
/// - Zero dark-theme artifacts: full light-theme encapsulation.
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
  late final TextEditingController _paypalController;
  bool _isLoading = false;
  double _minLimit = 100.0;
  String _selectedMethod = 'UPI'; // 'UPI' | 'BANK' | 'PAYPAL'

  // ── Color Tokens ────────────────────────────────────────────────────────────
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _bluePrimary = Color(0xFF2563EB); // Royal Blue
  static const Color _blueNavy = Color(0xFF1E3A8A);    // Deep Sapphire
  static const Color _blueIce = Color(0xFFEFF6FF);     // Soft Ice Blue
  static const Color _blueBorder = Color(0xFFDBEAFE);  // Border Ice Blue
  static const Color _textNavy = Color(0xFF0F172A);    // High-contrast slate navy
  static const Color _textSubtle = Color(0xFF64748B);  // Muted Slate
  static const Color _textHint = Color(0xFF94A3B8);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _successBg = Color(0xFFDCFCE7);
  static const Color _paypalBlue = Color(0xFF003087);
  static const Color _paypalCyan = Color(0xFF0079C1);

  final List<String> _upiChips = [
    '@okhdfcbank',
    '@oksbi',
    '@paytm',
    '@ybl',
  ];

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    final wallet = context.read<TaskProvider>().walletData;
    final bankDetails = profileProvider.bankDetails;

    _minLimit = double.tryParse(wallet['minWithdrawalLimit']?.toString() ?? '') ?? 100.0;
    final defaultAmt = widget.availableBalance >= _minLimit ? _minLimit.toInt().toString() : '100';
    _amountController = TextEditingController(text: defaultAmt);

    // Live saved UPI
    final realUpi = bankDetails['upiId'] ?? 
                    profileProvider.profileData['upiId'] ?? 
                    (profileProvider.profileData['phone'] != null && profileProvider.profileData['phone'].toString().isNotEmpty 
                        ? '${profileProvider.profileData['phone']}@upi' 
                        : '');
    _upiController = TextEditingController(text: realUpi.toString());

    // Live saved PayPal
    final realPaypal = bankDetails['paypalId']?.toString().trim() ?? '';
    _paypalController = TextEditingController(text: realPaypal);

    // Initial selected method priority
    if (realUpi.toString().isNotEmpty) {
      _selectedMethod = 'UPI';
    } else if (bankDetails['accountNumber']?.toString().isNotEmpty ?? false) {
      _selectedMethod = 'BANK';
    } else if (realPaypal.isNotEmpty) {
      _selectedMethod = 'PAYPAL';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _paypalController.dispose();
    super.dispose();
  }

  void _syncDestinationWithProvider() {
    final profileProvider = context.read<ProfileProvider>();
    final bankDetails = profileProvider.bankDetails;
    final upi = bankDetails['upiId'] ?? profileProvider.profileData['upiId'] ?? '';
    if (upi.toString().isNotEmpty) {
      _upiController.text = upi.toString();
    }
    final paypal = bankDetails['paypalId'] ?? '';
    if (paypal.toString().isNotEmpty) {
      _paypalController.text = paypal.toString();
    }
    setState(() {});
  }

  void _applyUpiChip(String handle) {
    final current = _upiController.text.trim();
    if (current.isEmpty) {
      _upiController.text = handle;
    } else if (current.contains('@')) {
      final username = current.split('@').first;
      _upiController.text = '$username$handle';
    } else {
      _upiController.text = '$current$handle';
    }
    setState(() {});
  }

  Future<void> _requestPayout() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid withdrawal amount', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final profileProvider = context.read<ProfileProvider>();
    final kycStatus = profileProvider.kycStatus;
    final hasPayoutDetails = profileProvider.hasPayoutDetails;
    final bankDetails = profileProvider.bankDetails;

    if (!hasPayoutDetails && kycStatus != 'VERIFIED' && kycStatus != 'SUBMITTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please link your Bank, UPI, or PayPal details before withdrawing.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Add Details',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
              ).then((_) {
                if (mounted) _syncDestinationWithProvider();
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
          content: Text('Minimum withdrawal amount is ₹${_minLimit.toStringAsFixed(0)}', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entered amount exceeds your available balance', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Determine target payment destination identifier
    String targetDestination = '';
    if (_selectedMethod == 'UPI') {
      targetDestination = _upiController.text.trim();
      if (targetDestination.isEmpty) {
        targetDestination = bankDetails['upiId']?.toString().trim() ?? '';
      }
    } else if (_selectedMethod == 'BANK') {
      final acc = bankDetails['accountNumber']?.toString().trim() ?? '';
      final ifsc = bankDetails['ifscCode']?.toString().trim() ?? '';
      final bName = bankDetails['bankName']?.toString().trim() ?? 'Bank';
      if (acc.isNotEmpty) {
        targetDestination = '$bName:$acc:$ifsc';
      }
    } else if (_selectedMethod == 'PAYPAL') {
      targetDestination = _paypalController.text.trim();
      if (targetDestination.isEmpty) {
        targetDestination = bankDetails['paypalId']?.toString().trim() ?? '';
      }
    }

    if (targetDestination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select or link a valid destination for $_selectedMethod payout', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Link Now',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
              ).then((_) {
                if (mounted) _syncDestinationWithProvider();
              });
            },
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.requestPayout(amount, targetDestination);
    setState(() => _isLoading = false);

    if (mounted) {
      final bool isSuccess = response['error'] == null && (response['success'] == true || response['status'] != null);
      if (isSuccess) {
        context.read<TaskProvider>().fetchWalletData();
        context.read<ProfileProvider>().fetchProfile();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _successGreen, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Payout Requested',
                  style: GoogleFonts.poppins(color: _textNavy, fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            content: Text(
              'Your withdrawal request of ₹${amount.toStringAsFixed(2)} has been submitted successfully to $_selectedMethod ($targetDestination). Funds will be processed shortly.',
              style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bluePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text('Done', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? response['error'] ?? 'Failed to submit withdrawal request',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final bankDetails = profileProvider.bankDetails;
    final bool hasPayoutDetails = profileProvider.hasPayoutDetails;
    final bool isKycVerified = profileProvider.isKycVerified;
    final double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;

    final upi = bankDetails['upiId']?.toString().trim() ?? '';
    final bankName = bankDetails['bankName']?.toString().trim() ?? '';
    final account = bankDetails['accountNumber']?.toString().trim() ?? '';
    final ifsc = bankDetails['ifscCode']?.toString().trim() ?? '';
    final paypal = bankDetails['paypalId']?.toString().trim() ?? '';

    // Dynamic quick chips
    final List<int> quickChips = [];
    if (_minLimit.toInt() > 0) quickChips.add(_minLimit.toInt());
    if (!quickChips.contains(250) && widget.availableBalance >= 250) quickChips.add(250);
    if (!quickChips.contains(500) && widget.availableBalance >= 500) quickChips.add(500);
    if (!quickChips.contains(1000) && widget.availableBalance >= 1000) quickChips.add(1000);
    if (quickChips.isEmpty) quickChips.addAll([100, 200, 500, 1000]);

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: _bgLight,
        colorScheme: const ColorScheme.light(
          primary: _bluePrimary,
          surface: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blueIce,
                border: Border.all(color: _blueBorder),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _blueNavy, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Withdraw Money',
            style: GoogleFonts.poppins(
              color: _textNavy,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Available Balance Gradient Card ───────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_blueNavy, _bluePrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _bluePrimary.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Ready for Direct Settlement',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '₹${widget.availableBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 2. Withdrawal Form Card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: _blueNavy.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Withdrawal Amount',
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Amount Input Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _bluePrimary.withOpacity(0.4), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '₹',
                              style: TextStyle(
                                color: _bluePrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                cursorColor: _bluePrimary,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.poppins(
                                  color: _textNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  hintText: '0',
                                  hintStyle: GoogleFonts.poppins(color: _textHint, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ),
                            // Max Balance Pill Button
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
                                  color: _blueIce,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _blueBorder),
                                ),
                                child: Text(
                                  'Max Balance',
                                  style: GoogleFonts.poppins(
                                    color: _bluePrimary,
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
                                color: isSelected ? _blueIce : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _bluePrimary : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                '₹$amt',
                                style: GoogleFonts.poppins(
                                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── 3. Payout Destination Selector ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choose Payout Method',
                            style: GoogleFonts.poppins(
                              color: _textNavy,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
                              ).then((_) {
                                if (mounted) _syncDestinationWithProvider();
                              });
                            },
                            child: Text(
                              hasPayoutDetails ? 'Edit / Add More' : '+ Add Details',
                              style: GoogleFonts.poppins(
                                color: _bluePrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Method Tabs (UPI, Bank, PayPal)
                      Row(
                        children: [
                          _buildMethodTab(
                            method: 'UPI',
                            label: 'UPI',
                            icon: Icons.bolt_rounded,
                            isLinked: upi.isNotEmpty,
                          ),
                          const SizedBox(width: 8),
                          _buildMethodTab(
                            method: 'BANK',
                            label: 'Bank',
                            icon: Icons.account_balance_rounded,
                            isLinked: account.isNotEmpty,
                          ),
                          const SizedBox(width: 8),
                          _buildMethodTab(
                            method: 'PAYPAL',
                            label: 'PayPal',
                            icon: Icons.public_rounded,
                            isLinked: paypal.isNotEmpty,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Active Selected Method Details Card
                      _buildSelectedMethodCard(
                        selectedMethod: _selectedMethod,
                        upi: upi,
                        bankName: bankName,
                        account: account,
                        ifsc: ifsc,
                        paypal: paypal,
                        isVerified: isKycVerified,
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
                                Text('Requested Amount', style: GoogleFonts.poppins(color: _textSubtle, fontSize: 12)),
                                Text('₹${enteredAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(color: _textNavy, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Processing Fee', style: GoogleFonts.poppins(color: _textSubtle, fontSize: 12)),
                                Text('₹0.00 (Free)',
                                    style: GoogleFonts.poppins(color: _successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Estimated Settlement', style: GoogleFonts.poppins(color: _textSubtle, fontSize: 12)),
                                Text('Instant (< 5 Mins)',
                                    style: GoogleFonts.poppins(color: _bluePrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Net Payout Amount',
                                    style: GoogleFonts.poppins(color: _textNavy, fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('₹${enteredAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(color: _bluePrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payout CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _requestPayout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bluePrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Request Instant Payout',
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildMethodTab({
    required String method,
    required String label,
    required IconData icon,
    required bool isLinked,
  }) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? _blueIce : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _bluePrimary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? _bluePrimary : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: isSelected ? _blueNavy : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isLinked ? 'Linked' : 'Not Added',
                style: GoogleFonts.poppins(
                  color: isLinked ? _successGreen : _textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMethodCard({
    required String selectedMethod,
    required String upi,
    required String bankName,
    required String account,
    required String ifsc,
    required String paypal,
    required bool isVerified,
  }) {
    if (selectedMethod == 'UPI') {
      final bool hasUpi = upi.isNotEmpty;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: hasUpi ? _successBg : _blueIce,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasUpi ? Icons.verified_user_rounded : Icons.qr_code_2_rounded,
                    color: hasUpi ? _successGreen : _bluePrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _upiController,
                    cursorColor: _bluePrimary,
                    style: GoogleFonts.poppins(
                      color: _textNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Enter or confirm UPI ID',
                      hintStyle: GoogleFonts.poppins(color: _textHint, fontSize: 12),
                    ),
                  ),
                ),
                if (hasUpi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Linked',
                      style: GoogleFonts.poppins(color: _successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _upiChips.map((handle) {
                return InkWell(
                  onTap: () => _applyUpiChip(handle),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _blueBorder),
                    ),
                    child: Text(
                      handle,
                      style: GoogleFonts.poppins(color: _blueNavy, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else if (selectedMethod == 'BANK') {
      final bool hasBank = account.isNotEmpty;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: hasBank
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blueIce,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: _bluePrimary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankName.isNotEmpty ? bankName : 'Bank Account',
                          style: GoogleFonts.poppins(color: _textNavy, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${account.length > 4 ? '•••• ${account.substring(account.length - 4)}' : account}${ifsc.isNotEmpty ? ' • IFSC: $ifsc' : ''}',
                          style: GoogleFonts.poppins(color: _textSubtle, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ready',
                      style: GoogleFonts.poppins(color: _successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            : _buildUnlinkedPrompt('Bank Account not added yet. Tap to link your bank account.'),
      );
    } else {
      // PAYPAL METHOD
      final bool hasPaypal = paypal.isNotEmpty;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_paypalBlue, _paypalCyan]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PayPal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _paypalController,
                    cursorColor: _paypalCyan,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(
                      color: _textNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Enter PayPal email / ID',
                      hintStyle: GoogleFonts.poppins(color: _textHint, fontSize: 12),
                    ),
                  ),
                ),
                if (hasPaypal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Active',
                      style: GoogleFonts.poppins(color: _paypalCyan, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF0284C7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Funds converted automatically to USD/local currency upon transfer.',
                    style: GoogleFonts.poppins(color: const Color(0xFF0369A1), fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUnlinkedPrompt(String text) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
        ).then((_) {
          if (mounted) _syncDestinationWithProvider();
        });
      },
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline_rounded, color: _bluePrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: _bluePrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
