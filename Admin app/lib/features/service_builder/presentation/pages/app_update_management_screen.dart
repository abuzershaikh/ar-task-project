import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

class AppUpdateManagementScreen extends StatefulWidget {
  const AppUpdateManagementScreen({super.key});

  @override
  State<AppUpdateManagementScreen> createState() => _AppUpdateManagementScreenState();
}

class _AppUpdateManagementScreenState extends State<AppUpdateManagementScreen> {
  final TextEditingController _latestVersionController = TextEditingController(text: '1.0.5');
  final TextEditingController _latestVersionCodeController = TextEditingController(text: '5');
  final TextEditingController _apkUrlController = TextEditingController(text: '');
  final TextEditingController _messageController = TextEditingController(
    text: 'A new version of Task Reward Worker is available. Please update your app to continue.',
  );
  final TextEditingController _releaseNotesController = TextEditingController(
    text: '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security',
  );

  List<Map<String, dynamic>> _versionList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUpdateSettings();
  }

  @override
  void dispose() {
    _latestVersionController.dispose();
    _latestVersionCodeController.dispose();
    _apkUrlController.dispose();
    _messageController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUpdateSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.get('/admin/settings/app-updates');
      final data = resp.data;
      if (data != null && data['settings'] != null) {
        final s = data['settings'];
        setState(() {
          final rawList = s['versionList'] as List? ?? [];
          _versionList = rawList.map((e) {
            final m = Map<String, dynamic>.from(e);
            final u = (m['updateUrl'] ?? '').toString();
            if (u.contains('github.com') || u.contains('raw.githubusercontent.com')) {
              m['updateUrl'] = '';
            }
            return m;
          }).toList();

          _latestVersionController.text = (s['latestVersion'] ?? '1.0.5').toString();
          _latestVersionCodeController.text = (s['latestVersionCode'] ?? '5').toString();
          final rawUrl = (s['apkDownloadUrl'] ?? '').toString();
          _apkUrlController.text = (rawUrl.contains('github.com') || rawUrl.contains('raw.githubusercontent.com')) ? '' : rawUrl;
          _messageController.text = (s['updateMessage'] ?? '').toString();
          _releaseNotesController.text = (s['releaseNotes'] ?? '').toString();
        });
      }
    } catch (e) {
      debugPrint('Error fetching update settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load version settings: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show Dialog to Add New Version Code
  Future<void> _showAddVersionDialog() async {
    final nameCtrl = TextEditingController(text: '1.0.4');
    final codeCtrl = TextEditingController(text: '4');
    final defaultUrl = (_apkUrlController.text.contains('github.com') || _apkUrlController.text.contains('raw.githubusercontent.com'))
        ? ''
        : _apkUrlController.text.trim();
    final linkCtrl = TextEditingController(text: defaultUrl);
    final msgCtrl = TextEditingController(text: 'Please update to continue using the app.');
    bool forceDisable = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Add Version Code',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Version Name *', style: TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. 1.0.4 or 1.0.0',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Version Code (Android Build Number) *', style: TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. 4 or 1',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: forceDisable ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: forceDisable ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            forceDisable ? Icons.block_rounded : Icons.check_circle_rounded,
                            color: forceDisable ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  forceDisable ? 'Disable Version (Force Update)' : 'Active (Allow normal access)',
                                  style: TextStyle(
                                    color: forceDisable ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Workers on this version will be blocked.',
                                  style: TextStyle(
                                    color: forceDisable ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: forceDisable,
                            activeColor: const Color(0xFFDC2626),
                            onChanged: (val) {
                              setDlgState(() => forceDisable = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Update / Redirect URL for this version',
                        style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: linkCtrl,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Direct APK or Play Store URL...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final vName = nameCtrl.text.trim();
                    final vCode = codeCtrl.text.trim();
                    if (vName.isEmpty && vCode.isEmpty) return;

                    Navigator.pop(ctx);
                    await _addVersion(
                      versionName: vName,
                      versionCode: vCode,
                      status: forceDisable ? 'disabled' : 'active',
                      updateUrl: linkCtrl.text.trim(),
                      message: msgCtrl.text.trim(),
                    );
                  },
                  child: const Text('Add Version', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addVersion({
    required String versionName,
    required String versionCode,
    required String status,
    required String updateUrl,
    required String message,
  }) async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.post('/admin/settings/app-updates/add-version', data: {
        'versionName': versionName,
        'versionCode': versionCode,
        'status': status,
        'updateUrl': updateUrl,
        'message': message,
      });

      final updatedList = resp.data?['versionList'] as List?;
      if (updatedList != null) {
        setState(() {
          _versionList = updatedList.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        await _fetchUpdateSettings();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Version "$versionName" (Code: $versionCode) added as ${status.toUpperCase()}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add version: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show Dialog when Admin clicks "Disable" on an active version
  Future<void> _showDisableVersionDialog(Map<String, dynamic> item) async {
    final vName = item['versionName'] ?? '';
    final vCode = item['versionCode'] ?? '';
    final rawItemUrl = (item['updateUrl'] ?? '').toString().trim();
    final cleanItemUrl = (rawItemUrl.contains('github.com') || rawItemUrl.contains('raw.githubusercontent.com')) ? '' : rawItemUrl;
    final defaultUrl = (_apkUrlController.text.contains('github.com') || _apkUrlController.text.contains('raw.githubusercontent.com'))
        ? ''
        : _apkUrlController.text.trim();
    final linkCtrl = TextEditingController(
      text: cleanItemUrl.isNotEmpty ? cleanItemUrl : defaultUrl,
    );
    final msgCtrl = TextEditingController(
      text: (item['message'] != null && item['message'].toString().isNotEmpty)
          ? item['message'].toString()
          : 'A new version of Task Reward Worker is available. Please update your app to continue.',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Disable Version $vName (#$vCode)',
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Workers running this version will be completely blocked and forced to update to the latest release.',
                          style: TextStyle(color: Color(0xFF991B1B), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text('New Latest Version Update Link (User Redirect URL) *',
                    style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: linkCtrl,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter APK download link or Play Store redirect URL...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '💡 Users will be redirected to this link to download the new version.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                ),
                const SizedBox(height: 12),

                const Text('Update Prompt Message',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: msgCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Message to show to worker...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.block_rounded, size: 16),
              label: const Text('Confirm & Disable', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final link = linkCtrl.text.trim();
                final msg = msgCtrl.text.trim();
                Navigator.pop(ctx);
                await _toggleStatus(item, status: 'disabled', updateUrl: link, message: msg);
              },
            ),
          ],
        );
      },
    );
  }

  /// Toggle Version status (Active / Disabled)
  Future<void> _toggleStatus(
    Map<String, dynamic> item, {
    required String status,
    String? updateUrl,
    String? message,
  }) async {
    setState(() => _isLoading = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.post('/admin/settings/app-updates/toggle-status', data: {
        'id': item['id'],
        'versionName': item['versionName'],
        'versionCode': item['versionCode'],
        'status': status,
        'updateUrl': updateUrl ?? item['updateUrl'] ?? _apkUrlController.text.trim(),
        'message': message ?? item['message'],
      });

      final updatedList = resp.data?['versionList'] as List?;
      if (updatedList != null) {
        setState(() {
          _versionList = updatedList.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        await _fetchUpdateSettings();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'disabled'
                  ? '🚫 Version "${item['versionName']}" DISABLED! Workers will be forced to update.'
                  : '✅ Version "${item['versionName']}" ENABLED! Normal access restored.',
            ),
            backgroundColor: status == 'disabled' ? Colors.orangeAccent : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle status: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Edit Link dialog for a version
  Future<void> _showEditLinkDialog(Map<String, dynamic> item) async {
    final rawItemUrl = (item['updateUrl'] ?? '').toString().trim();
    final cleanItemUrl = (rawItemUrl.contains('github.com') || rawItemUrl.contains('raw.githubusercontent.com')) ? '' : rawItemUrl;
    final defaultUrl = (_apkUrlController.text.contains('github.com') || _apkUrlController.text.contains('raw.githubusercontent.com'))
        ? ''
        : _apkUrlController.text.trim();
    final linkCtrl = TextEditingController(
      text: cleanItemUrl.isNotEmpty ? cleanItemUrl : defaultUrl,
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Redirect Link for v${item['versionName']}',
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: linkCtrl,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Update URL (APK / Play Store)...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                await _toggleStatus(item, status: item['status'] ?? 'disabled', updateUrl: linkCtrl.text.trim());
              },
              child: const Text('Save Link'),
            ),
          ],
        );
      },
    );
  }

  /// Remove version from registry
  Future<void> _removeVersion(Map<String, dynamic> item) async {
    final vName = item['versionName'] ?? item['id'] ?? '';
    try {
      final dio = getIt<DioClient>();
      await dio.delete('/admin/settings/app-updates/remove-version/$vName');
      setState(() {
        _versionList.removeWhere((e) => e['id'] == item['id'] || e['versionName'] == vName);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Version "$vName" removed from registry'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Remove error: $e');
    }
  }

  /// Save all global and list settings
  Future<void> _saveAllSettings() async {
    setState(() => _isSaving = true);
    try {
      final dio = getIt<DioClient>();
      await dio.post('/admin/settings/app-updates', data: {
        'versionList': _versionList,
        'latestVersion': _latestVersionController.text.trim(),
        'latestVersionCode': _latestVersionCodeController.text.trim(),
        'apkDownloadUrl': _apkUrlController.text.trim(),
        'updateMessage': _messageController.text.trim(),
        'releaseNotes': _releaseNotesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ App Version Registry & Configurations saved successfully!'),
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

  @override
  Widget build(BuildContext context) {
    final disabledCount = _versionList.where((v) => v['status'] == 'disabled').length;
    final activeCount = _versionList.where((v) => v['status'] == 'active').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'App Version & Updates',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchUpdateSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Summary Cards ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'TOTAL',
                          value: '${_versionList.length}',
                          icon: Icons.layers_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'DISABLED',
                          value: '$disabledCount',
                          icon: Icons.block_rounded,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'ACTIVE',
                          value: '$activeCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Card 1: Version Codes & Status Control List ──
                  _buildSectionCard(
                    icon: Icons.list_alt_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: '1. Version Code Registry',
                    badgeText: '${_versionList.length} VERSIONS',
                    badgeColor: const Color(0xFFD97706),
                    subtitle:
                        'Control which app versions are allowed. Disabling a version instantly forces workers to update using your redirect link.',
                    trailingAction: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text(
                          'Add New Version Code',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showAddVersionDialog,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_versionList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Center(
                              child: Text(
                                'No versions in registry. Click "+ Add New Version Code" above.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _versionList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _versionList[index];
                              final vName = (item['versionName'] ?? '').toString();
                              final vCode = (item['versionCode'] ?? '').toString();
                              final isDisabled = item['status'] == 'disabled';
                              final updateUrl = (item['updateUrl'] ?? '').toString();

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDisabled
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFF86EFAC),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Row 1: Badges & Edit/Delete Icons (Zero Overflow) ──
                                    Row(
                                      children: [
                                        // Version Code Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFCD34D)),
                                          ),
                                          child: Text(
                                            '#$vCode',
                                            style: const TextStyle(
                                              color: Color(0xFFB45309),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Version Name
                                        Text(
                                          'v$vName',
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Status Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDisabled
                                                ? const Color(0xFFFEE2E2)
                                                : const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDisabled
                                                  ? const Color(0xFFF87171)
                                                  : const Color(0xFF4ADE80),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isDisabled ? Icons.block_rounded : Icons.check_circle_rounded,
                                                color: isDisabled ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                                size: 10,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isDisabled ? 'DISABLED' : 'ACTIVE',
                                                style: TextStyle(
                                                  color: isDisabled ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const Spacer(),

                                        // Edit Link Icon
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          icon: const Icon(Icons.link_rounded, color: AppColors.primary, size: 19),
                                          tooltip: 'Edit Redirect Link',
                                          onPressed: () => _showEditLinkDialog(item),
                                        ),
                                        const SizedBox(width: 4),

                                        // Delete Icon
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 19),
                                          tooltip: 'Delete from registry',
                                          onPressed: () => _removeVersion(item),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // ── Row 2: Redirect URL info box ──
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.link_rounded,
                                            color: isDisabled ? const Color(0xFFD97706) : AppColors.primary,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              updateUrl.isNotEmpty
                                                  ? updateUrl
                                                  : (_apkUrlController.text.isNotEmpty
                                                      ? 'Default: ${_apkUrlController.text}'
                                                      : 'No redirect URL set'),
                                              style: TextStyle(
                                                color: isDisabled ? const Color(0xFFB45309) : const Color(0xFF334155),
                                                fontSize: 10.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // ── Row 3: Dedicated Full-Width Disable/Enable Button (Never Overflows) ──
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: !isDisabled
                                          ? ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFEF2F2),
                                                foregroundColor: const Color(0xFFDC2626),
                                                side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                              icon: const Icon(Icons.block_rounded, size: 16),
                                              label: const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  '🚫 Disable Version (Force Update Workers)',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              onPressed: () => _showDisableVersionDialog(item),
                                            )
                                          : ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFECFDF5),
                                                foregroundColor: const Color(0xFF16A34A),
                                                side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                              label: const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  '✓ Enable Version (Allow Normal Access)',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              onPressed: () => _toggleStatus(item, status: 'active'),
                                            ),
                                    ),

                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Card 2: Release & Download Configuration ──
                  _buildSectionCard(
                    icon: Icons.open_in_browser_rounded,
                    iconColor: AppColors.primary,
                    title: '2. Global Release & Default Link',
                    badgeText: 'GLOBAL CONFIG',
                    badgeColor: AppColors.primary,
                    subtitle:
                        'Default APK download URL and fallback version settings for all workers.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Default APK Download URL (Opens in Chrome / In-App Downloader) *',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _apkUrlController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'https://example.com/downloads/Worker_App.apk',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '💡 Enter any direct APK URL, Google Drive download link, or GitHub Releases URL.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Latest Release Version Name *',
                                      style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _latestVersionController,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 1.0.5',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                                  const Text('Latest Version Code (Build #) *',
                                      style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _latestVersionCodeController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 5',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFD97706), size: 18),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        const Text('Update Prompt Message',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 2,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Message shown to worker on update screen...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Release Notes / What\'s New',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _releaseNotesController,
                          maxLines: 3,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Bullet points explaining new features...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Saving Configurations...' : 'Save All Configurations',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveAllSettings,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
        ],
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
    Widget? trailingAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.bold),
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
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.35),
          ),
          if (trailingAction != null) ...[
            const SizedBox(height: 10),
            trailingAction,
          ],
          const Divider(color: Color(0xFFF1F5F9), height: 20),
          child,
        ],
      ),
    );
  }
}

