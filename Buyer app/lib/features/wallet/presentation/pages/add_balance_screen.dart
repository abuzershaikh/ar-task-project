import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class CreditPlan {
  final String id;
  final String title;
  final double amount;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color accentColor;
  final bool isPopular;

  const CreditPlan({
    required this.id,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.accentColor,
    this.isPopular = false,
  });
}

class AddBalanceScreen extends StatefulWidget {
  final double? initialAmount;

  const AddBalanceScreen({
    super.key,
    this.initialAmount,
  });

  @override
  State<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceScreenState extends State<AddBalanceScreen> {
  final TextEditingController _amountController = TextEditingController();
  late Razorpay _razorpay;
  double _selectedAmount = 1000;
  String? _selectedPlanId = 'growth';
  bool _isLoading = false;

  final List<CreditPlan> _plans = const [
    CreditPlan(
      id: 'starter',
      title: 'Starter Pack',
      amount: 500,
      subtitle: 'Fast trial • 1-2 small campaigns',
      badge: 'STARTER',
      icon: Icons.rocket_launch_outlined,
      accentColor: Color(0xFF0EA5E9),
    ),
    CreditPlan(
      id: 'growth',
      title: 'Growth Pack',
      amount: 1000,
      subtitle: 'Most popular • 5-10 active campaigns',
      badge: 'MOST POPULAR ⭐',
      icon: Icons.trending_up,
      accentColor: Color(0xFF6366F1),
      isPopular: true,
    ),
    CreditPlan(
      id: 'pro',
      title: 'Pro Pack',
      amount: 2500,
      subtitle: 'For expanding businesses & stores',
      badge: 'RECOMMENDED',
      icon: Icons.workspace_premium_outlined,
      accentColor: Color(0xFF8B5CF6),
    ),
    CreditPlan(
      id: 'scale',
      title: 'Scale Pack',
      amount: 5000,
      subtitle: 'High volume bulk orders & priority queue',
      badge: 'BEST VALUE 🔥',
      icon: Icons.bolt,
      accentColor: Color(0xFFEC4899),
    ),
    CreditPlan(
      id: 'enterprise',
      title: 'Enterprise Pack',
      amount: 10000,
      subtitle: 'Maximum campaign reach & VIP support',
      badge: 'ENTERPRISE',
      icon: Icons.diamond_outlined,
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // If initial amount passed (e.g., from campaign deficit), prefill
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      final amount = widget.initialAmount!;
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
      final matchingPlan = _plans.where((p) => p.amount == amount).toList();
      _selectedPlanId = matchingPlan.isNotEmpty ? matchingPlan.first.id : null;
    } else {
      _amountController.text = '1000';
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _selectPlan(CreditPlan plan) {
    setState(() {
      _selectedPlanId = plan.id;
      _selectedAmount = plan.amount;
      _amountController.text = plan.amount.toStringAsFixed(0);
    });
  }

  void _onCustomAmountChanged(String val) {
    final parsed = double.tryParse(val.trim());
    setState(() {
      if (parsed != null && parsed > 0) {
        _selectedAmount = parsed;
        final matchingPlan = _plans.where((p) => p.amount == parsed).toList();
        _selectedPlanId = matchingPlan.isNotEmpty ? matchingPlan.first.id : null;
      } else {
        _selectedPlanId = null;
      }
    });
  }

  void _addQuickIncrement(double delta) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0;
    final next = (current + delta).clamp(1.0, 500000.0);
    setState(() {
      _selectedAmount = next;
      _amountController.text = next.toStringAsFixed(0);
      final matchingPlan = _plans.where((p) => p.amount == next).toList();
      _selectedPlanId = matchingPlan.isNotEmpty ? matchingPlan.first.id : null;
    });
  }

  Future<void> _startRazorpayPayment() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? _selectedAmount;
    if (amount < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Minimum top-up amount is ₹1.00'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Show non-dismissible loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Generating Razorpay Order...',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ishyan Technologies Secure Checkout',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final dio = getIt<DioClient>();
      final response = await dio.post(
        ApiEndpoints.razorpayOrder,
        data: {
          'amount': amount,
          'description': 'Buyer Wallet Top-up: ₹${amount.toStringAsFixed(0)}',
        },
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Dismiss loading dialog
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final orderId = data['orderId']?.toString();
        final keyId = data['keyId']?.toString() ?? 'rzp_live_TI2wdFKYDJdAxY';
        final companyName = data['companyName']?.toString() ?? 'Ishyan Technologies';
        final amountInPaise = data['amountInPaise'] ?? (amount * 100).toInt();

        if (orderId == null || orderId.isEmpty) {
          throw Exception('Failed to retrieve Razorpay Order ID from server');
        }

        final options = {
          'key': keyId,
          'amount': amountInPaise,
          'name': companyName,
          'order_id': orderId,
          'description': 'Wallet Top-up • ₹${amount.toStringAsFixed(0)} Credits',
          'theme': {
            'color': '#4F46E5',
          },
          'send_sms_hash': true,
          'external': {
            'wallets': ['paytm']
          }
        };

        _razorpay.open(options);
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to initialize payment');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    // Show verification dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    'Verifying Payment Signature...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Crediting wallet balance atomically...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final dio = getIt<DioClient>();
      final verifyRes = await dio.post(
        ApiEndpoints.razorpayVerify,
        data: {
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'amount': _selectedAmount,
        },
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Dismiss verifying dialog
      }

      final isSuccess = (verifyRes.statusCode == 200 || verifyRes.statusCode == 201) &&
          verifyRes.data != null &&
          verifyRes.data['success'] == true;

      if (isSuccess) {
        // Refresh wallet state in app
        if (mounted) {
          context.read<WalletBloc>().add(const RefreshWalletEvent());
        }

        // Show Success Celebration Dialog
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Top-up Successful!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_selectedAmount.toStringAsFixed(2)} has been credited to your wallet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment ID:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          paymentId ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done & Back to Wallet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        throw Exception(verifyRes.data?['message'] ?? 'Payment verification failed on server');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Verification error: $e. Please contact support with Payment ID: $paymentId'),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCancelled
                ? 'Payment was cancelled'
                : 'Payment failed: ${response.message ?? "Transaction declined"}',
          ),
          backgroundColor: isCancelled ? Colors.grey.shade800 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redirected to external wallet: ${response.walletName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Top Up Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Header Card
            _buildBalanceHeader(),
            const SizedBox(height: 24),

            // Credit Plans Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose a Credit Plan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, size: 14, color: Color(0xFF4F46E5)),
                      SizedBox(width: 4),
                      Text(
                        'Instant Credit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of curated Plans
            ..._plans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 24),

            // Custom Amount Input Section
            const Text(
              'Or Enter Custom Amount',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            _buildCustomAmountInput(),
            const SizedBox(height: 10),

            // Quick Add Chips
            Wrap(
              spacing: 8,
              children: [
                _buildQuickChip('+₹100', 100),
                _buildQuickChip('+₹500', 500),
                _buildQuickChip('+₹1,000', 1000),
                _buildQuickChip('+₹2,500', 2500),
              ],
            ),
            const SizedBox(height: 28),

            // Razorpay & Ishyan Technologies Trust Banner
            _buildTrustBadge(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomPayBar(),
    );
  }

  Widget _buildBalanceHeader() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        double currentBal = 0.0;
        if (state is WalletLoaded) {
          currentBal = state.balance.availableBalance;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CURRENT AVAILABLE BALANCE',
                    style: TextStyle(
                      color: Color(0xFFC7D2FE),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Verified Wallet',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${currentBal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Usable across YouTube, Google Maps & Play Store campaigns',
                style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(CreditPlan plan) {
    final isSelected = _selectedPlanId == plan.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectPlan(plan),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? plan.accentColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: plan.accentColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: plan.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(plan.icon, color: plan.accentColor, size: 24),
              ),
              const SizedBox(width: 14),

              // Title & details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (plan.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              plan.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: plan.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Amount & radio
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${plan.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? plan.accentColor : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? plan.accentColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? plan.accentColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedPlanId == null ? const Color(0xFF4F46E5) : Colors.grey.shade200,
          width: _selectedPlanId == null ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text(
            '₹',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Enter custom amount (e.g. 750)',
                hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: _onCustomAmountChanged,
            ),
          ),
          if (_amountController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
              onPressed: () {
                _amountController.clear();
                setState(() {
                  _selectedAmount = 0;
                  _selectedPlanId = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double addAmount) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4F46E5),
        ),
      ),
      backgroundColor: const Color(0xFFEEF2FF),
      side: BorderSide(color: const Color(0xFFC7D2FE).withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _addQuickIncrement(addAmount),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2340),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Razorpay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ishyan Technologies Official Gateway',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Supported payment methods:\n• UPI: Google Pay, PhonePe, Paytm, BHIM, Cred\n• Cards: Credit & Debit (Visa, Mastercard, RuPay)\n• Net Banking: All 50+ Indian Banks supported\n• 100% Secure 256-Bit SSL Encryption',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPayBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable Amount:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                Text(
                  '₹${_selectedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startRazorpayPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ₹${_selectedAmount.toStringAsFixed(0)} via Razorpay',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
