import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CloudflareMediaService {
  static const String uploadUrl =
      'https://earnpost-media-worker.zestbizar.workers.dev/upload';

  /// Uploads an audio or media file to Cloudflare R2 storage bucket
  /// Returns the public CDN URL on success (e.g. https://earnpost-media-worker.zestbizar.workers.dev/audio/audio_xxx.m4a)
  static Future<String> uploadMediaFile(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final fileName = filePath.split(Platform.pathSeparator).last;
    final ext = fileName.split('.').last.toLowerCase();

    String mimeType = 'audio/m4a';
    if (ext == 'mp3') {
      mimeType = 'audio/mpeg';
    } else if (ext == 'wav') {
      mimeType = 'audio/wav';
    } else if (ext == 'aac') {
      mimeType = 'audio/aac';
    } else if (ext == 'ogg') {
      mimeType = 'audio/ogg';
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    debugPrint('[CloudflareMediaService] Uploading $fileName ($mimeType) to $uploadUrl...');

    try {
      final response = await dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: onProgress,
      );

      debugPrint('[CloudflareMediaService] Response: ${response.statusCode} => ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          var url = (data['url'] ?? data['publicUrl'])?.toString();
          if (url != null && url.isNotEmpty) {
            url = url.replaceAll(
              'https://media.earnpost.workers.dev',
              'https://earnpost-media-worker.zestbizar.workers.dev',
            );
            return url;
          }
        }
      }
      throw Exception('Upload failed (${response.statusCode}): ${response.data}');
    } on DioException catch (e) {
      debugPrint('[CloudflareMediaService] DioException: ${e.message} / ${e.response?.data}');
      final errMsg = e.response?.data?['error'] ?? e.message ?? 'Network error uploading to Cloudflare';
      throw Exception(errMsg);
    } catch (e) {
      debugPrint('[CloudflareMediaService] Exception: $e');
      rethrow;
    }
  }
}
