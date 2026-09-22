import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Manages local disk caching for support chat images and audio voice notes.
/// Automatically purges any media older than 30 days (1 month).
class SupportMediaCache {
  static final SupportMediaCache instance = SupportMediaCache._internal();
  SupportMediaCache._internal();

  Directory? _cacheDir;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      return _cacheDir!;
    }
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/support_chat_media');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  /// Generates a safe alphanumeric filename based on URL hash and extension
  String _getFileName(String url) {
    // Preserve extension if present (.png, .jpg, .m4a, .mp3, etc.)
    String ext = '';
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final path = uri.path.toLowerCase();
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        ext = '.jpg';
      } else if (path.endsWith('.png')) {
        ext = '.png';
      } else if (path.endsWith('.webp')) {
        ext = '.webp';
      } else if (path.endsWith('.m4a')) {
        ext = '.m4a';
      } else if (path.endsWith('.mp3')) {
        ext = '.mp3';
      } else if (path.endsWith('.aac')) {
        ext = '.aac';
      }
    }

    final bytes = utf8.encode(url);
    final hash = bytes.fold<int>(0, (prev, elem) => (prev * 31 + elem) & 0x7FFFFFFF);
    final safeUrl = url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final prefix = safeUrl.length > 20 ? safeUrl.substring(safeUrl.length - 20) : safeUrl;
    return 'cache_${hash}_$prefix$ext';
  }

  /// Checks if file exists in cache; if so, returns local File without network call.
  /// If not cached, downloads once, saves to disk, and returns local File.
  Future<File?> getOrDownloadMedia(String url) async {
    if (url.isEmpty) return null;

    try {
      final dir = await _getCacheDirectory();
      final fileName = _getFileName(url);
      final file = File('${dir.path}/$fileName');

      if (await file.exists() && (await file.length()) > 0) {
        // Touch last modified time so it stays active
        try {
          await file.setLastModified(DateTime.now());
        } catch (_) {}
        debugPrint('[SupportMediaCache] HIT from disk: ${file.path}');
        return file;
      }

      // Download from network
      debugPrint('[SupportMediaCache] MISS: Downloading from $url');
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(res.bodyBytes, flush: true);
        debugPrint('[SupportMediaCache] Saved to disk (${res.bodyBytes.length} bytes): ${file.path}');
        return file;
      }
    } catch (e) {
      debugPrint('[SupportMediaCache] Error caching media: $e');
    }
    return null;
  }

  /// Automatically purges media files older than 30 days (1 month)
  Future<void> purgeExpiredCache() async {
    try {
      final dir = await _getCacheDirectory();
      if (!await dir.exists()) return;

      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      int purgedCount = 0;

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(oneMonthAgo)) {
            await entity.delete();
            purgedCount++;
          }
        }
      }

      if (purgedCount > 0) {
        debugPrint('[SupportMediaCache] Purged $purgedCount expired media files (>30 days old).');
      }
    } catch (e) {
      debugPrint('[SupportMediaCache] Purge error: $e');
    }
  }
}
