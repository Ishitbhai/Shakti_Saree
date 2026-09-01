import 'package:flutter/material.dart';
import 'package:shakti_saree/user/screens/checkout_screen.dart';

void main() {
  runApp(const ShaktiSaree());
}

/// Placeholder root. Once the design tokens land this gets pointed at
/// `lib/dev/token_preview.dart`, and later at the real router.
class ShaktiSaree extends StatelessWidget {
  const ShaktiSaree({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shakti Saree',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      // Light-only app — no dark theme is supplied, so this pins it
      // regardless of the device setting.
      themeMode: ThemeMode.light,
      home: const CheckoutScreen(),
    );
  }
}
