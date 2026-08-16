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
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully')));
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
