import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/admin_tutorial_model.dart';
import '../../services/admin_tutorials_service.dart';

class AddEditTutorialDialog extends StatefulWidget {
  final AdminTutorialModel? tutorial;
  final String defaultAudience;

  const AddEditTutorialDialog({
    super.key,
    this.tutorial,
    this.defaultAudience = 'buyer',
  });

  @override
  State<AddEditTutorialDialog> createState() => _AddEditTutorialDialogState();
}

class _AddEditTutorialDialogState extends State<AddEditTutorialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = AdminTutorialsService();

  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _orderController;
  late TextEditingController _durationController;

  late String _selectedAudience;
  late String _selectedCategory;
  late bool _isActive;
  bool _isSaving = false;

  final List<String> _categoryPresets = [
    'Play Store',
    'YouTube',
    'Google Maps',
    'Wallet & Billing',
    'Campaigns',
    'Tasks Guide',
    'Earnings & Payout',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tutorial;
    _titleController = TextEditingController(text: t?.title ?? '');
    _urlController = TextEditingController(text: t?.videoUrl ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _tagsController = TextEditingController(text: t?.tags ?? '');
    _orderController = TextEditingController(text: t?.displayOrder.toString() ?? '1');
    _durationController = TextEditingController(text: t?.duration ?? '3:00');

    _selectedAudience = t?.targetAudience ?? widget.defaultAudience;
    _selectedCategory = t?.category ?? 'Play Store';
    if (!_categoryPresets.contains(_selectedCategory)) {
      _categoryPresets.insert(0, _selectedCategory);
    }
    _isActive = t?.isActive ?? true;

    _urlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _orderController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String? _extractYouTubeId(String url) {
    if (url.trim().isEmpty) return null;
    final clean = url.trim();
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(clean);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    if (clean.length == 11 && !clean.contains('/')) {
      return clean;
    }
    return null;
  }

  String _getPreviewThumbnail() {
    final ytId = _extractYouTubeId(_urlController.text);
    if (ytId != null && ytId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
    }
    return widget.tutorial?.thumbnailUrl ?? '';
  }

  Future<void> _testVideo() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;
    final uri = Uri.parse(raw);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final ytId = _extractYouTubeId(_urlController.text.trim());
      final thumb = ytId != null
          ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg'
          : widget.tutorial?.thumbnailUrl;

      if (widget.tutorial == null) {
        // Create
        await _service.createTutorial(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          videoUrl: _urlController.text.trim(),
          thumbnailUrl: thumb,
          category: _selectedCategory,
          tags: _tagsController.text.trim(),
          targetAudience: _selectedAudience,
          displayOrder: int.tryParse(_orderController.text.trim()) ?? 1,
          duration: _durationController.text.trim(),
          isActive: _isActive,
        );
      } else {
        // Update
        await _service.updateTutorial(
          widget.tutorial!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          videoUrl: _urlController.text.trim(),
          thumbnailUrl: thumb,
          category: _selectedCategory,
          tags: _tagsController.text.trim(),
          targetAudience: _selectedAudience,
          displayOrder: int.tryParse(_orderController.text.trim()) ?? 1,
          duration: _durationController.text.trim(),
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tutorial: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tutorial != null;
    final thumb = _getPreviewThumbnail();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_collection_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Tutorial Video' : 'Add Tutorial Video',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video URL Field
                      const Text(
                        'YouTube Video URL *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'https://youtu.be/... or https://www.youtube.com/watch?v=...',
                          prefixIcon: const Icon(Icons.link, color: AppColors.primary),
                          suffixIcon: _urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                                  tooltip: 'Test Video',
                                  onPressed: _testVideo,
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Video URL is required';
                          }
                          if (!v.contains('youtu')) {
                            return 'Please enter a valid YouTube video URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Thumbnail Preview
                      if (thumb.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: thumb,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Center(
                                    child: Icon(Icons.videocam_off, color: Colors.white54, size: 36),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Live Preview',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Title Field
                      const Text(
                        'Video Title *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. How to Create a Play Store Campaign',
                          prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Target Audience Selector
                      const Text(
                        'Target Audience *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildAudienceChip('buyer', 'Buyer App', Icons.shopping_bag_outlined),
                          const SizedBox(width: 8),
                          _buildAudienceChip('worker', 'Worker App', Icons.engineering_outlined),
                          const SizedBox(width: 8),
                          _buildAudienceChip('all', 'All Apps', Icons.devices_outlined),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      const Text(
                        'Category *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: _categoryPresets.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Search Tags Field (Special User Request)
                      Row(
                        children: [
                          const Text(
                            'Search Match Tags',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Matches Search Query',
                              style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          hintText: 'play store, installs, review, rating, youtube, campaign',
                          helperText: 'Comma-separated keywords matching user search',
                          prefixIcon: const Icon(Icons.tag, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display Order & Duration Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Display Order',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _orderController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '1, 2, 3...',
                                    prefixIcon: const Icon(Icons.format_list_numbered, color: AppColors.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Duration Badge',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _durationController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 3:45',
                                    prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Description / Guide (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Brief explanation of what the user learns from this tutorial...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Active Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active & Visible in App',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          _isActive ? 'Visible to users on their tutorial tab' : 'Hidden from users',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        value: _isActive,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Create Tutorial',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildAudienceChip(String audience, String label, IconData icon) {
    final isSelected = _selectedAudience == audience;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedAudience = audience),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
