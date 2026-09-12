import 'package:flutter/material.dart';
import '../services/review_keyboard_service.dart';

/// A card displayed in Task Details for Google Business & Play Store Review tasks.
/// Helps the worker enable, switch to, and test the Auto-Typing Review Keyboard.
class KeyboardReviewTile extends StatefulWidget {
  final String customText;
  final String platform;
  final String taskId;

  const KeyboardReviewTile({
    super.key,
    required this.customText,
    required this.platform,
    required this.taskId,
  });

  @override
  State<KeyboardReviewTile> createState() => _KeyboardReviewTileState();
}

class _KeyboardReviewTileState extends State<KeyboardReviewTile>
    with WidgetsBindingObserver {
  bool _isEnabled = false;
  bool _isSelected = false;
  bool _isLoading = true;
  bool _showTestField = false;
  final TextEditingController _testController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkKeyboardStatus();
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
      _checkKeyboardStatus();
    }
  }

  Future<void> _checkKeyboardStatus() async {
    final enabled = await ReviewKeyboardService.instance.isKeyboardEnabled();
    final selected = await ReviewKeyboardService.instance.isKeyboardSelected();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _isSelected = selected;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ReviewKeyboardService.instance.isEligiblePlatform(widget.platform)) {
      return const SizedBox.shrink();
    }

    final isGoogle = widget.platform == 'google_business' ||
        widget.platform == 'google_maps';
    final primaryColor =
        isGoogle ? const Color(0xFF2563EB) : const Color(0xFF059669);
    final lightBg =
        isGoogle ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final borderColor =
        isGoogle ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.keyboard_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Review Auto-Typing Keyboard',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGoogle
                          ? 'Auto-types this review inside Google Maps with 1 tap!'
                          : 'Auto-types this review inside Google Play Store with 1 tap!',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status & Action buttons
          if (_isLoading) ...[
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (!_isEnabled) ...[
            // Keyboard is NOT enabled in system settings
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFB45309), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Enable "Task Review Keyboard" in Settings to use 1-click auto-typing.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await ReviewKeyboardService.instance.openKeyboardSettings();
                  _checkKeyboardStatus();
                },
                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                label: const Text(
                  '1. Enable Task Keyboard in Settings',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (!_isSelected) ...[
            // Keyboard is enabled, but not selected
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Keyboard is enabled! Tap below to switch to "Task Review Keyboard".',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await ReviewKeyboardService.instance.openInputMethodPicker();
                  _checkKeyboardStatus();
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text(
                  '2. Switch to Task Keyboard',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            // Keyboard is enabled AND currently selected
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF15803D), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ Task Keyboard Active! Tap the review field in Maps/Play Store & press "✍️ Write Review".',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF14532D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Test Input area toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Review loaded in keyboard: ${widget.customText.length} chars',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => setState(() => _showTestField = !_showTestField),
                icon: Icon(
                  _showTestField
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: primaryColor,
                ),
                label: Text(
                  _showTestField ? 'Hide Test Pad' : 'Test Keyboard Here',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),

          if (_showTestField) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: TextField(
                controller: _testController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Tap here to open keyboard and test "✍️ Write Review"...',
                  hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
