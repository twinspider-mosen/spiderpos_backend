import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

class FirebaseConfig {
  static Firestore? _firestore;

  static Firestore get db {
    if (_firestore == null) {
      throw StateError(
        'Firebase not initialized. Call FirebaseConfig.initialize() first.',
      );
    }
    return _firestore!;
  }

  static Firestore get firestore => db;

  static Future<Firestore> initialize() async {
    if (_firestore != null) {
      return _firestore!;
    }

    if (File('.env').existsSync()) {
      load('.env');
    }

    final projectId = env['FIREBASE_PROJECT_ID'] ??
        Platform.environment['FIREBASE_PROJECT_ID'];

    final credentialsPath = env['GOOGLE_APPLICATION_CREDENTIALS'] ??
        Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];

    if (projectId == null || projectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID environment variable is missing.');
    }

    if (credentialsPath == null || credentialsPath.isEmpty) {
      throw StateError(
        'GOOGLE_APPLICATION_CREDENTIALS environment variable is missing.',
      );
    }

    final credentialsFile = File(credentialsPath);
    if (!credentialsFile.existsSync()) {
      throw StateError(
        'Firebase service account file not found at: ${credentialsFile.absolute.path}',
      );
    }

    final settings = Settings(
      projectId: projectId,
      credential: Credential.fromServiceAccount(credentialsFile),
    );

    _firestore = Firestore(settings: settings);
    return _firestore!;
  }
}
