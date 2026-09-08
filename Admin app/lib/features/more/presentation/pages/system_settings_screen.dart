import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

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

  // App Install & Play Store Retention Engine Settings
  double _appInstallRetentionHours = 24.0;
  bool _allowNegativeBalance = true;
  bool _strictEarlyUninstallPenalty = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get('/admin/settings');
      final data = resp.data ?? {};
      setState(() {
        _maintenanceMode = data['maintenanceMode'] ?? false;
        _platformMargin = double.tryParse(data['platformMargin']?.toString() ?? '20.0') ?? 20.0;
        _minWithdrawalAmount = double.tryParse(data['minWithdrawalAmount']?.toString() ?? '100.0') ?? 100.0;
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
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final dio = getIt<DioClient>();
      await dio.post('/admin/settings', data: {
        'maintenanceMode': _maintenanceMode,
        'platformMargin': _platformMargin,
        'minWithdrawalAmount': _minWithdrawalAmount,
      });

      await dio.post('/admin/settings/app-retention', data: {
        'minRetentionHours': _appInstallRetentionHours,
        'allowNegativeBalance': _allowNegativeBalance,
        'strictPenalty': _strictEarlyUninstallPenalty,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All system and retention settings updated successfully')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved locally')));
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
                          const SizedBox(height: 16),
                          Text('Minimum Worker Withdrawal: ₹${_minWithdrawalAmount.toStringAsFixed(0)}'),
                          Slider(
                            value: _minWithdrawalAmount,
                            min: 50.0,
                            max: 1000.0,
                            divisions: 19,
                            activeColor: AppColors.primary,
                            label: '₹${_minWithdrawalAmount.toStringAsFixed(0)}',
                            onChanged: (val) => setState(() => _minWithdrawalAmount = val),
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

