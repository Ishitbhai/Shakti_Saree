import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../styles/app_theme.dart';

/// Puts everything below it in the admin's colours: [AppTheme.brandOver],
/// laid over whatever theme the app is running.
///
/// The admin shell wears it, and `AdminRoute` puts every admin page under it.
/// Dialogs, sheets, menus and pickers come along on their own, since they
/// carry the theme of the screen that opens them.
class AdminTheme extends StatelessWidget {
  const AdminTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.brandOver(Theme.of(context));

    return Theme(
      data: theme,
      // A nested Theme keeps the app's Cupertino colours, which iOS reads for
      // its text-selection handles; this gives it the admin's.
      child: CupertinoTheme(
        data: MaterialBasedCupertinoThemeData(materialTheme: theme),
        child: child,
      ),
    );
  }
}
