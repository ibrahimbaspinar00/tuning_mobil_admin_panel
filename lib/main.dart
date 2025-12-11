import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'web_admin_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  runApp(const WebAdminApp());
}
