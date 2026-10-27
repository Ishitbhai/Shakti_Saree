import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Add this import

import 'admin/data/providers/backend_providers.dart';
import 'firebase_options.dart';
import 'user/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Wrap your root widget with ProviderScope
  runApp(
    ProviderScope(
      // The admin panel reads and writes the real database. Left out, as in
      // the tests, it runs on its in-memory sample data instead.
      overrides: [
        firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
        firebaseAuthProvider.overrideWithValue(FirebaseAuth.instance),
      ],
      child: const ShaktiSaree(),
    ),
  );
}

class ShaktiSaree extends StatelessWidget {
  const ShaktiSaree({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shakti Saree',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
