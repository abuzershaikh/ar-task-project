import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class ApkDownloader {
  static const String buyerApkUrl =
      'https://pub-aaf236e06e7346e5b925fe9d35132cc7.r2.dev/marketing.apk';

  static Future<void> downloadBuyerApk() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('downloadApk', [buyerApkUrl, 'ReviewsGateway.apk']);
        return;
      } catch (e) {
        debugPrint('window.downloadApk JS call failed: $e');
      }
    }

    final uri = Uri.parse(buyerApkUrl);
    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
  }
}
