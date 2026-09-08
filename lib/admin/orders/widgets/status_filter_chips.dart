import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/models/order_status.dart';

/// Horizontal row of status filters above the orders list.
///
/// Already scrolls, so the full set of statuses fits however narrow the
/// screen is — chips run off the right edge rather than being dropped.
class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.statuses,
    required this.selected,
    required this.onSelect,
    this.allLabel = 'All',
  });

  final List<OrderStatus> statuses;

  /// The chosen status, or null for [allLabel] — every order, unfiltered.
  final OrderStatus? selected;

  /// Called with null when the 'All' chip is tapped.
  final ValueChanged<OrderStatus?> onSelect;

  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.x2),
            child: _Chip(
              label: allLabel,
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
          ),
          for (final status in statuses)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x2),
              child: _Chip(
                label: status.label,
                selected: status == selected,
                onTap: () => onSelect(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillRadius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x2,
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textGrey,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
