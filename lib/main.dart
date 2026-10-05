import 'package:flutter/material.dart';
import 'package:shakti_saree/user/screens/splash_screen.dart';

void main() {
  runApp(const ShaktiSaree());
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