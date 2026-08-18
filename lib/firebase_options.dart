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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCRHw09FaJHHBceoelzvuNNCNPhqqmFPIE',
    appId: '1:1065560411366:web:40fa0c72adb8dec3a73f27',
    messagingSenderId: '1065560411366',
    projectId: 'vnb-grocery',
    authDomain: 'vnb-grocery.firebaseapp.com',
    storageBucket: 'vnb-grocery.firebasestorage.app',
    measurementId: 'G-932NZ75SEQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRHw09FaJHHBceoelzvuNNCNPhqqmFPIE',
    appId: '1:1065560411366:android:40fa0c72adb8dec3a73f27',
    messagingSenderId: '1065560411366',
    projectId: 'vnb-grocery',
    storageBucket: 'vnb-grocery.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRHw09FaJHHBceoelzvuNNCNPhqqmFPIE',
    appId: '1:1065560411366:ios:40fa0c72adb8dec3a73f27',
    messagingSenderId: '1065560411366',
    projectId: 'vnb-grocery',
    storageBucket: 'vnb-grocery.firebasestorage.app',
  );
}
