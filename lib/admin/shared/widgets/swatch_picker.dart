import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'swatches.dart';

/// Row of tappable tints, for choosing the colour that stands in for artwork
/// nobody has uploaded.
class SwatchPicker extends StatelessWidget {
  const SwatchPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  /// Straight from the design; not on the base-4 scale.
  static const double _size = 36;
  static const double _ring = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < Swatches.count; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.x3),
          Semantics(
            label: 'Placeholder colour ${index + 1}',
            button: true,
            selected: index == selected,
            child: InkWell(
              onTap: () => onSelect(index),
              customBorder: const CircleBorder(),
              child: Container(
                height: _size,
                width: _size,
                decoration: BoxDecoration(
                  color: Swatches.at(index),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index == selected
                        ? AppColors.textDark
                        : AppColors.border,
                    width: index == selected ? _ring : 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
