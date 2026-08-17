import 'package:flutter/material.dart';

import 'admin_destinations.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

/// Frame around every admin screen: sidebar + top bar + the active screen.
///
/// Above [_wideBreakpoint] the sidebar is permanent; below it, it collapses
/// into a drawer opened from the top bar's menu button.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  static const double _wideBreakpoint = 1100;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AdminShell._wideBreakpoint;
    final destination = adminDestinations[_selectedIndex];

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              width: 260,
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onSelect: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.of(context).pop();
                },
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onSelect: (index) => setState(() => _selectedIndex = index),
            ),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  title: destination.label,
                  showMenuButton: !isWide,
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: destination.screenBuilder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
