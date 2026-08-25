import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';
import '../../domain/models/action_type.dart';
import '../../domain/models/element_category.dart';
import '../../domain/models/element_type.dart';

class ElementPropertyInspector extends StatefulWidget {
  final TemplateElement element;
  final Function(TemplateElement) onSave;

  const ElementPropertyInspector({
    super.key,
    required this.element,
    required this.onSave,
  });

  @override
  State<ElementPropertyInspector> createState() => _ElementPropertyInspectorState();
}

class _ElementPropertyInspectorState extends State<ElementPropertyInspector> {
  late TextEditingController _keyController;
  late TextEditingController _labelController;
  late VisibilityContext _visibility;
  late EditabilityMode _editability;
  late bool _isRequired;
  ActionType? _actionType;
  bool _showAdvanced = false;

  // Type specific controllers
  late TextEditingController _videoUrlController;
  late TextEditingController _audioUrlController;
  late TextEditingController _buttonTextController;
  late TextEditingController _placeholderController;
  late TextEditingController _paragraphContentController;
  late TextEditingController _defaultValueController;
  late TextEditingController _optionsController;
  late TextEditingController _imageUrlController;
  late TextEditingController _timerSecondsController;
  late TextEditingController _proofInstructionsController;

  // Proof switches
  bool _requireScreenshot = true;
  bool _requireTextProof = false;

