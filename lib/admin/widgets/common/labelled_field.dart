import 'package:flutter/material.dart';

import '../../styles/app_spacing.dart';
import '../../styles/app_typography.dart';

/// A form control with its caption above it.
class LabelledField extends StatelessWidget {
  const LabelledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.x2),
        child,
      ],
    );
  }
}
