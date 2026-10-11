import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';

/// ReviewAutoApproveScreen - Admin Review Auto-Approve Timeframe Settings
/// Allows Admin to set the deadline window (hours) for Buyer/Admin proof reviews.
/// If not reviewed within this time frame, worker screenshot is automatically approved
/// and wallet coins are credited immediately.
class ReviewAutoApproveScreen extends StatefulWidget {
  const ReviewAutoApproveScreen({super.key});

  @override
  State<ReviewAutoApproveScreen> createState() => _ReviewAutoApproveScreenState();
}

class _ReviewAutoApproveScreenState extends State<ReviewAutoApproveScreen> {
  final TextEditingController _hoursController = TextEditingController(text: '24.0');
  bool _autoApproveEnabled = true;
  int _pendingCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTriggering = false;
  String? _lastSweepResult;

  final List<double> _presetHours = [6.0, 12.0, 24.0, 48.0, 72.0];

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get('/admin/settings/review-auto-approve');
      final data = resp.data;
      if (data != null && data['settings'] != null) {
        final settings = data['settings'];
        setState(() {
          _hoursController.text = (settings['reviewAutoApproveHours'] ?? 24.0).toString();
          _autoApproveEnabled = settings['reviewAutoApproveEnabled'] ?? true;
          _pendingCount = data['pendingCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching review auto-approve settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid review auto-approve deadline in hours'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = getIt<DioClient>();
      await dio.post('/admin/settings/review-auto-approve', data: {
        'reviewAutoApproveHours': hours,
        'reviewAutoApproveEnabled': _autoApproveEnabled,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _autoApproveEnabled
                  ? '✅ Review Auto-Approve window set to $hours hours!'
                  : 'ℹ️ Review Auto-Approval disabled.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _triggerManualSweep() async {
    setState(() => _isTriggering = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.post('/admin/settings/review-auto-approve/trigger');
      final result = resp.data?['result'];
      final approved = result?['autoApprovedCount'] ?? 0;
      final evaluated = result?['evaluatedCount'] ?? 0;
      final skipped = result?['skippedCount'] ?? 0;

      setState(() {
        _lastSweepResult = 'Sweep complete: $approved auto-approved, $skipped still within deadline ($evaluated total)';
      });

      await _fetchSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Sweep complete: $approved worker submissions auto-approved!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger sweep: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTriggering = false);
    }
  }

  void _selectPreset(double hours) {
    setState(() {
      _hoursController.text = hours.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentHours = double.tryParse(_hoursController.text.trim()) ?? 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Auto-Approve Review Time'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Hero Status Card ───────────────────────────
                    _buildHeroStatusCard(currentHours),
                    const SizedBox(height: 20),

                    // ── 2. Time Window Configuration Card ─────────────
                    _buildTimeConfigCard(currentHours),
                    const SizedBox(height: 20),

                    // ── 3. More Info / How It Works Explainer Card ────
                    _buildMoreInfoCard(currentHours),
                    const SizedBox(height: 20),

                    // ── 4. Live Queue & Sweep Trigger Card ────────────
                    _buildLiveQueueCard(),
                    const SizedBox(height: 32),

                    // ── 5. Save Button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          _isSaving ? 'Saving Settings...' : 'Save Configuration',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroStatusCard(double currentHours) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_mode_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Auto-Approval Engine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _autoApproveEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) {
                  setState(() => _autoApproveEnabled = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _autoApproveEnabled
                ? 'Active: Unreviewed worker proof screenshots will auto-approve after $currentHours hours.'
                : 'Paused: Auto-approval is disabled. Reviews require manual approval from Buyer or Admin.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _autoApproveEnabled
                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _autoApproveEnabled
                    ? const Color(0xFF34D399)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _autoApproveEnabled ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _autoApproveEnabled ? 'STATUS: ACTIVE' : 'STATUS: PAUSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeConfigCard(double currentHours) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Review Deadline Timeframe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Specify the maximum waiting time (in hours) allowed for Buyer and Admin to review worker proofs before system automatically approves:',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 16),

          // Preset Chips
          const Text(
            'Quick Presets:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetHours.map((h) {
              final isSelected = (currentHours - h).abs() < 0.05;
              final label = h == 24.0 ? '24h (Standard)' : '${h.toInt()}h';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) => _selectPreset(h),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Input Field
          TextFormField(
            controller: _hoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Auto-Approve Window (Hours)',
              hintText: 'e.g. 24.0',
              suffixText: 'Hours',
              prefixIcon: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreInfoCard(double currentHours) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'More Info & How It Works',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInfoStep(
            step: '1',
            title: 'Worker Proof Submission',
            description: 'Worker completes their assigned task and uploads screenshot / proof link. Task status transitions to PENDING.',
          ),
          const SizedBox(height: 10),

          _buildInfoStep(
            step: '2',
            title: 'Review Window Countdown ($currentHours Hours)',
            description: 'Both Buyer (in Buyer app) and Admin (in Admin app) have $currentHours hours to inspect the proof screenshot and either Approve or Reject.',
          ),
          const SizedBox(height: 10),

          _buildInfoStep(
            step: '3',
            title: 'Automated Timeout Trigger',
            description: 'If neither Buyer nor Admin reviews or rejects the submission within $currentHours hours, the system background monitor triggers automatic approval.',
          ),
          const SizedBox(height: 10),

          _buildInfoStep(
            step: '4',
            title: 'Instant Worker Credit',
            description: 'The worker receives their coin reward in wallet immediately, preventing delayed payouts caused by unresponsive buyers.',
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anti-Fraud: System still runs real-time fraud assessment score checks before auto-crediting earnings.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep({required String step, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveQueueCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rate_review_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pending Reviews Queue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingCount Pending',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Need to trigger an immediate check right now? Run a manual sweep to evaluate all pending submissions against the configured timeframe.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTriggering ? null : _triggerManualSweep,
              icon: _isTriggering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bolt_rounded, size: 18),
              label: Text(_isTriggering ? 'Running Sweep...' : 'Run Auto-Approve Sweep Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_lastSweepResult != null) ...[
            const SizedBox(height: 10),
            Text(
              _lastSweepResult!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
