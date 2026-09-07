import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/profile_provider.dart';

class KycBankDetailsScreen extends StatefulWidget {
  const KycBankDetailsScreen({super.key});

  @override
  State<KycBankDetailsScreen> createState() => _KycBankDetailsScreenState();
}

class _KycBankDetailsScreenState extends State<KycBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _paypalIdController = TextEditingController();

  bool _isLoading = false;

  // ── Palette Tokens ────────────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF04140F);
  static const Color _cardDark = Color(0xFF09291E);
  static const Color _cardBorder = Color(0xFF10B981);
  static const Color _goldPrimary = Color(0xFFF59E0B);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const Color _emeraldBright = Color(0xFF10B981);
  static const Color _emeraldLight = Color(0xFF34D399);
  static const Color _textWhite = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    _paypalIdController.dispose();
    super.dispose();
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;

    if (_accountNumberController.text.isEmpty &&
        _upiIdController.text.isEmpty &&
        _paypalIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide at least one payout method (Bank Account, UPI, or PayPal).',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'fullName': context.read<ProfileProvider>().profileData['fullName'] ?? 'Worker',
        if (_bankNameController.text.isNotEmpty) 'bankName': _bankNameController.text.trim(),
        if (_accountNumberController.text.isNotEmpty) 'accountNumber': _accountNumberController.text.trim(),
        if (_ifscCodeController.text.isNotEmpty) 'ifscCode': _ifscCodeController.text.trim(),
        if (_upiIdController.text.isNotEmpty) 'upiId': _upiIdController.text.trim(),
        if (_paypalIdController.text.isNotEmpty) 'paypalId': _paypalIdController.text.trim(),
      };

      final response = await ApiService.submitKycBankDetails(payload);

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payout details submitted successfully. Pending Admin verification.',
              style: GoogleFonts.poppins(color: _bgDark, fontWeight: FontWeight.w600),
            ),
            backgroundColor: _emeraldBright,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await context.read<ProfileProvider>().fetchProfile();
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        throw Exception(response['message'] ?? 'Failed to submit details');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cardDark,
              border: Border.all(color: _cardBorder.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _textWhite, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Payout & Bank Details',
          style: GoogleFonts.poppins(
            color: _textWhite,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04140F),
              Color(0xFF07241A),
              Color(0xFF03160F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Info Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF083827), Color(0xFF042116)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cardBorder.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: _emeraldBright.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _emeraldBright.withValues(alpha: 0.15),
                            border: Border.all(color: _emeraldBright.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.shield_rounded, color: _emeraldBright, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instant Worker Settlements',
                                style: GoogleFonts.poppins(
                                  color: _goldLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Provide Bank Account, UPI ID or PayPal to receive direct withdrawals.',
                                style: GoogleFonts.poppins(
                                  color: _textMuted,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section 1: UPI ID (Preferred) ───────────────────────────
                  _buildSectionHeader('UPI Transfer (Fastest)', Icons.bolt_rounded, _goldPrimary),
                  const SizedBox(height: 10),
                  _buildCard(
                    children: [
                      TextFormField(
                        controller: _upiIdController,
                        style: GoogleFonts.poppins(color: _textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: 'yourname@okhdfcbank / yourname@upi',
                          icon: Icons.qr_code_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Section 2: Bank Account Transfer ────────────────────────
                  _buildSectionHeader('Direct Bank Transfer', Icons.account_balance_rounded, _emeraldLight),
                  const SizedBox(height: 10),
                  _buildCard(
                    children: [
                      TextFormField(
                        controller: _bankNameController,
                        style: GoogleFonts.poppins(color: _textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: 'Bank Name (e.g. HDFC Bank, SBI)',
                          icon: Icons.business_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(color: _textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: 'Account Number',
                          icon: Icons.numbers_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ifscCodeController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.poppins(color: _textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: 'IFSC Code (e.g. HDFC0001234)',
                          icon: Icons.tag_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Section 3: PayPal Email ─────────────────────────────────
                  _buildSectionHeader('PayPal (International)', Icons.public_rounded, const Color(0xFF60A5FA)),
                  const SizedBox(height: 10),
                  _buildCard(
                    children: [
                      TextFormField(
                        controller: _paypalIdController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(color: _textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          hint: 'PayPal Email Address',
                          icon: Icons.email_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Submit CTA ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_emeraldBright, Color(0xFF059669)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _emeraldBright.withValues(alpha: 0.35),
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
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Payout Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: _goldLight,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: _textMuted.withValues(alpha: 0.6), fontSize: 13),
      prefixIcon: Icon(icon, size: 19, color: _emeraldLight),
      filled: true,
      fillColor: const Color(0xFF0C3829),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _cardBorder.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _cardBorder.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _emeraldBright, width: 1.5),
      ),
    );
  }
}
