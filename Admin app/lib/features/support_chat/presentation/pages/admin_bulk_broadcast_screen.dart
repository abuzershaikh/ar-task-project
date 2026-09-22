import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/support_chat_service.dart';

class AdminBulkBroadcastScreen extends StatefulWidget {
  const AdminBulkBroadcastScreen({super.key});

  @override
  State<AdminBulkBroadcastScreen> createState() => _AdminBulkBroadcastScreenState();
}

class _AdminBulkBroadcastScreenState extends State<AdminBulkBroadcastScreen> {
  final _chatService = SupportChatService.instance;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _ytController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedSegment = 'ALL'; // 'ALL' | 'NEW' | 'ACTIVE' | 'CUSTOM'
  bool _isLoadingWorkers = true;
  bool _isFirstLoad = true; // Track if this is the very first load
  bool _isSending = false;

  List<dynamic> _workers = [];
  Map<String, dynamic> _counts = {'total_count': 0, 'new_count': 0, 'active_count': 0};
  final Set<String> _selectedWorkerIds = {};

  // Debounce timer for search input
  Timer? _searchDebounce;

  String? _youtubePreviewId;
  File? _attachedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _textController.dispose();
    _ytController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkers() async {
    // Only show loading spinner on the very first load,
    // not on subsequent refreshes (prevents list flickering)
    if (_isFirstLoad) {
      setState(() => _isLoadingWorkers = true);
    }

    try {
      final data = await _chatService.getFilterableWorkers(
        search: _searchController.text.trim(),
        segment: _selectedSegment,
      );

      if (mounted) {
        final newWorkers = (data['workers'] as List?) ?? [];
        final newCounts = (data['counts'] as Map<String, dynamic>?);

        setState(() {
          // Only update workers if we got valid data back
          // This prevents the list from disappearing on API errors
          if (newWorkers.isNotEmpty || _isFirstLoad) {
            _workers = newWorkers;
          }
          if (newCounts != null) {
            _counts = newCounts;
          }
          _isLoadingWorkers = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      // On error, just stop the loading spinner but keep existing data
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
          _isFirstLoad = false;
        });
      }
      debugPrint('[BroadcastScreen] _fetchWorkers error: $e');
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchWorkers();
    });
  }

  void _extractYouTubePreview(String url) {
    final match = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})').firstMatch(url);
    setState(() {
      _youtubePreviewId = match?.group(1);
    });
  }

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      setState(() => _attachedImage = File(img.path));
    }
  }

  int get _targetRecipientCount {
    if (_selectedSegment == 'CUSTOM') {
      return _selectedWorkerIds.length;
    } else if (_selectedSegment == 'NEW') {
      return int.tryParse(_counts['new_count']?.toString() ?? '0') ?? 0;
    } else if (_selectedSegment == 'ACTIVE') {
      return int.tryParse(_counts['active_count']?.toString() ?? '0') ?? 0;
    } else {
      return int.tryParse(_counts['total_count']?.toString() ?? '0') ?? 0;
    }
  }

  Future<void> _handleSendBroadcast() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _youtubePreviewId == null && _attachedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message or attach media')),
      );
      return;
    }

    if (_selectedSegment == 'CUSTOM' && _selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one worker')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Bulk Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to broadcast this message to $_targetRecipientCount workers?\n\nEach worker will receive an individual message in their chat and a high-priority push notification.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Broadcast'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    // Upload image if attached
    if (_attachedImage != null && _uploadedImageUrl == null) {
      _uploadedImageUrl = await _chatService.uploadMedia(_attachedImage!);
    }

    String messageType = 'TEXT';
    if (_youtubePreviewId != null) {
      messageType = 'YOUTUBE';
    } else if (_uploadedImageUrl != null) {
      messageType = 'IMAGE';
    }

    final result = await _chatService.sendBulkMessage(
      segment: _selectedSegment,
      customWorkerIds: _selectedSegment == 'CUSTOM' ? _selectedWorkerIds.toList() : null,
      messageType: messageType,
      content: _youtubePreviewId != null ? _ytController.text.trim() : text,
      mediaUrl: _uploadedImageUrl,
      youtubeId: _youtubePreviewId,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00875A),
            content: Text('✅ Broadcast sent to ${result['count'] ?? _targetRecipientCount} workers successfully!'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to send broadcast: ${result['message'] ?? 'Error'}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bulk Broadcast to Workers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Target Audience Segmentation ─────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Select Target Workers',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Filter recipients by activity status or choose specific workers.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  // Segment Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSegmentChip('ALL', 'All Workers (${_counts['total_count'] ?? 0})', Icons.people_rounded),
                      _buildSegmentChip('NEW', 'New Workers (${_counts['new_count'] ?? 0})', Icons.fiber_new_rounded),
                      _buildSegmentChip('ACTIVE', 'Active (${_counts['active_count'] ?? 0})', Icons.bolt_rounded),
                      _buildSegmentChip('CUSTOM', 'Custom Select (${_selectedWorkerIds.length})', Icons.checklist_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 2. Custom Selection Worker List (if CUSTOM chosen) ───────────
            if (_selectedSegment == 'CUSTOM') ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Recipients',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (final w in _workers) {
                                    if (w['id'] != null) _selectedWorkerIds.add(w['id'].toString());
                                  }
                                });
                              },
                              child: const Text('Select All', style: TextStyle(fontSize: 12, color: Color(0xFF00875A))),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedWorkerIds.clear());
                              },
                              child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Search input
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Filter workers by name, phone...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Workers List
                    _isLoadingWorkers
                        ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                        : Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _workers.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final w = _workers[index];
                                final id = w['id']?.toString() ?? '';
                                final isSelected = _selectedWorkerIds.contains(id);
                                final name = w['full_name'] ?? w['email']?.toString().split('@')[0] ?? 'Worker';
                                final phone = w['phone'] ?? w['email'] ?? '';
                                final completed = w['total_tasks_completed'] ?? 0;

                                return CheckboxListTile(
                                  dense: true,
                                  value: isSelected,
                                  activeColor: const Color(0xFF00875A),
                                  title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  subtitle: Text('$phone • $completed tasks completed', style: const TextStyle(fontSize: 11)),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedWorkerIds.add(id);
                                      } else {
                                        _selectedWorkerIds.remove(id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── 3. Message Composer ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Compose Broadcast Message',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),

                  // Text input
                  TextField(
                    controller: _textController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Enter announcement, instructions, task updates, or greetings for workers...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Attach Media Buttons: YouTube Video & Photo
                  Row(
                    children: [
                      // YouTube Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                        label: const Text('Add YouTube Video', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _showYouTubeInputDialog();
                        },
                      ),
                      const SizedBox(width: 10),

                      // Photo Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                        label: const Text('Add Photo', style: TextStyle(fontSize: 12)),
                        onPressed: _pickImage,
                      ),
                    ],
                  ),

                  // YouTube Preview Card
                  if (_youtubePreviewId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://img.youtube.com/vi/$_youtubePreviewId/hqdefault.jpg',
                              width: 80,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YouTube Video Attached',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                Text(
                                  _ytController.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                            onPressed: () {
                              setState(() {
                                _youtubePreviewId = null;
                                _ytController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Attached Image Preview
                  if (_attachedImage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_attachedImage!, width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Photo attached (will upload during send)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                            onPressed: () => setState(() => _attachedImage = null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Dispatch Action Button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A), // Emerald WhatsApp green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSending ? 'Broadcasting to Workers...' : 'Broadcast to $_targetRecipientCount Workers',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSending ? null : _handleSendBroadcast,
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentChip(String segmentKey, String label, IconData icon) {
    final isSelected = _selectedSegment == segmentKey;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF00875A)),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF00875A),
      side: BorderSide(
        color: isSelected ? const Color(0xFF00875A) : const Color(0xFFCBD5E1),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        setState(() {
          _selectedSegment = segmentKey;
        });
        // Always fetch workers (including CUSTOM) so the list is populated
        _fetchWorkers();
      },
    );
  }

  void _showYouTubeInputDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('YouTube Video URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: _ytController,
          decoration: InputDecoration(
            hintText: 'https://youtube.com/watch?v=...',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _extractYouTubePreview(_ytController.text.trim());
            },
            child: const Text('Attach Video'),
          ),
        ],
      ),
    );
  }
}
