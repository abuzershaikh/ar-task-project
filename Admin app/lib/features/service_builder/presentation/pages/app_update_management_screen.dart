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
  final TextEditingController _newVersionController = TextEditingController();
  final TextEditingController _latestVersionController = TextEditingController(text: '1.0.1');
  final TextEditingController _apkUrlController = TextEditingController(text: 'https://raw.githubusercontent.com/abuzershaikh/ar-task-project/main/Worker_App_Release.apk');
  final TextEditingController _messageController = TextEditingController(text: 'A new version of Task Reward Worker is available. Please update your app to continue.');
  final TextEditingController _releaseNotesController = TextEditingController(text: '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security');

  List<String> _updateList = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAddingVersion = false;

  @override
  void initState() {
    super.initState();
    _fetchUpdateSettings();
  }

  @override
  void dispose() {
    _newVersionController.dispose();
    _latestVersionController.dispose();
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
          _updateList = (s['updateList'] as List? ?? []).map((e) => e.toString()).toList();
          _latestVersionController.text = (s['latestVersion'] ?? '1.0.1').toString();
          _apkUrlController.text = (s['apkDownloadUrl'] ?? '').toString();
          _messageController.text = (s['updateMessage'] ?? '').toString();
          _releaseNotesController.text = (s['releaseNotes'] ?? '').toString();
        });
      }
    } catch (e) {
      debugPrint('Error fetching update settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addVersion() async {
    final v = _newVersionController.text.trim();
    if (v.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a version number (e.g. 1.0.0 or 1)')),
      );
      return;
    }

    if (_updateList.contains(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Version "$v" is already in the update list')),
      );
      return;
    }

    setState(() => _isAddingVersion = true);
    try {
      final dio = getIt<DioClient>();
      final resp = await dio.post('/admin/settings/app-updates/add-version', data: {'version': v});
      final updatedList = resp.data?['updateList'] as List?;
      setState(() {
        if (updatedList != null) {
          _updateList = updatedList.map((e) => e.toString()).toList();
        } else {
          _updateList.add(v);
        }
        _newVersionController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Version "$v" added to forced update list!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _updateList.add(v));
      _newVersionController.clear();
      _saveAllSettings();
    } finally {
      if (mounted) setState(() => _isAddingVersion = false);
    }
  }

  Future<void> _removeVersion(String version) async {
    try {
      final dio = getIt<DioClient>();
      await dio.delete('/admin/settings/app-updates/remove-version/$version');
      setState(() {
        _updateList.remove(version);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Version "$version" removed from update list'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _updateList.remove(version);
      });
      _saveAllSettings();
    }
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isSaving = true);
    try {
      final dio = getIt<DioClient>();
      await dio.post('/admin/settings/app-updates', data: {
        'updateList': _updateList,
        'latestVersion': _latestVersionController.text.trim(),
        'apkDownloadUrl': _apkUrlController.text.trim(),
        'updateMessage': _messageController.text.trim(),
        'releaseNotes': _releaseNotesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ App Update & Versioning configurations saved!'),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'App Version & Updates',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchUpdateSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Info Banner ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan.withOpacity(0.15), Colors.purple.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Update & Version Control',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Add any version to the update list below. When a worker opens the app with that version, they will immediately see the Update Available screen with a direct APK download button.',
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Card 1: Add Version to Update List ──
                  _buildSectionCard(
                    icon: Icons.list_alt_rounded,
                    iconColor: Colors.amberAccent,
                    title: '1. Forced Update Versions List',
                    badgeText: '${_updateList.length} VERSIONS',
                    badgeColor: Colors.amberAccent,
                    subtitle:
                        'Any app version listed here will be blocked from regular access and prompted to download the latest update.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newVersionController,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Enter version (e.g. 1.0.0 or 1)',
                                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                  prefixIcon: const Icon(Icons.tag_rounded, color: Colors.amberAccent, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isAddingVersion
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _isAddingVersion ? null : _addVersion,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // List of versions
                        if (_updateList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Center(
                              child: Text(
                                'No versions currently in forced update list. All worker app versions can access normally.',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _updateList.map((v) {
                              return Container(
                                padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.block_rounded, color: Colors.redAccent, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'v$v',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                      tooltip: 'Remove version',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _removeVersion(v),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Card 2: Release & Download Configuration ──
                  _buildSectionCard(
                    icon: Icons.cloud_download_rounded,
                    iconColor: Colors.cyanAccent,
                    title: '2. Latest Release Information & APK URL',
                    badgeText: 'DOWNLOAD LINK',
                    badgeColor: Colors.cyanAccent,
                    subtitle:
                        'The worker app will download the update directly from this APK link and prompt installation in the Downloads folder.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Latest Release Version Name *',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _latestVersionController,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. 1.0.1 or 2.0.0',
                            prefixIcon: const Icon(Icons.verified_rounded, color: Colors.cyanAccent, size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Direct APK Download URL *',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _apkUrlController,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'https://.../Worker_App_Release.apk',
                            prefixIcon: const Icon(Icons.link_rounded, color: Colors.cyanAccent, size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Update Prompt Message',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Message shown to worker on update screen...',
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text('Release Notes / What\'s New',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _releaseNotesController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Bullet points explaining new features...',
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Saving Configurations...' : 'Save Update Configurations',
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

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
            style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.35),
          ),
          const Divider(color: Colors.white12, height: 20),
          child,
        ],
      ),
    );
  }
}
