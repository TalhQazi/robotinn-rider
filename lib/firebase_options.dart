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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8Dbpbk_IPYGw0gRKuSDLDsTmm8vs1xbc',
    appId: '1:301557654113:web:0fe154ff4ce2e9c13b1ad2',
    messagingSenderId: '301557654113',
    projectId: 'robotin-2a51b',
    authDomain: 'robotin-2a51b.firebaseapp.com',
    storageBucket: 'robotin-2a51b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8Dbpbk_IPYGw0gRKuSDLDsTmm8vs1xbc',
    appId: '1:301557654113:android:0fe154ff4ce2e9c13b1ad2',
    messagingSenderId: '301557654113',
    projectId: 'robotin-2a51b',
    storageBucket: 'robotin-2a51b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8Dbpbk_IPYGw0gRKuSDLDsTmm8vs1xbc',
    appId: '1:301557654113:ios:0fe154ff4ce2e9c13b1ad2',
    messagingSenderId: '301557654113',
    projectId: 'robotin-2a51b',
    storageBucket: 'robotin-2a51b.firebasestorage.app',
    iosBundleId: 'com.robotinnriderapp',
  );
}
