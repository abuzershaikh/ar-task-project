import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/admin_tutorial_model.dart';
import '../../services/admin_tutorials_service.dart';
import '../widgets/add_edit_tutorial_dialog.dart';

class TutorialManagementScreen extends StatefulWidget {
  final String initialAudience;

  const TutorialManagementScreen({
    super.key,
    this.initialAudience = 'buyer',
  });

  @override
  State<TutorialManagementScreen> createState() =>
      _TutorialManagementScreenState();
}

class _TutorialManagementScreenState extends State<TutorialManagementScreen> {
  final _service = AdminTutorialsService();
  final _searchController = TextEditingController();

  late String _currentAudience;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  List<AdminTutorialModel> _tutorials = [];
  bool _isLoading = true;
  bool _isReorderMode = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentAudience = widget.initialAudience;
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getTutorials(
          targetAudience: _currentAudience,
          category: _selectedCategory == 'All' ? null : _selectedCategory,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        ),
        _service.getCategories(targetAudience: _currentAudience),
      ]);

      if (mounted) {
        setState(() {
          _tutorials = results[0] as List<AdminTutorialModel>;
          final rawCats = results[1] as List<String>;
          _categories = ['All', ...rawCats.where((c) => c != 'All')];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tutorials: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openAddDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AddEditTutorialDialog(defaultAudience: _currentAudience),
    );
    if (created == true) {
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutorial added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog(AdminTutorialModel tutorial) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => AddEditTutorialDialog(
        tutorial: tutorial,
        defaultAudience: _currentAudience,
      ),
    );
    if (updated == true) {
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutorial updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(AdminTutorialModel tutorial) async {
    try {
      await _service.toggleStatus(tutorial.id);
      setState(() {
        final index = _tutorials.indexWhere((t) => t.id == tutorial.id);
        if (index != -1) {
          _tutorials[index] = tutorial.copyWith(isActive: !tutorial.isActive);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tutorial.title} is now ${!tutorial.isActive ? 'Active' : 'Inactive'}',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTutorial(AdminTutorialModel tutorial) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tutorial Video?'),
        content: Text('Are you sure you want to delete "${tutorial.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteTutorial(tutorial.id);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tutorial deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _previewVideo(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video: $e')),
        );
      }
    }
  }

  Future<void> _saveReorderedList() async {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < _tutorials.length; i++) {
      items.add({
        'id': _tutorials[i].id,
        'displayOrder': i + 1,
      });
    }

    try {
      await _service.updateOrder(items);
      setState(() => _isReorderMode = false);
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display order saved to server'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer App Tutorials'),
        actions: [
          IconButton(
            icon: Icon(
              _isReorderMode ? Icons.check_circle_rounded : Icons.reorder_rounded,
              color: _isReorderMode ? Colors.greenAccent : null,
            ),
            tooltip: _isReorderMode ? 'Save Order' : 'Reorder Mode',
            onPressed: () {
              if (_isReorderMode) {
                _saveReorderedList();
              } else {
                setState(() => _isReorderMode = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Audience Switcher (Buyer App | Worker App | All)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildAudienceTab('buyer', 'Buyer App', Icons.shopping_bag_outlined),
                const SizedBox(width: 8),
                _buildAudienceTab('worker', 'Worker App', Icons.engineering_outlined),
                const SizedBox(width: 8),
                _buildAudienceTab('all', 'All Apps', Icons.devices_outlined),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, category, or tags...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchData();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
                // Simple debounce
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_searchQuery == val.trim()) {
                    _fetchData();
                  }
                });
              },
            ),
          ),

          // Category Chips Bar
          if (_categories.length > 1)
            Container(
              height: 44,
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _fetchData();
                      }
                    },
                  );
                },
              ),
            ),

          // Reorder Mode Hint Banner
          if (_isReorderMode)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, size: 18, color: Colors.brown),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Drag items by the handle on the right to reorder. Click checkmark in AppBar when done.',
                      style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveReorderedList,
                    child: const Text('Save Order'),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tutorials.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: _isReorderMode
                            ? ReorderableListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _tutorials.length,
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (oldIndex < newIndex) {
                                      newIndex -= 1;
                                    }
                                    final item = _tutorials.removeAt(oldIndex);
                                    _tutorials.insert(newIndex, item);
                                  });
                                },
                                itemBuilder: (ctx, i) {
                                  final item = _tutorials[i];
                                  return _buildReorderItem(item, i, Key(item.id));
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _tutorials.length,
                                itemBuilder: (ctx, i) {
                                  final item = _tutorials[i];
                                  return _buildTutorialCard(item, i);
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Tutorial Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAudienceTab(String audience, String label, IconData icon) {
    final isSelected = _currentAudience == audience;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentAudience = audience;
            _selectedCategory = 'All';
          });
          _fetchData();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(AdminTutorialModel item, int index) {
    final tags = item.tagList;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Thumbnail with Overlays
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.video_collection, color: Colors.white38, size: 48),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.video_collection, color: Colors.white38, size: 48),
                        ),
                ),
              ),

              // Play Icon in Center
              Positioned.fill(
                child: Center(
                  child: InkWell(
                    onTap: () => _previewVideo(item.videoUrl),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),

              // Top Left: Display Order Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'Order #${item.displayOrder}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Top Right: Target Audience Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.targetAudience == 'buyer'
                        ? const Color(0xFF2563EB)
                        : item.targetAudience == 'worker'
                            ? const Color(0xFF059669)
                            : const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.targetAudience.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Bottom Right: Duration Badge
              if (item.duration != null && item.duration!.isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.duration!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // Card Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Visibility status Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Active Status Switch
                    Text(
                      item.isActive ? 'Active' : 'Hidden',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.isActive ? Colors.green.shade700 : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: item.isActive,
                      activeTrackColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) => _toggleStatus(item),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                // Description
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Tags Wrap
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Preview'),
                      onPressed: () => _previewVideo(item.videoUrl),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      onPressed: () => _openEditDialog(item),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      tooltip: 'Delete',
                      onPressed: () => _deleteTutorial(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderItem(AdminTutorialModel item, int index, Key key) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.thumbnailUrl!,
                  width: 50,
                  height: 38,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: Colors.grey, width: 50, height: 38),
                )
              : Container(color: Colors.grey, width: 50, height: 38),
        ),
        title: Text(
          '#${index + 1} - ${item.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${item.category} • ${item.targetAudience.toUpperCase()}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Tutorial Videos Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tutorials matched "$_searchQuery". Try searching other keywords or tags.'
                  : 'Get started by adding your first tutorial video for $_currentAudience app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAddDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Tutorial Video'),
            ),
          ],
        ),
      ),
    );
  }
}
