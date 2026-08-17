import 'package:flutter/material.dart';

import '../widgets/page_placeholder.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'Settings',
      note: 'Store profile, admin accounts and app preferences go here.',
    );
  }
}
