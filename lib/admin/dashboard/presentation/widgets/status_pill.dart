import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/dashboard_order.dart';

/// Small rounded chip showing an order's status.
///
/// The status-to-colour mapping lives here rather than on [OrderStatus] so
/// the domain layer stays free of anything visual.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final OrderStatus status;

  ({Color background, Color foreground}) get _palette => switch (status) {
    OrderStatus.isNew => (
      background: AppColors.tintMaroon,
      foreground: AppColors.primary,
    ),
    OrderStatus.packed => (
      background: AppColors.warningBg,
      foreground: AppColors.warning,
    ),
    OrderStatus.shipped => (
      background: AppColors.infoBg,
      foreground: AppColors.info,
    ),
    OrderStatus.delivered => (
      background: AppColors.successBg,
      foreground: AppColors.success,
    ),
    OrderStatus.cancelled => (
      background: AppColors.errorBg,
      foreground: AppColors.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final palette = _palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        status.label,
        style: AppTypography.pill.copyWith(color: palette.foreground),
      ),
    );
  }
}
