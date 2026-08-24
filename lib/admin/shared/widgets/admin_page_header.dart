import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Header used by the admin list screens: a back square, a centred title with
/// a count beneath it, and an optional action on the right.
///
/// When there is no [action] an invisible square takes its place, so the title
/// stays optically centred.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final AdminHeaderAction? action;

  static const double squareSize = 40;

  @override
  Widget build(BuildContext context) {
    final trailing = action;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x4,
        AppSpacing.x5,
        AppSpacing.x2,
      ),
      child: Row(
        children: [
          AdminHeaderSquare(
            icon: Icons.arrow_back,
            label: 'Back',
            // Only pops when this screen was pushed; inside the tab shell
            // there is nothing to go back to.
            onTap: Navigator.canPop(context)
                ? () => Navigator.pop(context)
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: AppTypography.displaySmall),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          if (trailing == null)
            const SizedBox.square(dimension: squareSize)
          else
            AdminHeaderSquare(
              icon: trailing.icon,
              label: trailing.label,
              onTap: trailing.onTap,
            ),
        ],
      ),
    );
  }
}

/// The right-hand action of an [AdminPageHeader].
class AdminHeaderAction {
  const AdminHeaderAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Bordered square icon button used at both ends of the header.
class AdminHeaderSquare extends StatelessWidget {
  const AdminHeaderSquare({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AdminPageHeader.squareSize,
            width: AdminPageHeader.squareSize,
            child: Icon(icon, size: 20, color: AppColors.textDark),
          ),
        ),
      ),
    );
  }
}
