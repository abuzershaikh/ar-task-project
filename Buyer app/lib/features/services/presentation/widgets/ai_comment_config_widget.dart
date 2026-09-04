import 'package:flutter/material.dart';

class AiCommentConfigWidget extends StatefulWidget {
  final TextEditingController topicController;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onToneChanged;
  final String selectedLanguage;
  final String selectedTone;
  final int selectedQuantity;
  final List<String> sampleComments;
  final bool isGeneratingPreview;
  final VoidCallback onGeneratePreview;
  final bool isAppReview;

  const AiCommentConfigWidget({
    super.key,
    required this.topicController,
    required this.onLanguageChanged,
    required this.onToneChanged,
    required this.selectedLanguage,
    required this.selectedTone,
    this.selectedQuantity = 10,
    this.sampleComments = const [],
    this.isGeneratingPreview = false,
    required this.onGeneratePreview,
    this.isAppReview = false,
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
    {'key': 'natural', 'label': 'Natural / Organic'},
    {'key': 'enthusiastic', 'label': 'Excited / Highly Engaged'},
    {'key': 'professional', 'label': 'Professional / Insightful'},
    {'key': 'questioning', 'label': 'Curious / Questions'},
  ];

  @override
  Widget build(BuildContext context) {
    final previewTargetCount = widget.selectedQuantity < 5 ? (widget.selectedQuantity > 0 ? widget.selectedQuantity : 1) : 5;
    final displayedComments = widget.sampleComments.take(previewTargetCount).toList();
    final hasSamples = displayedComments.isNotEmpty;
    final remainingCount = (widget.selectedQuantity - displayedComments.length).clamp(0, 99999);
    final unitType = widget.isAppReview ? (previewTargetCount == 1 ? "5-Star Review" : "5-Star Reviews") : (previewTargetCount == 1 ? "Comment" : "Comments");
    final countLabel = '$previewTargetCount Sample $unitType';

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
          // Header: Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.isAppReview ? 'Custom Organic 5-Star Reviews' : 'Custom Organic Comments',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 100% Unique Badge placed cleanly below Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: Color(0xFF15803D)),
                SizedBox(width: 4),
                Text(
                  '100% Unique & Natural',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isAppReview
                ? 'Authentic, genuine 5-star app reviews crafted for individual workers to post on Google Play Store.'
                : 'Authentic, context-relevant comments crafted for individual workers to post naturally.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.3),
          ),
          const Divider(color: Color(0xFFBBF7D0), height: 20),

          // Topic / Keywords
          Text(
            widget.isAppReview ? 'App Review Focus / Key Features (Optional):' : 'Video Topic / Keywords (Optional):',
            style: const TextStyle(
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
              hintText: widget.isAppReview
                  ? 'e.g. Smooth UI, fast performance, highly recommended app...'
                  : 'e.g. Great trading strategy, helpful tutorial, tech vlog...',
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
                        child: Text(t['label'] ?? ''),
                      )).toList(),
                      onChanged: (val) => widget.onToneChanged(val ?? 'natural'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Generate Preview Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isGeneratingPreview ? null : widget.onGeneratePreview,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: widget.isGeneratingPreview
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
                    )
                  : Icon(widget.isAppReview ? Icons.star_rate_rounded : Icons.mode_comment_outlined, size: 18),
              label: Text(
                widget.isGeneratingPreview
                    ? (widget.isAppReview ? 'Crafting sample 5-star reviews...' : 'Crafting sample comments...')
                    : (hasSamples ? '🔄 Regenerate $countLabel' : '✨ Generate $countLabel'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),

          // Preview Cards List (If generated)
          if (hasSamples) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isAppReview
                            ? 'Sample 5-Star Reviews (${displayedComments.length} of ${widget.selectedQuantity})'
                            : (widget.selectedQuantity < 5
                                ? 'Generated Comments (${displayedComments.length} of ${widget.selectedQuantity})'
                                : 'Sample Preview (${displayedComments.length} of ${widget.selectedQuantity} Comments)'),
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...displayedComments.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final comment = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$index',
                              style: const TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              comment,
                              style: const TextStyle(color: Color(0xFF334155), fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.isAppReview
                                ? (widget.selectedQuantity > 5
                                    ? 'Showing 5 sample preview 5-star reviews. The remaining $remainingCount unique reviews will be automatically prepared upon placing the order. Every worker receives their own distinct review to post.'
                                    : 'All ${displayedComments.length} unique 5-star reviews are ready. Each worker will receive their own distinct review to post.')
                                : (widget.selectedQuantity > 5
                                    ? 'Showing 5 sample preview comments. The remaining $remainingCount unique comments will be automatically prepared upon placing the order. Every worker receives their own distinct comment to post.'
                                    : 'All ${displayedComments.length} unique comments are ready. Each worker will receive their own distinct comment to post.'),
                            style: const TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
