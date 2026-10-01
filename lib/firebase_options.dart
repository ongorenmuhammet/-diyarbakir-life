// File generated for FlutterFire configuration.
// Diyarbakır Yerel Yaşam Firebase Options

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLWhjy-K0Wtoz5HJ3NvKDa3v7H4msamzg',
    appId: '1:624505734662:android:dea589bc29db1e456ba587',
    messagingSenderId: '624505734662',
    projectId: 'diyarbakir-yerel-yasam',
    storageBucket: 'diyarbakir-yerel-yasam.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBH5O1-LFaQA0V84Wk4qoEv6CNO9fajGqg',
    appId: '1:624505734662:ios:d02587d2e3f47ef16ba587',
    messagingSenderId: '624505734662',
    projectId: 'diyarbakir-yerel-yasam',
    storageBucket: 'diyarbakir-yerel-yasam.firebasestorage.app',
    iosBundleId: 'com.diyarbakir.yerelyasam.diyarbakirYerelYasam',
  );
}
