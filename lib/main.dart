import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Add this import

import 'user/screens/splash_screen.dart';

void main() {
  // 2. Wrap your root widget with ProviderScope
  runApp(const ProviderScope(child: ShaktiSaree()));
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
