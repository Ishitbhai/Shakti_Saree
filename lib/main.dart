import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin/dashboard/presentation/dashboard_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the system bars so the maroon header runs to the top of the
  // screen instead of sitting under a tinted status-bar band.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      // Light glyphs, because the header behind them is dark.
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
