// File generated for CampusSOS — Safe Campus Companion.
// Follow README.md or run `flutterfire configure` to bind to your specific Firebase project.
// If configuring manually, replace the placeholder values below with your Firebase project credentials.

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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Placeholder credentials. Update these with your Firebase project settings
  // from https://console.firebase.google.com or by running `flutterfire configure`.

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAz5WRggRBvs9HovoWAkISipaiJrK-nacA',
    appId: '1:475182956596:web:3d7a4496ab433799f6ca61',
    messagingSenderId: '475182956596',
    projectId: 'campussos-14b1b',
    authDomain: 'campussos-14b1b.firebaseapp.com',
    storageBucket: 'campussos-14b1b.firebasestorage.app',
    measurementId: 'G-881W4SBNB5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbU564UQJ5ZWRZ3DuH8YfbDMXo80HMTjs',
    appId: '1:475182956596:android:5cf620bf824a76b9f6ca61',
    messagingSenderId: '475182956596',
    projectId: 'campussos-14b1b',
    storageBucket: 'campussos-14b1b.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBq9L42cO7ktVWaaYo6iltEteRxtIMAFcs',
    appId: '1:475182956596:ios:108fecf8f12cd5bcf6ca61',
    messagingSenderId: '475182956596',
    projectId: 'campussos-14b1b',
    storageBucket: 'campussos-14b1b.firebasestorage.app',
    iosBundleId: 'com.campussos.campusSos',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBq9L42cO7ktVWaaYo6iltEteRxtIMAFcs',
    appId: '1:475182956596:ios:108fecf8f12cd5bcf6ca61',
    messagingSenderId: '475182956596',
    projectId: 'campussos-14b1b',
    storageBucket: 'campussos-14b1b.firebasestorage.app',
    iosBundleId: 'com.campussos.campusSos',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAz5WRggRBvs9HovoWAkISipaiJrK-nacA',
    appId: '1:475182956596:web:f843fb89d8e32c89f6ca61',
    messagingSenderId: '475182956596',
    projectId: 'campussos-14b1b',
    authDomain: 'campussos-14b1b.firebaseapp.com',
    storageBucket: 'campussos-14b1b.firebasestorage.app',
    measurementId: 'G-M9SWP3VC6H',
  );
}
