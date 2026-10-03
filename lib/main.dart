import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // OPTIONAL: Only use emulator if explicitly requested or if you are running it.
  // If you are NOT using 'firebase emulators:start', keep this false.
  bool useEmulator = false; 
  
  if (useEmulator && kDebugMode) {
    try {
      const String host = String.fromEnvironment('FIREBASE_EMULATOR_HOST',
          defaultValue: '10.0.2.2');
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      print('Using Firestore Emulator at $host:8080');
    } catch (e) {
      print('Error connecting to Firestore emulator: $e');
    }
  }

  // Temporarily disabling App Check to rule out configuration issues
  /*
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  */

  runApp(const MyApp());
}
