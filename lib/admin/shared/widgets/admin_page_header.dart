import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../admin_tab.dart';

/// Header used by the admin list screens: a back square, a centred title with
/// a count beneath it, and up to two actions on the right.
///
/// Blank squares stand in for whatever is missing, so the two sides weigh the
/// same and the title stays optically centred however many actions there are.
class AdminPageHeader extends ConsumerWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.secondaryAction,
    this.trailing,
  });

  final String title;
  final String subtitle;

  /// The screen's main action, at the far right.
  final AdminHeaderAction? action;

  /// A second action, sitting to the left of [action].
  ///
  /// Only where a screen genuinely has two — the header is not a toolbar, and
  /// the title has to stay readable between them.
  final AdminHeaderAction? secondaryAction;

  /// Something other than an action square at the far right — a badge, say.
  ///
  /// Takes the place of [action] and [secondaryAction] rather than sitting
  /// beside them. It may be any width, so the title is centred in what is
  /// left over rather than on the screen; a wide one pushes it along.
  final Widget? trailing;

  static const double squareSize = 40;

  static const double _actionGap = AppSpacing.x2;

  /// Leaves the screen by whichever route it has.
  ///
  /// A pushed screen pops. At the root of a tab there is nothing to pop, so
  /// back steps to the tab on the left instead.
  void _goBack(BuildContext context, WidgetRef ref) {
    if (Navigator.canPop(context)) {
      // maybePop, not pop: a screen guarding unsaved changes with a PopScope
      // has to get a say, and a plain pop would walk straight past it.
      Navigator.maybePop(context);
      return;
    }
    ref.read(adminTabProvider.notifier).back();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = trailing;
    final actions = <AdminHeaderAction>[
      if (custom == null) ...[?secondaryAction, ?action],
    ];

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
            onTap: () => _goBack(context, ref),
          ),
          // One blank square on the left for every action past the first, so
          // the two sides weigh the same and the title stays centred.
          for (var extra = 1; extra < actions.length; extra++) ...[
            const SizedBox(width: _actionGap),
            const SizedBox.square(dimension: squareSize),
          ],
          Expanded(
            child: Column(
              children: [
                Text(title, style: AppTypography.displaySmall),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          if (custom != null)
            custom
          else if (actions.isEmpty)
            const SizedBox.square(dimension: squareSize)
          else
            for (final (index, item) in actions.indexed) ...[
              if (index > 0) const SizedBox(width: _actionGap),
              AdminHeaderSquare(
                icon: item.icon,
                label: item.label,
                onTap: item.onTap,
              ),
            ],
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
