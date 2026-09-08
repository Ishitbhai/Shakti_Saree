import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A button's label, or a spinner in its place while that button is the one
/// waiting on the server.
///
/// Shared by the action bar and the transition sheets so a request looks the
/// same wherever it is started from.
class BusyLabel extends StatelessWidget {
  const BusyLabel({super.key, required this.label, required this.busy});

  final String label;
  final bool busy;

  /// Sized to sit inside a button without changing its height.
  static const double _spinner = 18;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(label);

    return Semantics(
      label: '$label in progress',
      child: const SizedBox(
        height: _spinner,
        width: _spinner,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          // Matches the disabled foreground the button is wearing anyway.
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
