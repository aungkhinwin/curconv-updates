// Android-only Firebase configuration generated from the supplied google-services.json.
// Do not use these Android values for web or iOS; run flutterfire configure there.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase is configured for Android only. Run flutterfire configure for other platforms.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCcyfcSdCCaOSYYzEI_6I5S8ZRJcnHfDaE",
    appId: "1:745266527188:android:d4efb6afeab94992b67441",
    messagingSenderId: "745266527188",
    projectId: "curconvbackup-7709c",
    storageBucket: "curconvbackup-7709c.firebasestorage.app",
  );
}