  // Voice recording simulation & preview state
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _isPlayingAudio = false;
  double _audioProgress = 0.0;
  Timer? _audioPlaybackTimer;
  int _audioElapsedSeconds = 0;
  final int _audioTotalSeconds = 45;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.element.key);
    _labelController = TextEditingController(text: widget.element.label);
    _visibility = widget.element.visibility;
    _isRequired = widget.element.isRequired;
    _actionType = widget.element.actionType ?? ActionType.openUrl;

    // Heading & Paragraph are Admin-Fixed by default (No buyer input)
    if (widget.element.type == ElementType.heading || widget.element.type == ElementType.paragraph) {
      _editability = EditabilityMode.adminFixed;
    } else {
      _editability = widget.element.editability;
    }

    final props = widget.element.properties;
    _videoUrlController = TextEditingController(text: props['url']?.toString() ?? props['videoUrl']?.toString() ?? '');
    _audioUrlController = TextEditingController(text: props['url']?.toString() ?? props['audioUrl']?.toString() ?? '');
    _buttonTextController = TextEditingController(text: props['buttonText']?.toString() ?? 'Open Link & Complete Task');
    _placeholderController = TextEditingController(text: props['placeholder']?.toString() ?? '');
    _paragraphContentController = TextEditingController(text: props['content']?.toString() ?? props['instructions']?.toString() ?? '');
    _defaultValueController = TextEditingController(text: props['defaultValue']?.toString() ?? '');
    _optionsController = TextEditingController(text: props['options'] is List ? (props['options'] as List).join(', ') : props['options']?.toString() ?? '');
    _imageUrlController = TextEditingController(text: props['imageUrl']?.toString() ?? props['url']?.toString() ?? '');
    _timerSecondsController = TextEditingController(text: props['durationSeconds']?.toString() ?? '60');
    _proofInstructionsController = TextEditingController(text: props['proofInstructions']?.toString() ?? '');

    _requireScreenshot = props['requireScreenshot'] is bool ? props['requireScreenshot'] as bool : true;
    _requireTextProof = props['requireTextProof'] is bool ? props['requireTextProof'] as bool : false;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    _videoUrlController.dispose();
    _audioUrlController.dispose();
    _buttonTextController.dispose();
    _placeholderController.dispose();
    _paragraphContentController.dispose();
    _defaultValueController.dispose();
    _optionsController.dispose();
    _imageUrlController.dispose();
    _timerSecondsController.dispose();
    _proofInstructionsController.dispose();
    _recordTimer?.cancel();
    _audioPlaybackTimer?.cancel();
    super.dispose();
  }

  void _onLabelChanged(String val) {
    if (widget.element.key.startsWith('heading_') ||
        widget.element.key.startsWith('paragraph_') ||
        widget.element.key.startsWith('textField_') ||
        widget.element.key.startsWith('actionButton_') ||
        widget.element.key.startsWith('youtube_') ||
        widget.element.key.startsWith('audio_')) {
      final autoKey = val.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      if (autoKey.isNotEmpty) {
        _keyController.text = autoKey;
      }
    }
  }

  String? _extractYouTubeId(String url) {
    if (url.trim().isEmpty) return null;
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url.trim());
    return match?.group(1);
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 120) {
          _stopVoiceRecording();
        }
      }
    });
  }

  void _stopVoiceRecording() {
    _recordTimer?.cancel();
    final generatedUrl = 'https://earnpost-media-worker.aawuazer.workers.dev/audio/voice_guide_${DateTime.now().millisecondsSinceEpoch}.m4a';
    setState(() {
      _isRecording = false;
      _audioUrlController.text = generatedUrl;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice Guide Recorded (${_recordSeconds}s) & Ready!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleAudioPlayback() {
    if (_isPlayingAudio) {
      _audioPlaybackTimer?.cancel();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      _audioPlaybackTimer?.cancel();
      _audioPlaybackTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_audioElapsedSeconds < _audioTotalSeconds) {
          setState(() {
            _audioElapsedSeconds++;
            _audioProgress = _audioElapsedSeconds / _audioTotalSeconds;
          });
        } else {
          t.cancel();
          setState(() {
            _isPlayingAudio = false;
            _audioElapsedSeconds = 0;
            _audioProgress = 0.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.element.type;
    final isSystem = widget.element.category == ElementCategory.system;
    final isYouTube = type == ElementType.youtube;
    final isAudio = type == ElementType.audio;
    final isHeading = type == ElementType.heading;
    final isParagraph = type == ElementType.paragraph;
    final isTextField = type == ElementType.textField;
    final isNumberField = type == ElementType.numberField;
    final isDropdown = type == ElementType.dropdownField;
    final isActionButton = type == ElementType.actionButton;
    final isImage = type == ElementType.imageBanner;
    final isSystemProof = type == ElementType.systemProof;
    final isSystemTimer = type == ElementType.systemTimer;
    final ytId = isYouTube ? _extractYouTubeId(_videoUrlController.text) : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isYouTube
                              ? Icons.video_library_rounded
                              : (isAudio
                                  ? Icons.graphic_eq_rounded
                                  : (isHeading
                                      ? Icons.title_rounded
                                      : (isParagraph ? Icons.notes_rounded : Icons.tune_rounded))),
                          color: isYouTube ? Colors.redAccent : (isAudio ? Colors.indigoAccent : Colors.cyanAccent),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Configure: ${type.label}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ══════════════════════════════════════════════════════════
            // 1. PRIMARY TITLE / LABEL
            // ══════════════════════════════════════════════════════════
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: isHeading
                    ? 'Campaign Header / Title (Admin Defined) *'
                    : (isParagraph
                        ? 'Guidelines / Section Title *'
                        : (isNumberField
                            ? 'Quantity / Count Field Label *'
                            : 'Component Title / Label *')),
                labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                hintText: isHeading
                    ? 'e.g. YouTube Subscribe & Like Campaign'
                    : (isParagraph
                        ? 'e.g. Step-by-Step Task Instructions'
                        : (isNumberField ? 'e.g. Enter Subscriber Count' : 'e.g. Target Link')),
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onLabelChanged,
            ),
            const SizedBox(height: 14),

            // ══════════════════════════════════════════════════════════
            // HEADING SPECIFIC BANNER (Admin Fixed - No Buyer Input)
            // ══════════════════════════════════════════════════════════
            if (isHeading) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This title is set by Admin and displayed at the top of the campaign. Buyer will not see an input box for this.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // PARAGRAPH SPECIFIC FIELDS (Fixed Instructions / Guidelines)
            // ══════════════════════════════════════════════════════════
            if (isParagraph) ...[
              TextField(
                controller: _paragraphContentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Fixed Task Guidelines for Workers (Admin Defined)',
                  labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  hintText: 'Enter step-by-step instructions that workers must follow...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // NUMBER FIELD (Buyer Quantity / Count Input)
            // ══════════════════════════════════════════════════════════
            if (isNumberField) ...[
              TextField(
                controller: _placeholderController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Placeholder Hint for Buyer Count',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  hintText: 'e.g. Enter count (e.g. 100, 500, 1000)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // TEXT FIELD (Target Link / Username)
            // ══════════════════════════════════════════════════════════
            if (isTextField) ...[
              TextField(
                controller: _placeholderController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Placeholder Hint (Buyer Target Link)',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  hintText: 'e.g. https://youtube.com/watch?v=... or @channel_name',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // DROPDOWN SELECTOR FIELDS
            // ══════════════════════════════════════════════════════════
            if (isDropdown) ...[
              TextField(
                controller: _optionsController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Dropdown Options (Comma separated)',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  hintText: 'e.g. 100, 500, 1000, 5000',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // ACTION BUTTON FIELDS
            // ══════════════════════════════════════════════════════════
            if (isActionButton) ...[
              TextField(
                controller: _buttonTextController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Button Display Text',
                  labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  hintText: 'e.g. Open Link & Complete Task',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // YOUTUBE VIDEO EMBED FIELDS
            // ══════════════════════════════════════════════════════════
            if (isYouTube) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.play_circle_filled_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'YouTube Tutorial Video Link (Worker Guidance)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _videoUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'YouTube Video URL',
                        labelStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
                        hintText: 'https://youtube.com/watch?v=... or https://youtu.be/...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        prefixIcon: const Icon(Icons.link_rounded, color: Colors.redAccent, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          backgroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(color: Colors.redAccent),
                          label: const Text('Sample Tutorial Video',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          avatar: const Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 14),
                          onPressed: () {
                            setState(() {
                              _videoUrlController.text = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
                            });
                          },
                        ),
                        if (_videoUrlController.text.isNotEmpty)
                          ActionChip(
                            backgroundColor: const Color(0xFF1E293B),
                            label: const Text('Clear', style: TextStyle(fontSize: 10, color: Colors.white70)),
                            onPressed: () => setState(() => _videoUrlController.clear()),
                          ),
                      ],
                    ),
                    if (ytId != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 100,
                                color: Colors.black26,
                                alignment: Alignment.center,
                                child: const Text('Invalid Video Link', style: TextStyle(color: Colors.white54)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                            ),
                            Positioned(
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                                child: const Text('Live YouTube Video Connected',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // AUDIO VOICE GUIDE & RECORDER
            // ══════════════════════════════════════════════════════════
            if (isAudio) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.indigoAccent.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded, color: Colors.indigoAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Voice Audio Guide Studio (Worker Guidance)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _audioUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Cloudflare R2 / Server Audio URL',
                        labelStyle: const TextStyle(color: Colors.indigoAccent, fontSize: 11),
                        hintText: 'https://media.earnpost.workers.dev/audio/...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        prefixIcon: const Icon(Icons.audiotrack_rounded, color: Colors.indigoAccent, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Voice Recorder Studio Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (_isRecording)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(
                                    _isRecording
                                        ? 'RECORDING VOICE (${_recordSeconds}s)...'
                                        : (_audioUrlController.text.isNotEmpty
                                            ? 'VOICE GUIDE ATTACHED'
                                            : 'VOICE RECORDER STUDIO'),
                                    style: TextStyle(
                                      color: _isRecording ? Colors.redAccent : Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isRecording)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.mic_rounded, size: 14),
                                  label: const Text('Record Voice',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: _startVoiceRecording,
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.stop_rounded, size: 14),
                                  label: const Text('Stop & Upload',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: _stopVoiceRecording,
                                ),
                            ],
                          ),
                          if (_audioUrlController.text.isNotEmpty && !_isRecording) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _toggleAudioPlayback,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration:
                                        const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
                                    child: Icon(
                                      _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      LinearProgressIndicator(
                                        value: _audioProgress,
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                                        minHeight: 4,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Listen Preview (${(_audioElapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_audioElapsedSeconds % 60).toString().padLeft(2, '0')})',
                                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // SYSTEM PROOF SETTINGS
            // ══════════════════════════════════════════════════════════
            if (isSystemProof) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.amberAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Worker Proof Verification Rules',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require Screenshot Proof',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Worker must upload screenshot proof after finishing',
                          style: TextStyle(color: Colors.white54, fontSize: 10)),
                      value: _requireScreenshot,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _requireScreenshot = val),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require Text / Transaction ID Proof',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Worker must type verification code or account handle',
                          style: TextStyle(color: Colors.white54, fontSize: 10)),
                      value: _requireTextProof,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _requireTextProof = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ══════════════════════════════════════════════════════════
            // SYSTEM TIMER SETTINGS
            // ══════════════════════════════════════════════════════════
            if (isSystemTimer) ...[
              TextField(
                controller: _timerSecondsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Timer Duration (Seconds)',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  hintText: 'e.g. 60',
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Who can view this?
            const Text('Who can see this component?',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<VisibilityContext>(
              value: _visibility,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: VisibilityContext.values.map((v) {
                return DropdownMenuItem(value: v, child: Text(v.label));
              }).toList(),
              onChanged: isSystem ? null : (val) => setState(() => _visibility = val!),
            ),
            const SizedBox(height: 12),

            // Who fills this? (Only shown for non-heading, non-paragraph, non-system)
            if (!isHeading && !isParagraph && !isSystem) ...[
              const Text('Who fills or interacts with this?',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<EditabilityMode>(
                value: _editability,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: EditabilityMode.values.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e.label));
                }).toList(),
                onChanged: (val) => setState(() => _editability = val!),
              ),
              const SizedBox(height: 12),
            ],

            // Action Binding (if interactive button)
            if (widget.element.category == ElementCategory.interactive) ...[
              const Text('What action should this button trigger?',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ActionType>(
                value: _actionType,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: ActionType.values.map((a) {
                  return DropdownMenuItem(value: a, child: Text(a.label));
                }).toList(),
                onChanged: (val) => setState(() => _actionType = val),
              ),
              const SizedBox(height: 12),
            ],

            // Is Required Field Switch
            if (!isHeading && !isParagraph)
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Mandatory / Required Field',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                subtitle: const Text('User cannot submit without completing this field',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                value: _isRequired,
                activeColor: Colors.cyanAccent,
                onChanged: isSystem ? null : (val) => setState(() => _isRequired = val),
              ),
            const SizedBox(height: 8),

            // Optional Advanced Technical Settings (Collapsed by default)
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Icon(_showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white54, size: 18),
                    const SizedBox(width: 6),
                    const Text('Advanced Technical Config (Developer Only)',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                enabled: !isSystem,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: InputDecoration(
                  labelText: 'System Field ID (Auto Generated)',
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Save Component Settings Button
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Save Component Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  final updatedProps = Map<String, dynamic>.from(widget.element.properties);

                  if (isHeading) {
                    updatedProps['content'] = _labelController.text.trim();
                  } else if (isParagraph) {
                    updatedProps['content'] = _paragraphContentController.text.trim();
                    updatedProps['instructions'] = _paragraphContentController.text.trim();
                  } else if (isYouTube) {
                    updatedProps['url'] = _videoUrlController.text.trim();
                    updatedProps['videoUrl'] = _videoUrlController.text.trim();
                  } else if (isAudio) {
                    updatedProps['url'] = _audioUrlController.text.trim();
                    updatedProps['audioUrl'] = _audioUrlController.text.trim();
                  } else if (isActionButton) {
                    updatedProps['buttonText'] = _buttonTextController.text.trim();
                  } else if (isTextField || isNumberField) {
                    if (_placeholderController.text.isNotEmpty) {
                      updatedProps['placeholder'] = _placeholderController.text.trim();
                    }
                  } else if (isDropdown) {
                    final opts = _optionsController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    updatedProps['options'] = opts;
                  } else if (isSystemProof) {
                    updatedProps['requireScreenshot'] = _requireScreenshot;
                    updatedProps['requireTextProof'] = _requireTextProof;
                  } else if (isSystemTimer) {
                    updatedProps['durationSeconds'] = int.tryParse(_timerSecondsController.text.trim()) ?? 60;
                  }

                  final updated = widget.element.copyWith(
                    key: _keyController.text.trim().replaceAll(' ', '_'),
                    label: _labelController.text.trim(),
                    visibility: _visibility,
                    editability: (isHeading || isParagraph) ? EditabilityMode.adminFixed : _editability,
                    isRequired: (isHeading || isParagraph) ? true : _isRequired,
                    actionType: _actionType,
                    properties: updatedProps,
                  );
                  widget.onSave(updated);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
