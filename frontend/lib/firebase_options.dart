import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// For Firebase JS SDK v7.20.0 and later, measurementId is optional
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyCKSFYFv-cVKJgK0514C0Z1bzJcIvYaIZQ",
      authDomain: "sunny-bunny-cafe.firebaseapp.com",
      projectId: "sunny-bunny-cafe",
      storageBucket: "sunny-bunny-cafe.firebasestorage.app",
      messagingSenderId: "407305985091",
      appId: "1:407305985091:web:c5493d90d68733dc0608f6",
      measurementId: "G-W8FB6X38KT",
    );
  }
}
