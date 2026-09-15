import 'package:flutter/material.dart';

class AiCommentConfigWidget extends StatefulWidget {
  final TextEditingController topicController;
  final TextEditingController? appNameController;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onToneChanged;
  final String selectedLanguage;
  final String selectedTone;
  final int selectedQuantity;
  final List<String> sampleComments;
  final bool isGeneratingPreview;
  final VoidCallback onGeneratePreview;
  final bool isAppReview;
  final bool isGoogleBusiness;
  final bool isInstagram;
  final String? appName;
  final int minWords;
  final int maxWords;
  final void Function(int min, int max)? onWordLimitChanged;

  const AiCommentConfigWidget({
    super.key,
    required this.topicController,
    this.appNameController,
    required this.onLanguageChanged,
    required this.onToneChanged,
    required this.selectedLanguage,
    required this.selectedTone,
    this.selectedQuantity = 10,
    this.sampleComments = const [],
    this.isGeneratingPreview = false,
    required this.onGeneratePreview,
    this.isAppReview = false,
    this.isGoogleBusiness = false,
    this.isInstagram = false,
    this.appName,
    this.minWords = 15,
    this.maxWords = 45,
    this.onWordLimitChanged,
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
    final bool isGoogle = widget.isGoogleBusiness;
    final bool isApp = widget.isAppReview && !isGoogle;
    final bool isInsta = widget.isInstagram;

    final previewTargetCount = widget.selectedQuantity < 5
        ? (widget.selectedQuantity > 0 ? widget.selectedQuantity : 1)
        : 5;
    final displayedComments =
        widget.sampleComments.take(previewTargetCount).toList();
    final hasSamples = displayedComments.isNotEmpty;
    final remainingCount =
        (widget.selectedQuantity - displayedComments.length).clamp(0, 99999);

    final String unitType = isGoogle
        ? (previewTargetCount == 1 ? "5-Star Review" : "5-Star Reviews")
        : (isApp
            ? (previewTargetCount == 1 ? "5-Star Review" : "5-Star Reviews")
            : (previewTargetCount == 1 ? "Comment" : "Comments"));
    final countLabel = '$previewTargetCount Sample $unitType';

    final Color containerBg = isGoogle
        ? const Color(0xFFEFF6FF)
        : (isApp
            ? const Color(0xFFF0FDF4)
            : (isInsta ? const Color(0xFFFDF2F8) : const Color(0xFFFEF2F2)));
    final Color containerBorder = isGoogle
        ? const Color(0xFF93C5FD)
        : (isApp
            ? const Color(0xFF86EFAC)
            : (isInsta ? const Color(0xFFFBCFE8) : const Color(0xFFFECACA)));
    final Color headerIconBg = isGoogle
        ? const Color(0xFFDBEAFE)
        : (isApp
            ? const Color(0xFFDCFCE7)
            : (isInsta ? const Color(0xFFFCE7F3) : const Color(0xFFFEE2E2)));
    final Color primaryColor = isGoogle
        ? const Color(0xFF2563EB)
        : (isApp
            ? const Color(0xFF16A34A)
            : (isInsta ? const Color(0xFFE1306C) : const Color(0xFFDC2626)));
    final Color titleColor = isGoogle
        ? const Color(0xFF1E40AF)
        : (isApp
            ? const Color(0xFF166534)
            : (isInsta ? const Color(0xFF9D174D) : const Color(0xFF991B1B)));
    final Color badgeBg = isGoogle
        ? const Color(0xFFDBEAFE)
        : (isApp
            ? const Color(0xFFDCFCE7)
            : (isInsta ? const Color(0xFFFCE7F3) : const Color(0xFFFEE2E2)));
    final Color badgeBorder = isGoogle
        ? const Color(0xFFBFDBFE)
        : (isApp
            ? const Color(0xFFBBF7D0)
            : (isInsta ? const Color(0xFFFBCFE8) : const Color(0xFFFECACA)));
    final Color badgeTextColor = isGoogle
        ? const Color(0xFF1D4ED8)
        : (isApp
            ? const Color(0xFF15803D)
            : (isInsta ? const Color(0xFFBE185D) : const Color(0xFFB91C1C)));
    final Color dividerColor = isGoogle
        ? const Color(0xFFBFDBFE)
        : (isApp
            ? const Color(0xFFBBF7D0)
            : (isInsta ? const Color(0xFFFBCFE8) : const Color(0xFFFECACA)));

    final String widgetTitle = isGoogle
        ? 'Custom Organic 5-Star Google Reviews'
        : (isApp
            ? 'Custom Organic 5-Star Reviews'
            : (isInsta
                ? 'Custom Organic Instagram Comments'
                : 'Custom Organic YouTube Comments'));

    final String badgeLabel = isGoogle
        ? '100% Real Local Customers'
        : (isApp
            ? '100% Unique & Natural'
            : (isInsta ? '100% Real Active IG Users' : '100% Unique & Natural'));

    final String widgetDescription = isGoogle
        ? 'Authentic, genuine 5-star business reviews crafted for individual workers to post on Google Maps / Google Business.'
        : (isApp
            ? 'Authentic, genuine 5-star app reviews crafted for individual workers to post on Google Play Store.'
            : (isInsta
                ? 'Authentic, high-engagement comments crafted for individual workers to post on your Instagram Reel or Post.'
                : 'Authentic, context-relevant comments crafted for individual workers to post naturally.'));

    final String nameFieldLabel = isGoogle
        ? 'Business / Place Name:'
        : (isApp
            ? 'App Name:'
            : (isInsta
                ? 'Instagram Handle / Post Topic (Optional):'
                : 'Video Title / Topic (Detected or Enter Manually):'));

    final String nameFieldHint = isGoogle
        ? 'e.g. Royal Dental Clinic, Cafe Bistro, Sharma Automobiles'
        : (isApp
            ? 'e.g. Cashify, PhonePe, WhatsApp'
            : (isInsta
                ? 'e.g. @username, Fashion Reel, Gym Transformation, Cafe Aesthetics'
                : 'e.g. Trading Strategy Masterclass, Tech Vlog, Python Tutorial'));

    final IconData nameFieldIcon = isGoogle
        ? Icons.storefront_rounded
        : (isApp
            ? Icons.apps_rounded
            : (isInsta ? Icons.camera_alt_outlined : Icons.play_circle_outline_rounded));

    final String promptFieldLabel = isGoogle
        ? 'Review Focus / Service Highlights (Optional):'
        : (isApp
            ? 'Review Focus / Custom Prompt (Optional):'
            : (isInsta
                ? 'AI Comment Focus / Tone (Optional):'
                : 'AI Prompt / Comment Instructions (Optional):'));

    final String promptFieldSubtext = isGoogle
        ? 'Specify what services, staff behavior, cleanliness, or highlights AI should praise.'
        : (isApp
            ? 'Specify what specific features or feedback AI should focus on.'
            : (isInsta
                ? 'Specify what workers should praise (e.g. video transitions, aesthetic vibe, outfit details, drop fire emojis 🔥).'
                : 'Enter a prompt or custom instructions for AI on what kind of comments to generate.'));

    final String promptFieldHint = isGoogle
        ? 'e.g. Polite staff, quick service, clean environment, highly recommended'
        : (isApp
            ? 'e.g. Fast pickup, quick payment, smooth delivery (or leave blank for natural praise)'
            : (isInsta
                ? 'e.g. Praise the reel aesthetic, ask for outfit/location, drop fire emojis 🔥...'
                : 'e.g. Praise the video, ask for part 2, ask insightful questions, highlight key tips...'));

    final List<String> suggestions = isGoogle
        ? [
            'Polite Staff & Fast Service',
            'Highly Recommended',
            'Great Experience',
            'Neat & Clean Ambience',
            'Professional & Punctual',
            'Best in the Area',
          ]
        : (isApp
            ? [
                'Smooth & Fast UI',
                'Excellent Support',
                'Very Useful App',
                'Recommended to All',
              ]
            : (isInsta
                ? [
                    'Fire & Trending 🔥',
                    'Aesthetic & Love it ❤️',
                    'Outfit / Location Details',
                    'Relatable & Funny 😂',
                    'Pure Quality Content 👏',
                    'Support & Share',
                  ]
                : [
                    'Praise & Support',
                    'Ask for Part 2',
                    'Insightful Tutorial',
                    'Great Explanation',
                    'Subscribed & Liked',
                  ]));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: containerBorder),
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
                  color: headerIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isGoogle
                      ? Icons.location_on_rounded
                      : (isApp
                          ? Icons.verified_rounded
                          : (isInsta ? Icons.camera_alt_rounded : Icons.mode_comment_rounded)),
                  color: primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widgetTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGoogle ? Icons.place_rounded : Icons.shield_outlined,
                      size: 12,
                      color: badgeTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.appName != null && widget.appName!.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 64,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFB45309)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isGoogle ? 'Business: ${widget.appName}' : 'Target: ${widget.appName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widgetDescription,
            style: TextStyle(fontSize: 11, color: titleColor, height: 1.3),
          ),
          Divider(color: dividerColor, height: 20),

          // App Name / Business Name / Video Title Input
          if (widget.appNameController != null) ...[
            Row(
              children: [
                Icon(
                  nameFieldIcon,
                  size: 16,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nameFieldLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.appNameController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: nameFieldHint,
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(
                  nameFieldIcon,
                  size: 18,
                  color: primaryColor,
                ),
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
          ],

          // Dedicated AI Prompt Field
          Row(
            children: [
              Icon(
                isGoogle
                    ? Icons.rate_review_rounded
                    : (isApp
                        ? Icons.rate_review_rounded
                        : (isInsta ? Icons.chat_bubble_outline_rounded : Icons.psychology_rounded)),
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  promptFieldLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            promptFieldSubtext,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.topicController,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: promptFieldHint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: Icon(
                Icons.auto_awesome,
                size: 18,
                color: primaryColor,
              ),
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
          const SizedBox(height: 8),

          // Quick Prompt Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions
                  .map((suggestion) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          label: Text(
                            '+ $suggestion',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () {
                            final current = widget.topicController.text.trim();
                            if (current.isEmpty) {
                              widget.topicController.text = suggestion;
                            } else if (!current.contains(suggestion)) {
                              widget.topicController.text = '$current, $suggestion';
                            }
                          },
                        ),
                      ))
                  .toList(),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: widget.selectedLanguage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: _languages
                          .map((l) => DropdownMenuItem(
                                value: l,
                                child: Text(l, overflow: TextOverflow.ellipsis, maxLines: 1),
                              ))
                          .toList(),
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
                    Text(
                      isGoogle || isApp ? 'Review Tone:' : 'Comment Tone:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: widget.selectedTone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: _tones
                          .map((t) => DropdownMenuItem(
                                value: t['key'],
                                child: Text(t['label'] ?? '',
                                    overflow: TextOverflow.ellipsis, maxLines: 1),
                              ))
                          .toList(),
                      onChanged: (val) => widget.onToneChanged(val ?? 'natural'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Word Limit Slider (Min & Max Words)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Word Count Limit:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeBorder),
                      ),
                      child: Text(
                        '${widget.minWords} – ${widget.maxWords} Words',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isGoogle || isApp
                      ? 'Select desired minimum and maximum review word length.'
                      : 'Select desired minimum and maximum comment word length.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                // Range Slider
                RangeSlider(
                  values: RangeValues(
                    widget.minWords.clamp(8, 120).toDouble(),
                    widget.maxWords.clamp(widget.minWords + 4, 120).toDouble(),
                  ),
                  min: 8,
                  max: 120,
                  divisions: 28,
                  activeColor: primaryColor,
                  inactiveColor: const Color(0xFFE2E8F0),
                  labels: RangeLabels(
                    '${widget.minWords}w',
                    '${widget.maxWords}w',
                  ),
                  onChanged: (RangeValues values) {
                    widget.onWordLimitChanged?.call(
                      values.start.round(),
                      values.end.round(),
                    );
                  },
                ),

                // Quick Presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWordPresetChip(
                      label: '⚡ Short (10-25w)',
                      min: 10,
                      max: 25,
                      isSelected: widget.minWords <= 12 && widget.maxWords <= 25,
                      primaryColor: primaryColor,
                    ),
                    _buildWordPresetChip(
                      label: '⭐ Standard (25-50w)',
                      min: 25,
                      max: 50,
                      isSelected: widget.minWords >= 20 && widget.minWords <= 30 && widget.maxWords >= 45 && widget.maxWords <= 55,
                      primaryColor: primaryColor,
                    ),
                    _buildWordPresetChip(
                      label: '📝 In-Depth (50-90w)',
                      min: 50,
                      max: 90,
                      isSelected: widget.minWords >= 45 && widget.maxWords >= 85,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Generate Preview Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isGeneratingPreview ? null : widget.onGeneratePreview,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: widget.isGeneratingPreview
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                    )
                  : Icon(
                      isGoogle
                          ? Icons.location_on_rounded
                          : (isApp
                              ? Icons.star_rate_rounded
                              : (isInsta ? Icons.camera_alt_rounded : Icons.mode_comment_outlined)),
                      size: 18,
                    ),
              label: Text(
                widget.isGeneratingPreview
                    ? (isGoogle
                        ? 'Crafting sample 5-star Google reviews...'
                        : (isApp
                            ? 'Crafting sample 5-star reviews...'
                            : (isInsta
                                ? 'Crafting sample Instagram comments...'
                                : 'Crafting sample comments...')))
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
                border: Border.all(color: containerBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isGoogle
                              ? 'Sample 5-Star Google Reviews (${displayedComments.length} of ${widget.selectedQuantity})'
                              : (isApp
                                  ? 'Sample 5-Star Reviews (${displayedComments.length} of ${widget.selectedQuantity})'
                                  : (isInsta
                                      ? 'Sample Instagram Comments (${displayedComments.length} of ${widget.selectedQuantity})'
                                      : (widget.selectedQuantity < 5
                                          ? 'Generated Comments (${displayedComments.length} of ${widget.selectedQuantity})'
                                          : 'Sample Preview (${displayedComments.length} of ${widget.selectedQuantity} Comments)'))),
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle_rounded, color: primaryColor, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...displayedComments.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final comment = entry.value;
                    final wordCount = comment.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
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
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '#$index',
                                  style: TextStyle(
                                    color: badgeTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '• ${wordCount}w',
                                  style: TextStyle(
                                    color: badgeTextColor.withOpacity(0.75),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              comment,
                              style: const TextStyle(
                                  color: Color(0xFF334155), fontSize: 12, height: 1.3),
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
                      color: containerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: containerBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isGoogle
                                ? (widget.selectedQuantity > 5
                                    ? 'Showing 5 sample preview Google Maps reviews. The remaining $remainingCount unique reviews will be automatically prepared upon placing the order. Every worker receives their own distinct review to post.'
                                    : 'All ${displayedComments.length} unique 5-star Google reviews are ready. Each worker will receive their own distinct review to post.')
                                : (isApp
                                    ? (widget.selectedQuantity > 5
                                        ? 'Showing 5 sample preview 5-star reviews. The remaining $remainingCount unique reviews will be automatically prepared upon placing the order. Every worker receives their own distinct review to post.'
                                        : 'All ${displayedComments.length} unique 5-star reviews are ready. Each worker will receive their own distinct review to post.')
                                    : (isInsta
                                        ? (widget.selectedQuantity > 5
                                            ? 'Showing 5 sample preview Instagram comments. The remaining $remainingCount unique comments will be automatically prepared upon placing the order. Every worker receives their own distinct comment to post.'
                                            : 'All ${displayedComments.length} unique Instagram comments are ready. Each worker will receive their own distinct comment to post.')
                                        : (widget.selectedQuantity > 5
                                            ? 'Showing 5 sample preview comments. The remaining $remainingCount unique comments will be automatically prepared upon placing the order. Every worker receives their own distinct comment to post.'
                                            : 'All ${displayedComments.length} unique comments are ready. Each worker will receive their own distinct comment to post.'))),
                            style: TextStyle(
                              color: titleColor,
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

  Widget _buildWordPresetChip({
    required String label,
    required int min,
    required int max,
    required bool isSelected,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: () => widget.onWordLimitChanged?.call(min, max),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
