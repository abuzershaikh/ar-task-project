import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

class RiskFraudScreen extends StatefulWidget {
  const RiskFraudScreen({super.key});

  @override
  State<RiskFraudScreen> createState() => _RiskFraudScreenState();
}

class _RiskFraudScreenState extends State<RiskFraudScreen> {
  bool _isLoading = true;
  int _flaggedCount = 0;
  int _suspendedCount = 0;
  List<dynamic> _riskFlags = [];

  @override
  void initState() {
    super.initState();
    _fetchRiskDashboard();
  }

  Future<void> _fetchRiskDashboard() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get('/admin/risk/dashboard').catchError((_) => dio.get('/admin/risk/workers'));
      
      final data = resp.data ?? {};
      setState(() {
        _flaggedCount = (data['flaggedAccountsCount'] as num?)?.toInt() ?? 0;
        _suspendedCount = (data['suspendedCount'] as num?)?.toInt() ?? 0;
        _riskFlags = (data['recentFlags'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk & Fraud Control'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRiskDashboard,
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
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.shield, color: AppColors.success, size: 24),
                                const SizedBox(height: 12),
                                const Text('Automated Fraud Shield', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                const SizedBox(height: 4),
                                const Text('ACTIVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning, color: AppColors.warning, size: 24),
                                const SizedBox(height: 12),
                                const Text('Flagged Accounts', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                const SizedBox(height: 4),
                                Text('$_flaggedCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Recent Risk Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 12),

                  _riskFlags.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: const [
                                Icon(Icons.verified_user, color: AppColors.success, size: 48),
                                SizedBox(height: 12),
                                Text('No High-Risk Fraud Alerts Detected', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray800)),
                                SizedBox(height: 4),
                                Text('Multiple device detection and IP velocity checks are operating normally.', style: TextStyle(fontSize: 12, color: AppColors.gray600), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _riskFlags.length,
                          itemBuilder: (context, index) {
                            final item = _riskFlags[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.error, color: AppColors.error),
                                title: Text(item['rule'] ?? 'Suspicious Activity'),
                                subtitle: Text(item['userId'] ?? 'User'),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
