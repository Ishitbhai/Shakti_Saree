import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'dev/token_preview.dart';

void main() {
  runApp(const ShaktiSareeAdminApp());
}

class ShaktiSareeAdminApp extends StatelessWidget {
  const ShaktiSareeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shakti Saree Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Light-only app — no dark theme is supplied, so this pins it
      // regardless of the device setting.
      themeMode: ThemeMode.light,
      // TEMPORARY: points at the token preview until the router lands.
      home: const TokenPreview(),
    );
  }
}
