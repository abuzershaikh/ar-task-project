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
  double _selectedAmount = 500;
  bool _isLoading = false;

  final List<double> _quickAmounts = const [100, 200, 500, 1000, 2000, 5000];

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
    } else {
      _selectedAmount = 500;
      _amountController.text = '500';
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final parsed = double.tryParse(val.trim());
    setState(() {
      _selectedAmount = (parsed != null && parsed > 0) ? parsed : 0;
    });
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _addIncrement(double delta) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0;
    final next = (current + delta).clamp(1.0, 500000.0);
    setState(() {
      _selectedAmount = next;
      _amountController.text = next.toStringAsFixed(0);
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
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  SizedBox(height: 20),
                  Text(
                    'Opening Secure Checkout...',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Connecting to payment gateway',
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
          'description': 'Wallet Top-up: ₹${amount.toStringAsFixed(0)}',
        },
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Dismiss loading dialog
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final orderId = data['orderId']?.toString();
        final keyId = data['keyId']?.toString() ?? 'rzp_live_TI2wdFKYDJdAxY';
        final merchantName = data['companyName']?.toString() ?? 'Marketing Pro';
        final amountInPaise = data['amountInPaise'] ?? (amount * 100).toInt();

        if (orderId == null || orderId.isEmpty) {
          throw Exception('Failed to retrieve Order ID from server');
        }

        final options = {
          'key': keyId,
          'amount': amountInPaise,
          'name': merchantName,
          'order_id': orderId,
          'description': 'Wallet Top-up • ₹${amount.toStringAsFixed(0)}',
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
                    'Verifying Payment...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Updating your wallet balance...',
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
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 48,
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
                    '₹${_selectedAmount.toStringAsFixed(2)} added to your wallet.',
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
            content: Text('⚠️ Verification error: $e. Transaction Reference: $paymentId'),
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
                ? 'Payment cancelled'
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
          'Add Balance',
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

            // Enter Amount Section Header
            const Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter any custom amount you want to add to your wallet',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Custom Amount Input
            _buildCustomAmountInput(),
            const SizedBox(height: 20),

            // Quick Select Amounts Header
            const Text(
              'Quick Select',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),

            // Grid of Quick Amount Buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amt) {
                final isSelected = _selectedAmount == amt;
                return InkWell(
                  onTap: () => _selectQuickAmount(amt),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '₹${amt.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Add Quick Increment Chips (+100, +500)
            Wrap(
              spacing: 8,
              children: [
                _buildIncrementChip('+₹100', 100),
                _buildIncrementChip('+₹500', 500),
                _buildIncrementChip('+₹1,000', 1000),
                _buildIncrementChip('+₹2,000', 2000),
              ],
            ),
            const SizedBox(height: 16),
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
                color: const Color(0xFF4338CA).withOpacity(0.25),
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
                        Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Active Wallet',
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
                'Available instantly to launch new campaigns',
                style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4F46E5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Text(
            '₹',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCBD5E1),
                ),
                border: InputBorder.none,
              ),
              onChanged: _onAmountChanged,
            ),
          ),
          if (_amountController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, size: 22, color: Color(0xFF94A3B8)),
              onPressed: () {
                _amountController.clear();
                setState(() {
                  _selectedAmount = 0;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIncrementChip(String label, double addAmount) {
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
      onPressed: () => _addIncrement(addAmount),
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
                  'Amount to Add:',
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
                          const Icon(Icons.shield_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Proceed to Pay ₹${_selectedAmount.toStringAsFixed(0)}',
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
