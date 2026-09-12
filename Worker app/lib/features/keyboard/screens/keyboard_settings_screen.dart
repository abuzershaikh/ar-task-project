import 'package:flutter/material.dart';
import '../services/review_keyboard_service.dart';

class KeyboardSettingsScreen extends StatefulWidget {
  const KeyboardSettingsScreen({super.key});

  @override
  State<KeyboardSettingsScreen> createState() => _KeyboardSettingsScreenState();
}

class _KeyboardSettingsScreenState extends State<KeyboardSettingsScreen>
    with WidgetsBindingObserver {
  bool _isEnabled = false;
  bool _isSelected = false;
  final TextEditingController _testController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _testController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
      _pollStatusAfterAction();
    }
  }

  void _pollStatusAfterAction() {
    _checkStatus();
    final delays = [400, 800, 1500, 2500, 4000];
    for (final ms in delays) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) _checkStatus();
      });
    }
  }

  Future<void> _checkStatus() async {
    final enabled = await ReviewKeyboardService.instance.isKeyboardEnabled();
    final selected = await ReviewKeyboardService.instance.isKeyboardSelected();
    await ReviewKeyboardService.instance.markKeyboardOnboardingSeen();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _isSelected = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Task Review Keyboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Refresh Status',
            onPressed: () async {
              await _checkStatus();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status refreshed!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x202563EB),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.keyboard_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '1-Click Auto-Typing Keyboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Eliminate copy-paste warnings in Google Maps & Play Store! Our keyboard auto-types your assigned review with natural human speed.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: Enable
            _buildStepCard(
              step: '1',
              title: 'Enable Task Review Keyboard',
              desc:
                  'Turn on "Task Review Keyboard" in your Android Manage Keyboards list.',
              isComplete: _isEnabled,
              buttonText: _isEnabled ? '✓ Enabled' : 'Enable in Settings',
              buttonAction: () async {
                await ReviewKeyboardService.instance.openKeyboardSettings();
                _pollStatusAfterAction();
              },
            ),
            const SizedBox(height: 14),

            // Step 2: Switch
            _buildStepCard(
              step: '2',
              title: 'Switch to Task Keyboard',
              desc:
                  'Set Task Review Keyboard as your active input method when doing review tasks.',
              isComplete: _isSelected,
              buttonText: _isSelected ? '✓ Currently Active' : 'Switch Keyboard',
              buttonAction: () async {
                await ReviewKeyboardService.instance.openInputMethodPicker();
                _pollStatusAfterAction();
              },
            ),
            const SizedBox(height: 14),

            // Step 3: Switch back to default keyboard
            _buildStepCard(
              step: '3',
              title: 'Default Keyboard (Gboard / Samsung)',
              desc:
                  'Finished review tasks? You can switch back to your normal daily keyboard anytime with 1 tap.',
              isComplete: !_isSelected,
              buttonText: !_isSelected ? '✓ Default Keyboard Active' : 'Switch to Default Keyboard',
              buttonAction: () async {
                await ReviewKeyboardService.instance.openInputMethodPicker();
                _pollStatusAfterAction();
              },
            ),
            const SizedBox(height: 24),

            // Test Area
            const Text(
              'Test Keyboard Auto-Typing',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Load a demo review to see the keyboard top bar and test the "✍️ Write Review" auto-typing:',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.star_rounded, size: 16),
                        label: const Text('Google Maps Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await ReviewKeyboardService.instance.setActiveReview(
                            taskId: 'demo_maps_123',
                            reviewText: 'Outstanding service and very polite staff! Everything was handled smoothly and professionally.',
                            platform: 'google_maps',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⭐ Google Maps review loaded! Tap the test box below.'),
                                backgroundColor: Color(0xFF0284C7),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Play Store Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await ReviewKeyboardService.instance.setActiveReview(
                            taskId: 'demo_play_456',
                            reviewText: 'Super smooth app with great UI and reliable features. Highly recommended for daily use!',
                            platform: 'playstore',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📱 Play Store review loaded! Tap the test box below.'),
                                backgroundColor: Color(0xFF059669),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                        label: const Text('Clear Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await ReviewKeyboardService.instance.clearActiveReview();
                          _testController.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🧹 Keyboard review cleared!'),
                                backgroundColor: Color(0xFF64748B),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tap the box below to open the keyboard and press "✍️ Write Review":',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _testController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Tap here to test keyboard...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
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

  Widget _buildStepCard({
    required String step,
    required String title,
    required String desc,
    required bool isComplete,
    required String buttonText,
    required VoidCallback buttonAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isComplete ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isComplete
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        step,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isComplete
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFF2563EB),
                foregroundColor: isComplete
                    ? const Color(0xFF15803D)
                    : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: buttonAction,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
