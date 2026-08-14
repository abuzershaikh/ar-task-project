import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

class MatchingBrainScreen extends StatefulWidget {
  const MatchingBrainScreen({super.key});

  @override
  State<MatchingBrainScreen> createState() => _MatchingBrainScreenState();
}

class _MatchingBrainScreenState extends State<MatchingBrainScreen> {
  bool _isLoading = true;
  String _status = 'ONLINE';
  String _health = 'HEALTHY';
  int _activeEnginesCount = 11;

  @override
  void initState() {
    super.initState();
    _fetchEngineStatus();
  }

  Future<void> _fetchEngineStatus() async {
    try {
      final dio = getIt<DioClient>();
      final statusResp = await dio.get('/admin/engine/matching/status');
      final progressResp = await dio.get('/admin/engine/progress/overview');
      
      setState(() {
        _status = (statusResp.data['status'] ?? 'ONLINE').toString().toUpperCase();
        _health = (progressResp.data['engineHealth'] ?? 'HEALTHY').toString().toUpperCase();
        final engines = progressResp.data['activeEngines'] as List?;
        if (engines != null) {
          _activeEnginesCount = engines.length;
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Brain'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEngineStatus,
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
                  // Engine Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.psychology, color: AppColors.success, size: 48),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Engine Status',
                            style: TextStyle(fontSize: 14, color: AppColors.gray600),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: Text(
                              '$_status • $_health',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildEngineMetric('Active Engines', '$_activeEnginesCount'),
                              _buildEngineMetric('Avg Response', '45ms'),
                              _buildEngineMetric('Success Rate', '98.2%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

            // Real-time Matching Activity
            const Text(
              'Real-time Matching Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActivityRow('Active Campaigns', '45', AppColors.primary),
                    _buildActivityRow('Candidate Pool Size', '1,245', AppColors.info),
                    _buildActivityRow('Matches Found (Today)', '892', AppColors.success),
                    _buildActivityRow('Avg Candidates/Task', '12', AppColors.warning),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sample Matching Rationale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Candidate Worker Pool',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text('W${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text('Worker W-${1000 + index}'),
                    subtitle: Text('Match Score: ${95 - (index * 3)}%'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRankColor(index).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Rank ${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getRankColor(index),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why This Worker Was Selected:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            _buildRationaleItem(Icons.check_circle, 'Active status', AppColors.success),
                            _buildRationaleItem(Icons.verified, 'KYC verified', AppColors.success),
                            _buildRationaleItem(Icons.trending_up, 'High quality score (92.5)', AppColors.success),
                            _buildRationaleItem(Icons.speed, 'Available capacity (3 tasks)', AppColors.success),
                            _buildRationaleItem(Icons.location_on, 'Location match', AppColors.success),
                            _buildRationaleItem(Icons.category, 'Category expertise', AppColors.success),
                            const SizedBox(height: 12),
                            const Text(
                              'Why Worker Y Was Rejected:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            _buildRationaleItem(Icons.cancel, 'Already assigned similar task', AppColors.error),
                            _buildRationaleItem(Icons.warning, 'Low completion rate (75%)', AppColors.warning),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Filter Configuration
            const Text(
              'Active Filter Pipeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  _buildFilterTile('Active Filter', 'Status = ACTIVE', true),
                  _buildFilterTile('KYC Filter', 'KYC Verified', true),
                  _buildFilterTile('Capacity Filter', 'Available slots > 0', true),
                  _buildFilterTile('Location Filter', 'Within service area', true),
                  _buildFilterTile('Category Filter', 'Matching expertise', true),
                  _buildFilterTile('Duplicate Filter', 'No recent duplicates', true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Used Worker Exclusion
            const Text(
              'Exclusion Policies',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildExclusionItem('Same Campaign', '24 hours', 'Prevent duplicate tasks'),
                    _buildExclusionItem('Similar Tasks', '12 hours', 'Avoid clustering'),
                    _buildExclusionItem('Failed Tasks', '7 days', 'Quality control'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildActivityRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRationaleItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTile(String name, String condition, bool isActive) {
    return ListTile(
      dense: true,
      leading: Icon(
        isActive ? Icons.check_circle : Icons.cancel,
        color: isActive ? AppColors.success : AppColors.gray400,
        size: 20,
      ),
      title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(condition, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildExclusionItem(String type, String duration, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.block, size: 16, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$duration • $reason', style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return AppColors.success;
    if (index == 1) return AppColors.info;
    if (index == 2) return AppColors.warning;
    return AppColors.gray600;
  }
}
