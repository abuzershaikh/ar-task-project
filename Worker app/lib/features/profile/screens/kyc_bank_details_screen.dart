import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/profile_provider.dart';

/// KycBankDetailsScreen:
/// - Premium White & Blue Fin-tech UI
/// - Real live saved details banner ("Add hua ya nahi" status indicator)
/// - Masked display of existing Bank, UPI, and PayPal details
/// - Form pre-fills automatically from live server profile
/// - Dedicated styled PayPal section with validation
/// - UPI fast-fill provider chips
class KycBankDetailsScreen extends StatefulWidget {
  const KycBankDetailsScreen({super.key});

  @override
  State<KycBankDetailsScreen> createState() => _KycBankDetailsScreenState();
}

class _KycBankDetailsScreenState extends State<KycBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _paypalIdController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingInitial = false;
  bool _obscureAccount = true;

  // ── Premium White & Blue Palette Tokens ─────────────────────────────────────
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _bluePrimary = Color(0xFF2563EB); // Royal Blue
  static const Color _blueNavy = Color(0xFF1E3A8A); // Deep Sapphire
  static const Color _blueIce = Color(0xFFEFF6FF); // Soft Blue Tint
  static const Color _blueBorder = Color(0xFFDBEAFE); // Ice Blue Border
  static const Color _textNavy = Color(0xFF0F172A); // High-contrast slate navy
  static const Color _textSubtle = Color(0xFF64748B); // Muted Slate
  static const Color _textHint = Color(0xFF94A3B8);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _successBg = Color(0xFFDCFCE7);
  static const Color _warningAmber = Color(0xFFD97706);
  static const Color _warningBg = Color(0xFFFEF3C7);
  static const Color _paypalBlue = Color(0xFF003087);
  static const Color _paypalCyan = Color(0xFF0079C1);

  final List<String> _upiChips = [
    '@okhdfcbank',
    '@oksbi',
    '@paytm',
    '@ybl',
    '@axl',
    '@ibl',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    _paypalIdController.dispose();
    super.dispose();
  }

  void _loadSavedDetails() {
    final profileProvider = context.read<ProfileProvider>();
    final profile = profileProvider.profileData;
    final bankDetails = profileProvider.bankDetails;

    final existingName = bankDetails['fullName'] ?? profile['fullName'] ?? '';
    final existingBank = bankDetails['bankName'] ?? '';
    final existingAcc = bankDetails['accountNumber'] ?? '';
    final existingIfsc = bankDetails['ifscCode'] ?? '';
    final existingUpi = bankDetails['upiId'] ?? profile['upiId'] ?? '';
    final existingPaypal = bankDetails['paypalId'] ?? '';

    _fullNameController.text = existingName.toString();
    _bankNameController.text = existingBank.toString();
    _accountNumberController.text = existingAcc.toString();
    _confirmAccountNumberController.text = existingAcc.toString();
    _ifscCodeController.text = existingIfsc.toString();
    _upiIdController.text = existingUpi.toString();
    _paypalIdController.text = existingPaypal.toString();
  }

  Future<void> _refreshFromLiveApi() async {
    setState(() => _isFetchingInitial = true);
    try {
      await context.read<ProfileProvider>().fetchProfile();
      _loadSavedDetails();
    } catch (_) {}
    if (mounted) setState(() => _isFetchingInitial = false);
  }

  void _applyUpiChip(String handle) {
    final current = _upiIdController.text.trim();
    if (current.isEmpty) {
      _upiIdController.text = handle;
    } else if (current.contains('@')) {
      final username = current.split('@').first;
      _upiIdController.text = '$username$handle';
    } else {
      _upiIdController.text = '$current$handle';
    }
    setState(() {});
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final upi = _upiIdController.text.trim();
    final acc = _accountNumberController.text.trim();
    final paypal = _paypalIdController.text.trim();

    if (upi.isEmpty && acc.isEmpty && paypal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill at least one payout method (UPI, Bank Account, or PayPal).',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (acc.isNotEmpty && _confirmAccountNumberController.text.trim() != acc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bank Account Number and Confirm Account Number do not match.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'fullName': _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : (context.read<ProfileProvider>().profileData['fullName'] ??
                  'Worker'),
        if (_bankNameController.text.trim().isNotEmpty)
          'bankName': _bankNameController.text.trim(),
        if (acc.isNotEmpty) 'accountNumber': acc,
        if (_ifscCodeController.text.trim().isNotEmpty)
          'ifscCode': _ifscCodeController.text.trim().toUpperCase(),
        if (upi.isNotEmpty) 'upiId': upi,
        if (paypal.isNotEmpty) 'paypalId': paypal,
      };

      final response = await ApiService.submitKycBankDetails(payload);

      if (response['success'] == true) {
        await context.read<ProfileProvider>().fetchProfile();
        _loadSavedDetails();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payout details saved successfully! Payout method is now active.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to save payout details');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final kycStatus = profileProvider.kycStatus;
    final bankDetails = profileProvider.bankDetails;
    final bool hasDetails = profileProvider.hasPayoutDetails;

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: _bgLight,
        colorScheme: const ColorScheme.light(
          primary: _bluePrimary,
          surface: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF8FAFC),
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
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _blueNavy,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Payout & Bank Details',
            style: GoogleFonts.poppins(
              color: _textNavy,
              fontWeight: FontWeight.w700,
              fontSize: 17.5,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: _isFetchingInitial
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _bluePrimary,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: _bluePrimary,
                      size: 22,
                    ),
              onPressed: _isFetchingInitial ? null : _refreshFromLiveApi,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. "Add Hua Ya Nahi" Status & Saved Summary Card ────────────
                  _buildLiveStatusCard(hasDetails, kycStatus, bankDetails),
                  const SizedBox(height: 20),

                  // ── 2. Section Header: Payout Methods Form ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hasDetails
                            ? 'Update Payout Details'
                            : 'Add Payout Details',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _textNavy,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _blueIce,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _blueBorder),
                        ),
                        child: Text(
                          '100% Encrypted',
                          style: GoogleFonts.poppins(
                            color: _bluePrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Full Name Box ───────────────────────────────────────────────
                  _buildWhiteCard(
                    title: 'Account Holder Full Name',
                    icon: Icons.person_outline_rounded,
                    iconColor: _bluePrimary,
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Full name as per Bank / ID document',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Section 1: UPI ID Box ───────────────────────────────────────
                  _buildWhiteCard(
                    title: 'UPI Transfer (Instant • Fastest)',
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    trailingBadge: 'Zero Fees',
                    badgeColor: const Color(0xFFFEF3C7),
                    badgeTextColor: const Color(0xFFD97706),
                    children: [
                      TextFormField(
                        controller: _upiIdController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: 'username@okhdfcbank / mobile@upi',
                          icon: Icons.qr_code_2_rounded,
                          suffixIcon: _upiIdController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: _textSubtle,
                                  ),
                                  onPressed: () {
                                    _upiIdController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Quick Add Provider Handle:',
                        style: GoogleFonts.poppins(
                          color: _textSubtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _upiChips.map((handle) {
                          return InkWell(
                            onTap: () => _applyUpiChip(handle),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _blueIce,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _blueBorder),
                              ),
                              child: Text(
                                handle,
                                style: GoogleFonts.poppins(
                                  color: _blueNavy,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Section 2: Direct Bank Transfer Box ────────────────────────
                  _buildWhiteCard(
                    title: 'Direct Bank Account Transfer',
                    icon: Icons.account_balance_rounded,
                    iconColor: _bluePrimary,
                    children: [
                      TextFormField(
                        controller: _bankNameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Bank Name (e.g. HDFC Bank, SBI, ICICI)',
                          icon: Icons.business_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        obscureText: _obscureAccount,
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Account Number',
                          icon: Icons.numbers_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureAccount
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 19,
                              color: _textSubtle,
                            ),
                            onPressed: () => setState(
                              () => _obscureAccount = !_obscureAccount,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmAccountNumberController,
                        keyboardType: TextInputType.number,
                        obscureText: _obscureAccount,
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Confirm Account Number',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ifscCodeController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                        ],
                        style: GoogleFonts.poppins(
                          color: _textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        decoration: _inputDecoration(
                          hint: 'IFSC Code (e.g. HDFC0001234)',
                          icon: Icons.pin_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Section 3: Premium PayPal International Box ────────────────
                  _buildPayPalCard(),
                  const SizedBox(height: 24),

                  // ── Submit / Save CTA ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_blueNavy, _bluePrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _bluePrimary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasDetails
                                      ? 'Update Payout Details'
                                      : 'Save & Link Payout Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Direct payouts are processed to your active verified method.',
                      style: GoogleFonts.poppins(
                        color: _textSubtle,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Live Status Card ("Add Hua Ya Nahi") ─────────────────────────────────────
  Widget _buildLiveStatusCard(
    bool hasDetails,
    String kycStatus,
    Map<String, dynamic> bankDetails,
  ) {
    final bool isVerified = kycStatus == 'VERIFIED';
    final bool isSubmitted =
        kycStatus == 'SUBMITTED' || kycStatus == 'UNDER_REVIEW';

    Color badgeBg;
    Color badgeText;
    String statusTitle;
    IconData statusIcon;

    if (isVerified) {
      badgeBg = _successBg;
      badgeText = _successGreen;
      statusTitle = 'Payout Profile Verified & Active';
      statusIcon = Icons.verified_rounded;
    } else if (hasDetails || isSubmitted) {
      badgeBg = _warningBg;
      badgeText = _warningAmber;
      statusTitle = 'Details Added & Active (Under Review)';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = const Color(0xFF64748B);
      statusTitle = 'No Payout Method Linked Yet';
      statusIcon = Icons.info_outline_rounded;
    }

    final upi = bankDetails['upiId']?.toString().trim() ?? '';
    final bankName = bankDetails['bankName']?.toString().trim() ?? '';
    final account = bankDetails['accountNumber']?.toString().trim() ?? '';
    final ifsc = bankDetails['ifscCode']?.toString().trim() ?? '';
    final paypal = bankDetails['paypalId']?.toString().trim() ?? '';

    // Helper to mask account number (show last 4 digits)
    String maskedAccount(String acc) {
      if (acc.length <= 4) return acc;
      return '•••• •••• ${acc.substring(acc.length - 4)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasDetails ? _blueBorder : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _blueNavy.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeBg,
                ),
                child: Icon(statusIcon, color: badgeText, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.poppins(
                        color: _textNavy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDetails
                          ? 'Withdrawals will be sent to your linked destination below.'
                          : 'Enter your Bank, UPI, or PayPal details to enable payouts.',
                      style: GoogleFonts.poppins(
                        color: _textSubtle,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasDetails
                      ? (isVerified ? 'VERIFIED' : 'ADDED')
                      : 'NOT ADDED',
                  style: GoogleFonts.poppins(
                    color: badgeText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // Detail Tiles if details exist
          if (hasDetails) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Text(
              'Active Linked Payout Destinations:',
              style: GoogleFonts.poppins(
                color: _textSubtle,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // UPI Display Tile
            if (upi.isNotEmpty)
              _buildSavedItemTile(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'UPI ID',
                value: upi,
                badge: 'Fastest',
                canCopy: true,
              ),

            // Bank Display Tile
            if (account.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSavedItemTile(
                icon: Icons.account_balance_rounded,
                iconColor: _bluePrimary,
                title: bankName.isNotEmpty ? bankName : 'Bank Account',
                value: '${maskedAccount(account)} • IFSC: $ifsc',
                badge: 'Direct',
              ),
            ],

            // PayPal Display Tile
            if (paypal.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSavedItemTile(
                icon: Icons.public_rounded,
                iconColor: _paypalCyan,
                title: 'PayPal Account',
                value: paypal,
                badge: 'USD / Global',
                canCopy: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSavedItemTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String badge,
    bool canCopy = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _blueIce,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blueBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: _textSubtle,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: _blueNavy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _blueBorder),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(
                color: _bluePrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Copied $value to clipboard',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Icon(
                Icons.copy_rounded,
                size: 15,
                color: _bluePrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── White Card Container ─────────────────────────────────────────────────────
  Widget _buildWhiteCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? trailingBadge,
    Color? badgeColor,
    Color? badgeTextColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: _textNavy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? _blueIce,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailingBadge,
                    style: GoogleFonts.poppins(
                      color: badgeTextColor ?? _bluePrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Dedicated PayPal International Card ───────────────────────────────────────
  Widget _buildPayPalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _paypalBlue.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // PayPal Icon Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_paypalBlue, _paypalCyan],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PayPal',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PayPal (International / USD)',
                  style: GoogleFonts.poppins(
                    color: _textNavy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Global',
                  style: GoogleFonts.poppins(
                    color: _paypalCyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paypalIdController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(
              color: _textNavy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. yourname@gmail.com or paypal.me/username',
              hintStyle: GoogleFonts.poppins(color: _textHint, fontSize: 12.5),
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                size: 19,
                color: _paypalCyan,
              ),
              filled: true,
              fillColor: const Color(0xFFF0F9FF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBAE6FD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBAE6FD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _paypalCyan, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: _paypalCyan,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Payouts to PayPal are converted directly to your local currency or USD.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0369A1),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Input Decoration ────────────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: _textHint, fontSize: 13),
      prefixIcon: Icon(icon, size: 19, color: _bluePrimary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _bluePrimary, width: 1.8),
      ),
    );
  }
}
