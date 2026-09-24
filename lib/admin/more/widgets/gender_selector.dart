import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../admin_profile.dart';

/// The three-way gender control on the profile form.
///
/// No MergeSemantics anywhere in here, and none may be put around it: these
/// are three real buttons, and merging them folds them into one node with a
/// label made of all three words and nothing to press. Each carries its own
/// selected state instead, which is what a screen reader announces as
/// "selected" on the one that is.
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Gender selected;
  final ValueChanged<Gender> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, gender) in Gender.values.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: _GenderButton(
              gender: gender,
              isSelected: gender == selected,
              onTap: () => onSelect(gender),
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: gender.label,
      button: true,
      selected: isSelected,
      // The label is already given above; without this the Text would arrive
      // as a child node saying the same word again.
      excludeSemantics: true,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.field,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: BorderSide(
            color: isSelected ? AppColors.transparent : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
            child: Center(
              child: Text(
                gender.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
