import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

/// Pushed from the More tab, so it carries its own app bar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const PagePlaceholder(
        title: 'Settings',
        note: 'Store profile, admin accounts and app preferences go here.',
      ),
    );
  }
}
