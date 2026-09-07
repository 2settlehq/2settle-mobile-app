import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBrjCjdNSXU8lfMHwYTvdj0zLaBRS5rapQ",
            authDomain: "settle-405f1.firebaseapp.com",
            projectId: "settle-405f1",
            storageBucket: "settle-405f1.appspot.com",
            messagingSenderId: "532037830967",
            appId: "1:532037830967:web:e1b534da3f2220c2ea32b2",
            measurementId: "G-MTJX1Y9ZCZ"));
  } else {
    await Firebase.initializeApp();
  }
}
