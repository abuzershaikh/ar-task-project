import 'package:flutter/material.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/entities/campaign_detail.dart';
import '../../../domain/repositories/campaign_repository.dart';

class AnalyticsTab extends StatefulWidget {
  final CampaignDetail campaign;

  const AnalyticsTab({super.key, required this.campaign});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  Map<String, dynamic>? _apiAnalytics;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final repo = getIt<CampaignRepository>();
    final result = await repo.getCampaignAnalytics(widget.campaign.id);
    if (!mounted) return;
    result.fold(
      (_) => null,
      (data) {
        setState(() {
          _apiAnalytics = data;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final int total = campaign.totalTasks;
    final int completed = campaign.completedTasks;
    final int inProg = campaign.inProgressTasks;
    final int pend = campaign.pendingTasks;
    final int rej = campaign.rejectedTasks;

    final double completionPct = total > 0 ? (completed / total * 100.0) : 0.0;
    final double approvalPct = campaign.approvalRate;
    final double rejectionPct = campaign.rejectionRate;
    final int reviewTime = campaign.averageReviewTimeMinutes;

    final int completedPct = total > 0 ? ((completed / total) * 100).round() : 0;
    final int inProgPct = total > 0 ? ((inProg / total) * 100).round() : 0;
    final int pendPct = total > 0 ? ((pend / total) * 100).round() : 0;
    final int rejPct = total > 0 ? ((rej / total) * 100).round() : 0;

    // Flex weights for segmented bar
    final int flexComp = completed > 0 ? completed : 0;
    final int flexInProg = inProg > 0 ? inProg : 0;
    final int flexPend = pend > 0 ? pend : (total == 0 ? 1 : 0);
    final int flexRej = rej > 0 ? rej : 0;

    // Weekly velocity map from API or fallback
    final velocityMap = (_apiAnalytics?['weeklyVelocity'] as Map<String, dynamic>?) ?? {};
    final int monCount = (velocityMap['Mon'] as num?)?.toInt() ?? 0;
    final int tueCount = (velocityMap['Tue'] as num?)?.toInt() ?? 0;
    final int wedCount = (velocityMap['Wed'] as num?)?.toInt() ?? 0;
    final int thuCount = (velocityMap['Thu'] as num?)?.toInt() ?? 0;
    final int friCount = (velocityMap['Fri'] as num?)?.toInt() ?? 0;
    final int satCount = (velocityMap['Sat'] as num?)?.toInt() ?? 0;
    final int sunCount = (velocityMap['Sun'] as num?)?.toInt() ?? 0;

    final maxVal = [monCount, tueCount, wedCount, thuCount, friCount, satCount, sunCount].reduce((a, b) => a > b ? a : b);

    double factor(int c) {
      if (maxVal == 0) return 0.1;
      return (c / maxVal).clamp(0.15, 1.0);
    }

    return RefreshIndicator(
      onRefresh: _fetchAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Real Performance Overview KPIs
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.insights_rounded, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text(
                        'Key Performance Indicators',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Completion Rate',
                          value: '${completionPct.toStringAsFixed(1)}%',
                          subtext: '$completed of $total done',
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFECFDF5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Approval Rate',
                          value: '${approvalPct.toStringAsFixed(1)}%',
                          subtext: rej > 0 ? '$rej rejected' : 'Clean verification',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Rejection Rate',
                          value: '${rejectionPct.toStringAsFixed(1)}%',
                          subtext: '$rej tasks rejected',
                          color: const Color(0xFFEF4444),
                          bgColor: const Color(0xFFFEF2F2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Avg Turnaround',
                          value: '$reviewTime min',
                          subtext: 'Per proof review',
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFFFBEB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Real Task Fulfillment Pipeline Distribution
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.donut_large_rounded, size: 16, color: Color(0xFF7C3AED)),
                          SizedBox(width: 6),
                          Text(
                            'Task Pipeline Distribution',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Text(
                        '$total Total Tasks',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Multi-color Segmented Progress Bar (Real Distribution)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (flexComp > 0)
                          Expanded(flex: flexComp, child: Container(height: 10, color: const Color(0xFF10B981))),
                        if (flexInProg > 0)
                          Expanded(flex: flexInProg, child: Container(height: 10, color: const Color(0xFF2563EB))),
                        if (flexPend > 0)
                          Expanded(flex: flexPend, child: Container(height: 10, color: const Color(0xFFF59E0B))),
                        if (flexRej > 0)
                          Expanded(flex: flexRej, child: Container(height: 10, color: const Color(0xFFEF4444))),
                        if (total == 0)
                          Expanded(child: Container(height: 10, color: const Color(0xFFCBD5E1))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Legend with real values
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _PipelineLegendItem(color: const Color(0xFF10B981), label: 'Completed: $completed ($completedPct%)'),
                      _PipelineLegendItem(color: const Color(0xFF2563EB), label: 'In Progress: $inProg ($inProgPct%)'),
                      _PipelineLegendItem(color: const Color(0xFFF59E0B), label: 'Pending: $pend ($pendPct%)'),
                      if (rej > 0)
                        _PipelineLegendItem(color: const Color(0xFFEF4444), label: 'Rejected: $rej ($rejPct%)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Hourly / Daily Task Velocity Activity Bar Chart
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'Worker Completion Velocity',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$completed Completed',
                          style: const TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Real completion velocity bars
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _VelocityBar(label: 'Mon', count: monCount, heightFactor: factor(monCount), isPeak: monCount == maxVal && maxVal > 0),
                        _VelocityBar(label: 'Tue', count: tueCount, heightFactor: factor(tueCount), isPeak: tueCount == maxVal && maxVal > 0),
                        _VelocityBar(label: 'Wed', count: wedCount, heightFactor: factor(wedCount), isPeak: wedCount == maxVal && maxVal > 0),
                        _VelocityBar(label: 'Thu', count: thuCount, heightFactor: factor(thuCount), isPeak: thuCount == maxVal && maxVal > 0),
                        _VelocityBar(label: 'Fri', count: friCount, heightFactor: factor(friCount), isPeak: friCount == maxVal && maxVal > 0),
                        _VelocityBar(label: 'Sat', count: satCount, heightFactor: factor(satCount), isPeak: satCount == maxVal && maxVal > 0),
                        _VelocityBar(label: 'Sun', count: sunCount, heightFactor: factor(sunCount), isPeak: sunCount == maxVal && maxVal > 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Quality & Proof Verification Trust Score Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quality & Verification Index: ${approvalPct.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completed of $total tasks verified and completed.',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _PipelineLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _VelocityBar extends StatelessWidget {
  final String label;
  final double heightFactor;
  final int count;
  final bool isPeak;

  const _VelocityBar({
    required this.label,
    required this.heightFactor,
    required this.count,
    this.isPeak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isPeak ? const Color(0xFF059669) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: (70 * heightFactor).clamp(10.0, 70.0),
          decoration: BoxDecoration(
            color: isPeak ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
            color: isPeak ? const Color(0xFF059669) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
