import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/profile_provider.dart';

class KycBankDetailsScreen extends StatefulWidget {
  const KycBankDetailsScreen({Key? key}) : super(key: key);

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
        const SnackBar(
          content: Text('Please provide at least one payout method (Bank Account, UPI, or PayPal).'),
          backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('Payout details submitted successfully. Pending Admin verification.'),
            backgroundColor: Colors.green,
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
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout & Bank Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Your Payout Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your preferred method for receiving payments. These details will be verified by the admin.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Bank Transfer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ifscCodeController,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 32),

              const Text(
                'UPI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'PayPal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paypalIdController,
                decoration: const InputDecoration(
                  labelText: 'PayPal Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.paypal),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
