import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String message;
  final String releaseNotes;

  const AppUpdateScreen({
    super.key,
    this.currentVersion = '1.0.0',
    this.latestVersion = '1.0.1',
    this.downloadUrl = 'https://raw.githubusercontent.com/abuzershaikh/ar-task-project/main/Worker_App_Release.apk',
    this.message = 'A new version of Task Reward Worker is available. Please update your app to continue.',
    this.releaseNotes = '• High paying new tasks\n• Real-time notifications with instant task redirect\n• Performance optimizations and bug fixes',
  });

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Update Ready';
  String? _downloadedFilePath;
  bool _downloadCompleted = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Open Download Link directly in Google Chrome / External Browser
  Future<void> _openDownloadInChrome() async {
    final link = widget.downloadUrl.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No download link configured by admin')),
      );
      return;
    }

    setState(() {
      _statusText = 'Opening Chrome / Browser to download update...';
    });

    try {
      final uri = Uri.parse(link);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('⚠️ Browser launch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open Chrome: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Direct In-App Download into Downloads folder
  Future<void> _startInAppDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.05;
      _statusText = 'Connecting to download server...';
      _downloadCompleted = false;
    });

    try {
      final uri = Uri.parse(widget.downloadUrl.trim());
      final request = http.Request('GET', uri);
      final response = await http.Client().send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLength = response.contentLength ?? 0;
        int receivedBytes = 0;
        final List<int> bytes = [];

        Directory? downloadDir;
        if (Platform.isAndroid) {
          final externalDir = Directory('/storage/emulated/0/Download');
          if (await externalDir.exists()) {
            downloadDir = externalDir;
          }
        }
        downloadDir ??= await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();

        final fileName = 'TaskReward_Worker_v${widget.latestVersion}.apk';
        final saveFile = File('${downloadDir.path}/$fileName');

        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;

          if (contentLength > 0) {
            final p = receivedBytes / contentLength;
            setState(() {
              _progress = p;
              final downloadedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
              final totalMb = (contentLength / (1024 * 1024)).toStringAsFixed(1);
              _statusText = 'Downloading: $downloadedMb MB / $totalMb MB (${(p * 100).toInt()}%)';
            });
          } else {
            setState(() {
              final downloadedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
              _statusText = 'Downloading: $downloadedMb MB...';
            });
          }
        }

        await saveFile.writeAsBytes(bytes);
        _downloadedFilePath = saveFile.path;

        setState(() {
          _isDownloading = false;
          _progress = 1.0;
          _downloadCompleted = true;
          _statusText = '✅ Download complete! Saved to Downloads.';
        });

        _installApk();
      } else {
        await _openDownloadInChrome();
      }
    } catch (e) {
      debugPrint('⚠️ In-app download error: $e. Opening Chrome instead.');
      await _openDownloadInChrome();
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFilePath != null && File(_downloadedFilePath!).existsSync()) {
      try {
        final result = await OpenFilex.open(_downloadedFilePath!);
        debugPrint('🎯 Install intent result: ${result.type} - ${result.message}');
      } catch (e) {
        debugPrint('⚠️ Error launching installer: $e');
        await _openDownloadInChrome();
      }
    } else {
      await _openDownloadInChrome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF04130D),
        body: Stack(
          children: [
            // Background ambient lighting
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38BDF8).withOpacity(0.1),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Pulsing Rocket / Update Icon ──
                      AnimatedBuilder(
                        animation: _animCtrl,
                        builder: (context, child) {
                          return Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                  Color(0xFF052E16),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withOpacity(0.3 + (_animCtrl.value * 0.3)),
                                  blurRadius: 24 + (_animCtrl.value * 12),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),

                      // ── Title ──
                      Text(
                        'Update Available!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Version Badges ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Current: v${widget.currentVersion}',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4)),
                            ),
                            child: Text(
                              'Latest: v${widget.latestVersion}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF22C55E),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Message Box ──
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Release Notes Card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF021B11),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF083320)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "What's New in this update:",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF59E0B),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF083320), height: 16),
                            Text(
                              widget.releaseNotes,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFCBD5E1),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── In-App Download Progress (if active) ──
                      if (_isDownloading || _downloadCompleted) ...[
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progress > 0 ? _progress : null,
                                backgroundColor: const Color(0xFF083320),
                                color: const Color(0xFF22C55E),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _statusText,
                              style: GoogleFonts.poppins(
                                color: _downloadCompleted ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: _downloadCompleted ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ],

                      // ── Primary Button: Download via Chrome / Browser ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.open_in_browser_rounded, size: 22),
                          label: Text(
                            'Download Update (Chrome)',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _openDownloadInChrome,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Secondary Action: In-App Download / Install ──
                      if (_downloadCompleted)
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF22C55E),
                              side: const BorderSide(color: Color(0xFF22C55E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.install_mobile_rounded, size: 18),
                            label: Text(
                              'Install Downloaded APK',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _installApk,
                          ),
                        )
                      else if (!_isDownloading)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF94A3B8),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(
                              'Direct Download in Background',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            onPressed: _startInAppDownload,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
