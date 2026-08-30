import 'package:flutter/material.dart';

class AiCommentConfigWidget extends StatefulWidget {
  final TextEditingController topicController;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onToneChanged;
  final String selectedLanguage;
  final String selectedTone;

  const AiCommentConfigWidget({
    super.key,
    required this.topicController,
    required this.onLanguageChanged,
    required this.onToneChanged,
    required this.selectedLanguage,
    required this.selectedTone,
  });

  @override
  State<AiCommentConfigWidget> createState() => _AiCommentConfigWidgetState();
}

class _AiCommentConfigWidgetState extends State<AiCommentConfigWidget> {
  final List<String> _languages = [
    'English',
    'Hindi',
    'Hinglish',
    'Spanish',
    'Portuguese',
    'Arabic',
  ];

  final List<Map<String, String>> _tones = [
    {'key': 'natural', 'label': 'Natural / Organic', 'emoji': '🌿'},
    {'key': 'enthusiastic', 'label': 'Excited / Hyped', 'emoji': '🔥'},
    {'key': 'professional', 'label': 'Professional', 'emoji': '💼'},
    {'key': 'questioning', 'label': 'Curious / Question', 'emoji': '❓'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'AI Smart Comment Generator',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Unique, human-like comments will be auto-generated for each worker task.',
            style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
          ),
          const Divider(color: Color(0xFFBBF7D0), height: 18),

          // Topic / Keywords
          const Text(
            'Video Topic / Keywords (Optional):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.topicController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Great trading strategy, crypto tutorial...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF16A34A)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Language & Tone
          Row(
            children: [
              // Language Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Language:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: widget.selectedLanguage,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) => widget.onLanguageChanged(val ?? 'English'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Tone Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comment Tone:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: widget.selectedTone,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: _tones.map((t) => DropdownMenuItem(
                        value: t['key'],
                        child: Text('${t['emoji']} ${t['label']}'),
                      )).toList(),
                      onChanged: (val) => widget.onToneChanged(val ?? 'natural'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
