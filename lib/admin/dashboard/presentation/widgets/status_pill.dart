import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tinted_pill.dart';
import '../../domain/dashboard_order.dart';

/// Status chip for an order.
///
/// The status-to-colour mapping lives here rather than on [OrderStatus] so the
/// domain layer stays free of anything visual.
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
    return TintedPill(
      label: status.label,
      background: palette.background,
      foreground: palette.foreground,
    );
  }
}
