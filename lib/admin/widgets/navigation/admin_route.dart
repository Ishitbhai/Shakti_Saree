import 'package:flutter/material.dart';

import '../common/admin_theme.dart';

/// The route every admin page is pushed with: a [MaterialPageRoute] that puts
/// the page under [AdminTheme].
///
/// A pushed page sits beside the shell in the navigator, not inside it, so it
/// inherits the app's theme rather than the shell's — Material's default
/// purple. The one push in the admin that must stay a plain
/// [MaterialPageRoute] is the logout, which hands back to the customer side.
class AdminRoute<T> extends MaterialPageRoute<T> {
  AdminRoute({required super.builder});

  @override
  Widget buildContent(BuildContext context) {
    // The page builds below the theme, so its own context sees the admin's.
    return AdminTheme(child: Builder(builder: builder));
  }
}
