import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcYzLuzmqkP14OvY2vot0SYuOCZbEB3o4',
    appId: '1:311090572825:web:745149609214b2d8684488',
    messagingSenderId: '311090572825',
    projectId: 'taskz-87679',
    authDomain: 'taskz-87679.firebaseapp.com',
    storageBucket: 'taskz-87679.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcYzLuzmqkP14OvY2vot0SYuOCZbEB3o4',
    appId: '1:311090572825:android:745149609214b2d8684488',
    messagingSenderId: '311090572825',
    projectId: 'taskz-87679',
    storageBucket: 'taskz-87679.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcYzLuzmqkP14OvY2vot0SYuOCZbEB3o4',
    appId: '1:311090572825:ios:745149609214b2d8684488',
    messagingSenderId: '311090572825',
    projectId: 'taskz-87679',
    storageBucket: 'taskz-87679.firebasestorage.app',
    iosBundleId: 'com.buy.taskpost.marketing_pro',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBcYzLuzmqkP14OvY2vot0SYuOCZbEB3o4',
    appId: '1:311090572825:ios:745149609214b2d8684488',
    messagingSenderId: '311090572825',
    projectId: 'taskz-87679',
    storageBucket: 'taskz-87679.firebasestorage.app',
    iosBundleId: 'com.buy.taskpost.marketing_pro',
  );
}
