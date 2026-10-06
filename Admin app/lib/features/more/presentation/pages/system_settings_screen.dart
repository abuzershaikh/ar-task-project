import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../service_builder/presentation/pages/app_update_management_screen.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _maintenanceMode = false;
  double _platformMargin = 20.0;
  double _minWithdrawalAmount = 100.0;

  // Global Currency (INR / USD) & Dynamic Pricing Switch Engine
  String _globalDefaultCurrency = 'INR';
  final TextEditingController _usdExchangeRateController = TextEditingController(text: '85.00');
  bool _allowBuyerSwitch = true;

  // App Install & Play Store Retention Engine Settings
  double _appInstallRetentionHours = 24.0;
  bool _allowNegativeBalance = true;
  bool _strictEarlyUninstallPenalty = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _usdExchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get('/admin/settings');
      final data = resp.data ?? {};

      double? parsedMin;
      if (data['minWithdrawalAmount'] != null) {
        parsedMin = double.tryParse(data['minWithdrawalAmount'].toString());
      } else if (data['minWithdrawalLimit'] != null) {
        parsedMin = double.tryParse(data['minWithdrawalLimit'].toString());
      } else if (data['minimum_withdrawal'] != null) {
        parsedMin = double.tryParse(data['minimum_withdrawal'].toString());
      } else if (data['settings'] is List) {
        for (final item in data['settings']) {
          if (item is Map && item['key'] == 'minimum_withdrawal') {
            parsedMin = double.tryParse(item['value']?.toString() ?? '');
            break;
          }
        }
      }

      // Also verify directly against /admin/payouts/config
      try {
        final payoutResp = await dio.get('/admin/payouts/config');
        if (payoutResp.data != null && payoutResp.data['minWithdrawalLimit'] != null) {
          final pMin = double.tryParse(payoutResp.data['minWithdrawalLimit'].toString());
          if (pMin != null) {
            parsedMin = pMin;
          }
        }
      } catch (_) {}

      setState(() {
        _maintenanceMode = data['maintenanceMode'] ?? false;
        _platformMargin = double.tryParse(data['platformMargin']?.toString() ?? '20.0') ?? 20.0;
        if (parsedMin != null) {
          _minWithdrawalAmount = parsedMin;
        }
      });

      try {
        final retentionResp = await dio.get('/admin/settings/app-retention');
        final rData = retentionResp.data?['settings'] ?? retentionResp.data ?? {};
        if (rData['minRetentionHours'] != null) {
          _appInstallRetentionHours = double.tryParse(rData['minRetentionHours'].toString()) ?? 24.0;
        }
        if (rData['allowNegativeBalance'] != null) {
          _allowNegativeBalance = rData['allowNegativeBalance'] == true;
        }
        if (rData['strictPenalty'] != null) {
          _strictEarlyUninstallPenalty = rData['strictPenalty'] == true;
        }
      } catch (_) {}

      // Fetch Global Currency Engine Settings from Live VPS Backend
      try {
        final currResp = await http.get(Uri.parse('https://reviewsgateway.in/support-chat/api/support/currency-settings')).timeout(const Duration(seconds: 8));
        if (currResp.statusCode == 200) {
          final cData = jsonDecode(currResp.body);
          if (cData is Map && cData['success'] == true) {
            final serverDef = (cData['defaultCurrency']?.toString().toUpperCase() == 'USD') ? 'USD' : 'INR';
            final serverRate = double.tryParse(cData['usdExchangeRate']?.toString() ?? '85.0') ?? 85.0;
            final allowSwitch = cData['allowBuyerSwitch'] == true || cData['allowBuyerSwitch'] == null;
            if (mounted) {
              setState(() {
                _globalDefaultCurrency = serverDef;
                _usdExchangeRateController.text = serverRate.toStringAsFixed(2);
                _allowBuyerSwitch = allowSwitch;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[Admin Settings] Currency fetch warning: $e');
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final dio = getIt<DioClient>();

      // 1. Update general system settings (minimum withdrawal, maintenance mode, platform margin)
      await dio.post('/admin/settings', data: {
        'maintenanceMode': _maintenanceMode,
        'platformMargin': _platformMargin,
        'minWithdrawalAmount': _minWithdrawalAmount,
        'minWithdrawalLimit': _minWithdrawalAmount,
      });

      // 2. Direct payout threshold endpoint update
      try {
        await dio.post('/admin/payouts/config', data: {
          'minWithdrawalLimit': _minWithdrawalAmount,
        });
      } catch (e) {
        debugPrint('[Admin Settings] Direct payout config notice: $e');
      }

      // 3. Direct setting key patch
      try {
        await dio.patch('/admin/settings/minimum_withdrawal', data: {
          'value': _minWithdrawalAmount,
        });
      } catch (e) {
        debugPrint('[Admin Settings] Setting patch notice: $e');
      }

      // 4. Update retention settings
      await dio.post('/admin/settings/app-retention', data: {
        'minRetentionHours': _appInstallRetentionHours,
        'allowNegativeBalance': _allowNegativeBalance,
        'strictPenalty': _strictEarlyUninstallPenalty,
      });

      // 5. Save Global Currency & USD Exchange Rate to Live VPS Backend
      try {
        final rate = double.tryParse(_usdExchangeRateController.text.trim()) ?? 85.0;
        await http.post(
          Uri.parse('https://reviewsgateway.in/support-chat/api/support/admin/currency-settings'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'defaultCurrency': _globalDefaultCurrency,
            'usdExchangeRate': rate,
            'allowBuyerSwitch': _allowBuyerSwitch,
          }),
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('[Admin Settings] Currency save warning: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('All settings saved to server! Worker min withdrawal: ₹${_minWithdrawalAmount.toStringAsFixed(0)}'),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to save settings: $err'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.system_update_rounded, color: Color(0xFF818CF8), size: 28),
                      ),
                      title: const Text(
                        'App Version & Updates',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: const Text(
                        'Manage version codes, disable versions & setup redirect links',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppUpdateManagementScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Global Currency & Pricing Control (INR & USD Single Switch) ──
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.4), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.currency_exchange_rounded, color: Color(0xFF6366F1), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Global Currency & Pricing Switch',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Single switch to toggle all service pricing between INR & USD',
                                      style: TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Active Global Currency Selector Pill
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Default Platform Currency (All Buyers)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Switching this sets the default currency for all buyers across all services simultaneously.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _globalDefaultCurrency = 'INR'),
                                        borderRadius: BorderRadius.circular(10),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _globalDefaultCurrency == 'INR' ? const Color(0xFF4F46E5) : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _globalDefaultCurrency == 'INR' ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '₹',
                                                style: TextStyle(
                                                  color: _globalDefaultCurrency == 'INR' ? Colors.white : const Color(0xFF475569),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'INR (Rupee)',
                                                style: TextStyle(
                                                  color: _globalDefaultCurrency == 'INR' ? Colors.white : const Color(0xFF475569),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _globalDefaultCurrency = 'USD'),
                                        borderRadius: BorderRadius.circular(10),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _globalDefaultCurrency == 'USD' ? const Color(0xFF0284C7) : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _globalDefaultCurrency == 'USD' ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '\$',
                                                style: TextStyle(
                                                  color: _globalDefaultCurrency == 'USD' ? Colors.white : const Color(0xFF475569),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'USD (Dollar)',
                                                style: TextStyle(
                                                  color: _globalDefaultCurrency == 'USD' ? Colors.white : const Color(0xFF475569),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // USD Exchange Rate Input Field
                          TextFormField(
                            controller: _usdExchangeRateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'USD Exchange Rate (1 USD = ₹ INR)',
                              helperText: 'e.g. 85.00 (calculates prices in USD: INR / 85.00)',
                              prefixIcon: const Icon(Icons.attach_money_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Allow Buyer App Currency Switch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text(
                              'If enabled, individual buyers can toggle INR/USD on their personal device (rate-limited to 1 request/min).',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _allowBuyerSwitch,
                            activeColor: const Color(0xFF6366F1),
                            onChanged: (val) => setState(() => _allowBuyerSwitch = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Temporarily pause task submission engine for system maintenance'),
                      value: _maintenanceMode,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _maintenanceMode = val),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Platform Financial Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('Platform Commission Margin: ${_platformMargin.toStringAsFixed(1)}%'),
                          Slider(
                            value: _platformMargin,
                            min: 5.0,
                            max: 50.0,
                            divisions: 45,
                            activeColor: AppColors.primary,
                            label: '${_platformMargin.toStringAsFixed(1)}%',
                            onChanged: (val) => setState(() => _platformMargin = val),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Minimum Worker Withdrawal:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹${_minWithdrawalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _minWithdrawalAmount.clamp(10.0, 1000.0),
                            min: 10.0,
                            max: 1000.0,
                            divisions: 99,
                            activeColor: AppColors.primary,
                            label: '₹${_minWithdrawalAmount.toStringAsFixed(0)}',
                            onChanged: (val) => setState(() => _minWithdrawalAmount = val),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('₹10'),
                                selected: _minWithdrawalAmount == 10.0,
                                onSelected: (_) => setState(() => _minWithdrawalAmount = 10.0),
                              ),
                              ChoiceChip(
                                label: const Text('₹25'),
                                selected: _minWithdrawalAmount == 25.0,
                                onSelected: (_) => setState(() => _minWithdrawalAmount = 25.0),
                              ),
                              ChoiceChip(
                                label: const Text('₹50'),
                                selected: _minWithdrawalAmount == 50.0,
                                onSelected: (_) => setState(() => _minWithdrawalAmount = 50.0),
                              ),
                              ChoiceChip(
                                label: const Text('₹100'),
                                selected: _minWithdrawalAmount == 100.0,
                                onSelected: (_) => setState(() => _minWithdrawalAmount = 100.0),
                              ),
                              ChoiceChip(
                                label: const Text('₹200'),
                                selected: _minWithdrawalAmount == 200.0,
                                onSelected: (_) => setState(() => _minWithdrawalAmount = 200.0),
                              ),
                              ChoiceChip(
                                label: const Text('₹500'),
                                selected: _minWithdrawalAmount == 500.0,
                                onSelected: (_) => setState(() => _minWithdrawalAmount = 500.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Install & Play Store Retention Engine
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.install_mobile_rounded, color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Play Store & App Install Retention',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Control how long workers must keep target apps installed on their devices. Worker app crons verify installation periodically.',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Minimum Retention Duration:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_appInstallRetentionHours.toStringAsFixed(0)} Hours (${(_appInstallRetentionHours / 24).toStringAsFixed(1)} Days)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _appInstallRetentionHours,
                            min: 1.0,
                            max: 168.0,
                            divisions: 167,
                            activeColor: AppColors.primary,
                            label: '${_appInstallRetentionHours.toStringAsFixed(0)}h',
                            onChanged: (val) => setState(() => _appInstallRetentionHours = val),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('12h'),
                                selected: _appInstallRetentionHours == 12.0,
                                onSelected: (_) => setState(() => _appInstallRetentionHours = 12.0),
                              ),
                              ChoiceChip(
                                label: const Text('24h (1 Day)'),
                                selected: _appInstallRetentionHours == 24.0,
                                onSelected: (_) => setState(() => _appInstallRetentionHours = 24.0),
                              ),
                              ChoiceChip(
                                label: const Text('48h (2 Days)'),
                                selected: _appInstallRetentionHours == 48.0,
                                onSelected: (_) => setState(() => _appInstallRetentionHours = 48.0),
                              ),
                              ChoiceChip(
                                label: const Text('72h (3 Days)'),
                                selected: _appInstallRetentionHours == 72.0,
                                onSelected: (_) => setState(() => _appInstallRetentionHours = 72.0),
                              ),
                              ChoiceChip(
                                label: const Text('7 Days (168h)'),
                                selected: _appInstallRetentionHours == 168.0,
                                onSelected: (_) => setState(() => _appInstallRetentionHours = 168.0),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Allow Negative Balance on Reversal (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text(
                              'If worker already withdrew funds prior to uninstalling the app, driving their wallet balance into negative so upcoming earnings recover the deficit.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _allowNegativeBalance,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _allowNegativeBalance = val),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Strict Early Uninstall Penalty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text(
                              'Automatically deduct task reward and decrement completed count upon worker app detecting app is not installed during retention period.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _strictEarlyUninstallPenalty,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _strictEarlyUninstallPenalty = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save System Configurations', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

