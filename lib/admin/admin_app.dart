import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'admin_shell.dart';

/// Root of the admin panel. Kept separate from the user-facing app so the
/// login page can hand off to either one without them sharing state or theme.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shakti Saree — Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.admin,
      home: const AdminShell(),
    );
  }
}
