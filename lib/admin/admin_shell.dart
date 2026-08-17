import 'package:flutter/material.dart';

import 'admin_destinations.dart';
import 'widgets/admin_app_bar.dart';

/// Frame around the admin tabs: app bar on top, bottom navigation below.
///
/// Tab screens are kept alive in an [IndexedStack] so scroll position and any
/// in-progress form input survive switching tabs — expected behaviour on a
/// phone, where tabs get switched constantly.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: adminTabs[_selectedIndex].label),
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final tab in adminTabs) tab.screenBuilder()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          for (final tab in adminTabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
