import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY'),
    appId: dotenv.get('FIREBASE_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    databaseURL: dotenv.get('FIREBASE_DATABASE_URL'),
  );
}
