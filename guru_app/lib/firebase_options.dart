import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAx2T9actUy6mR_t0YiIl4Pt6Dzq6GPTMY',
    appId: '1:395213204399:android:4f0d2938467008596d5d5a',
    messagingSenderId: '395213204399',
    projectId: 'wtf-gym-2b12f',
    storageBucket: 'wtf-gym-2b12f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAx2T9actUy6mR_t0YiIl4Pt6Dzq6GPTMY',
    appId: '1:395213204399:android:4f0d2938467008596d5d5a',
    messagingSenderId: '395213204399',
    projectId: 'wtf-gym-2b12f',
    storageBucket: 'wtf-gym-2b12f.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAx2T9actUy6mR_t0YiIl4Pt6Dzq6GPTMY',
    appId: '1:395213204399:android:4f0d2938467008596d5d5a',
    messagingSenderId: '395213204399',
    projectId: 'wtf-gym-2b12f',
    storageBucket: 'wtf-gym-2b12f.firebasestorage.app',
  );
}
