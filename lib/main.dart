import 'package:flutter/material.dart';

import 'admin/dashboard/presentation/dashboard_screen.dart';
import 'core/theme/app_theme.dart';

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
      // TEMPORARY: points straight at the dashboard until the router lands.
      home: const DashboardScreen(),
    );
  }
}
