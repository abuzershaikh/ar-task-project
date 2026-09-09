import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../core/network/cloudflare_media_service.dart';

class VoiceGuideStudioCard extends StatefulWidget {
  final TextEditingController audioUrlController;
  final VoidCallback? onChanged;

  const VoiceGuideStudioCard({
    super.key,
    required this.audioUrlController,
    this.onChanged,
  });

  @override
  State<VoiceGuideStudioCard> createState() => _VoiceGuideStudioCardState();
}

class _VoiceGuideStudioCardState extends State<VoiceGuideStudioCard> {
  // Recorder
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordDurationSeconds = 0;
  Timer? _recordTimer;

  // Uploading
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = '';

  // Audio Player
  AudioPlayer? _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isBuffering = false;

  // Manual URL visibility
  bool _showManualUrl = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    widget.audioUrlController.addListener(_onUrlControllerChanged);
  }

  void _onUrlControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.audioUrlController.removeListener(_onUrlControllerChanged);
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AUDIO PLAYER METHODS
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _initAudioPlayer() async {
    if (_audioPlayer != null) return;
    _audioPlayer = AudioPlayer();

    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _audioPlayer!.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer!.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });

    _audioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  Future<void> _toggleAudioPreview() async {
    final url = widget.audioUrlController.text.trim();
    if (url.isEmpty) return;

    await _initAudioPlayer();

    if (_playerState == PlayerState.playing) {
      await _audioPlayer!.pause();
    } else if (_playerState == PlayerState.paused) {
      await _audioPlayer!.resume();
    } else {
      try {
        setState(() => _isBuffering = true);
        await _audioPlayer!.play(UrlSource(url));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio Preview Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isBuffering = false);
      }
    }
  }

  Future<void> _seekPreview(double value) async {
    if (_audioPlayer != null && _duration.inMilliseconds > 0) {
      final newPos = Duration(
        milliseconds: (value * _duration.inMilliseconds).round(),
      );
      await _audioPlayer!.seek(newPos);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // VOICE RECORDING METHODS
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _startRecording() async {
    // 1. Permission check
    final micStatus = await Permission.microphone.request();
    if (micStatus.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record voice.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    try {
      // 2. Stop player if playing
      if (_playerState == PlayerState.playing) {
        await _audioPlayer?.stop();
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_guide_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordDurationSeconds = 0;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _recordDurationSeconds++);
        // Cap max recording at 3 minutes (180s)
        if (_recordDurationSeconds >= 180) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start recording: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }

    setState(() => _isRecording = false);

    if (path != null && File(path).existsSync()) {
      await _uploadToCloudflare(path);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AUDIO FILE PICKER
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await _uploadToCloudflare(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick audio file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CLOUDFLARE R2 UPLOAD
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _uploadToCloudflare(String localFilePath) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusText = 'Uploading audio...';
    });

    try {
      final publicUrl = await CloudflareMediaService.uploadMediaFile(
        localFilePath,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      widget.audioUrlController.text = publicUrl;
      widget.onChanged?.call();

      // Reset audio player to load new file
      await _audioPlayer?.stop();
      _duration = Duration.zero;
      _position = Duration.zero;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Voice Guide uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Upload failed: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatusText = '';
        });
      }
    }
  }

  void _clearAudio() {
    _audioPlayer?.stop();
    setState(() {
      widget.audioUrlController.clear();
      _duration = Duration.zero;
      _position = Duration.zero;
      _playerState = PlayerState.stopped;
    });
    widget.onChanged?.call();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatSeconds(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = widget.audioUrlController.text.trim().isNotEmpty;
    final isPlaying = _playerState == PlayerState.playing;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAudio
              ? Colors.cyanAccent.withOpacity(0.5)
              : Colors.indigoAccent.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Status Header ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.cyanAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Instruction Studio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Voice Cloud Storage',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.redAccent.withOpacity(0.2)
                      : (hasAudio
                          ? Colors.greenAccent.withOpacity(0.15)
                          : Colors.white10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isRecording
                        ? Colors.redAccent
                        : (hasAudio ? Colors.greenAccent : Colors.white24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRecording) ...[
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      _isRecording
                          ? 'RECORDING (${_formatSeconds(_recordDurationSeconds)})'
                          : (hasAudio ? 'VOICE ATTACHED' : 'NO VOICE GUIDE'),
                      style: TextStyle(
                        color: _isRecording
                            ? Colors.redAccent
                            : (hasAudio ? Colors.greenAccent : Colors.white60),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Uploading Progress Indicator ──────────────────────────────────
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _uploadStatusText,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Action Buttons Row (Record / Upload / Clear) ───────────────────
          if (!_isUploading) ...[
            Row(
              children: [
                // Record Voice Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.redAccent
                          : const Color(0xFF312E81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      _isRecording
                          ? Icons.stop_circle_rounded
                          : Icons.mic_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _isRecording ? 'Stop & Save' : 'Record Voice',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed:
                        _isRecording ? _stopRecording : _startRecording,
                  ),
                ),
                const SizedBox(width: 8),

                // Upload Audio File Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.upload_file_rounded,
                      size: 16,
                      color: Colors.cyanAccent,
                    ),
                    label: const Text(
                      'Upload Audio',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isRecording ? null : _pickAudioFile,
                  ),
                ),

                // Clear Button (if audio attached)
                if (hasAudio && !_isRecording) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.15),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: 'Remove Voice Guide',
                    onPressed: _clearAudio,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── In-App Audio Preview Player (When audio is attached) ───────────
          if (hasAudio && !_isRecording) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Play / Pause Button
                      GestureDetector(
                        onTap: _toggleAudioPreview,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _isBuffering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0F172A),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: const Color(0xFF0F172A),
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Seek Slider & Timestamps
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                activeTrackColor: Colors.cyanAccent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: (_duration.inMilliseconds > 0)
                                    ? (_position.inMilliseconds /
                                            _duration.inMilliseconds)
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                                onChanged: (val) => _seekPreview(val),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _duration.inSeconds > 0
                                        ? _formatDuration(_duration)
                                        : 'Listen Preview',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Toggle Direct URL / Advanced view ──────────────────────────────
          InkWell(
            onTap: () => setState(() => _showManualUrl = !_showManualUrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showManualUrl
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _showManualUrl
                        ? 'Hide Direct Cloudflare URL'
                        : 'View / Edit Direct Audio URL',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showManualUrl) ...[
            const SizedBox(height: 6),
            TextField(
              controller: widget.audioUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              onChanged: (_) {
                widget.onChanged?.call();
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Cloudflare Audio Stream URL',
                labelStyle:
                    const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                hintText:
                    'https://earnpost-media-worker.zestbizar.workers.dev/audio/...',
                hintStyle:
                    const TextStyle(color: Colors.white30, fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  color: Colors.cyanAccent,
                  size: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
