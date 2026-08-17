import 'package:flutter/material.dart';

void main() {
  runApp(const ShaktiSareeAdminApp());
}

/// Placeholder root. Once the design tokens land this gets pointed at
/// `lib/dev/token_preview.dart`, and later at the real router.
class ShaktiSareeAdminApp extends StatelessWidget {
  const ShaktiSareeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shakti Saree Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      // Light-only app — no dark theme is supplied, so this pins it
      // regardless of the device setting.
      themeMode: ThemeMode.light,
      home: const Placeholder(),
    );
  }
}
