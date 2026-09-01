import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

class TaskExpirySettingsScreen extends StatefulWidget {
  const TaskExpirySettingsScreen({super.key});

  @override
  State<TaskExpirySettingsScreen> createState() => _TaskExpirySettingsScreenState();
}

class _TaskExpirySettingsScreenState extends State<TaskExpirySettingsScreen> {
  final TextEditingController _workerTimeoutController = TextEditingController(text: '2.0');
  final TextEditingController _unacceptedExpiryController = TextEditingController(text: '24.0');
  bool _autoReassign = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTriggering = false;
  String? _lastCycleResult;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _workerTimeoutController.dispose();
    _unacceptedExpiryController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get('/admin/settings/task-expiry');
      final data = resp.data;
      if (data != null && data['settings'] != null) {
        final settings = data['settings'];
        setState(() {
          _workerTimeoutController.text = (settings['workerExecutionTimeoutHours'] ?? 2.0).toString();
          _unacceptedExpiryController.text = (settings['unacceptedTaskExpiryHours'] ?? 24.0).toString();
          _autoReassign = settings['autoReassignOnExpiry'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching task expiry settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final workerHours = double.tryParse(_workerTimeoutController.text.trim());
    final unacceptedHours = double.tryParse(_unacceptedExpiryController.text.trim());

    if (workerHours == null || workerHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid worker completion deadline in hours')),
      );
      return;
    }

    if (unacceptedHours == null || unacceptedHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unaccepted pool expiry in hours')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = getIt<DioClient>();
      await dio.post('/admin/settings/task-expiry', data: {
        'workerExecutionTimeoutHours': workerHours,
        'unacceptedTaskExpiryHours': unacceptedHours,
        'autoReassignOnExpiry': _autoReassign,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task Expiry & Auto-Reassignment settings saved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _triggerManualCycle() async {
    setState(() => _isTriggering = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.post('/admin/settings/task-expiry/trigger');
      final result = resp.data?['result'];
      setState(() {
        if (result != null) {
          _lastCycleResult =
              'Evaluated: ${result['evaluatedTasksCount'] ?? 0} | Expired: ${result['expiredTasksCount'] ?? 0} | Reallocated: ${result['reallocatedTasksCount'] ?? 0} | Extended: ${result['extendedCampaignsCount'] ?? 0}';
        } else {
          _lastCycleResult = 'Cycle executed successfully';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Manual deadline monitor cycle completed!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed running cycle: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTriggering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Task Expiry & Timeout',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Info Banner ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan.withOpacity(0.15), Colors.blue.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Automated Task Expiration Engine',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Set exact time windows for accepted worker tasks and unaccepted pool tasks. Expired tasks are automatically released and re-broadcast to other active workers.',
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Card 1: Worker Completion Deadline (Accepted Task Expiry) ──
                  _buildSectionCard(
                    icon: Icons.hourglass_top_rounded,
                    iconColor: Colors.amberAccent,
                    title: '1. Worker Completion Deadline (Post-Accept)',
                    badgeText: 'CRITICAL',
                    badgeColor: Colors.amberAccent,
                    subtitle:
                        'Allowed time in hours for a worker to submit task proof after tapping Accept. If not completed within this time, the task expires for that worker.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline Window (Hours) *',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _workerTimeoutController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. 2.0 (2 Hours)',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.alarm_rounded, color: Colors.amberAccent, size: 20),
                            suffixText: 'Hours',
                            suffixStyle: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [1.0, 2.0, 3.0, 6.0, 12.0, 24.0].map((h) {
                            return ActionChip(
                              backgroundColor: const Color(0xFF0F172A),
                              side: BorderSide(color: Colors.white.withOpacity(0.15)),
                              label: Text('$h h', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                              onPressed: () => setState(() => _workerTimeoutController.text = h.toString()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Card 2: Unaccepted Pool Task Expiry ──
                  _buildSectionCard(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: Colors.cyanAccent,
                    title: '2. Unaccepted Task Availability Window',
                    badgeText: 'POOL LIFECYCLE',
                    badgeColor: Colors.cyanAccent,
                    subtitle:
                        'Maximum hours an unaccepted task remains live in the global worker pool before expiring or auto-refreshing for new worker batches.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unaccepted Task Lifetime (Hours) *',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _unacceptedExpiryController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. 24.0 (24 Hours)',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.hourglass_bottom_rounded, color: Colors.cyanAccent, size: 20),
                            suffixText: 'Hours',
                            suffixStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [12.0, 24.0, 48.0, 72.0, 168.0].map((h) {
                            return ActionChip(
                              backgroundColor: const Color(0xFF0F172A),
                              side: BorderSide(color: Colors.white.withOpacity(0.15)),
                              label: Text('$h h', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                              onPressed: () => setState(() => _unacceptedExpiryController.text = h.toString()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Card 3: Auto-Reassignment & Reallocation Policy ──
                  _buildSectionCard(
                    icon: Icons.sync_alt_rounded,
                    iconColor: Colors.greenAccent,
                    title: '3. Auto-Reassign to Other Workers',
                    badgeText: 'AUTOMATION',
                    badgeColor: Colors.greenAccent,
                    subtitle:
                        'When an accepted task expires without proof submission, automatically release it back to the available pool so other workers can immediately pick it up.',
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Enable Instant Auto-Reassignment',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Release timed-out worker and notify eligible workers in pool',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: _autoReassign,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) => setState(() => _autoReassign = val),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Card 4: Manual Test Trigger & Stats ──
                  _buildSectionCard(
                    icon: Icons.bolt_rounded,
                    iconColor: Colors.purpleAccent,
                    title: '4. Manual Execution & Real-Time Test',
                    badgeText: 'TEST & AUDIT',
                    badgeColor: Colors.purpleAccent,
                    subtitle:
                        'Test the background reallocation engine immediately without waiting for the 60-second automated interval.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_lastCycleResult != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: Colors.purpleAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _lastCycleResult!,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purpleAccent,
                              side: const BorderSide(color: Colors.purpleAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isTriggering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                                  )
                                : const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(
                              _isTriggering ? 'Running Cycle...' : 'Run Deadline Monitor Cycle Now',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isTriggering ? null : _triggerManualCycle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Save Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Saving Configurations...' : 'Save Expiry Configurations',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.35),
          ),
          const Divider(color: Colors.white12, height: 20),
          child,
        ],
      ),
    );
  }
}
