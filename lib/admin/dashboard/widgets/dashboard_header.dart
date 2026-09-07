import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

/// Curved maroon block at the top of the admin dashboard.
///
/// Presentational only — every value arrives through the constructor.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.height,
    this.adminName = 'Admin',
    this.storeName = 'Shakti Saree',
    this.onAvatarTap,
  });

  /// Exact block height. Owned by [DashboardScreen], which also owns the card
  /// overlap — the two only make sense together, so neither is declared here.
  final double height;

  final String adminName;
  final String storeName;
  final VoidCallback? onAvatarTap;

  static const double _avatarSize = 38;

  @override
  Widget build(BuildContext context) {
    // Status bar height varies with the notch; read it rather than assuming.
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x5,
        topInset + AppSpacing.x4,
        AppSpacing.x5,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // Top-aligned, in reading order. The leftover space at the bottom is
        // the runway the cards land on — nothing may push into it.
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Eyebrow(),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Welcome back, $adminName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              _Avatar(name: adminName, onTap: onAvatarTap),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            '$storeName  •  ${Formatters.date(DateTime.now())}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnPrimarySoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decorative: the adjacent text already carries the meaning.
        const ExcludeSemantics(
          child: Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: AppColors.accentLight,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'ADMIN PANEL'.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.overline.copyWith(
              color: AppColors.accentLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.onTap});

  final String name;
  final VoidCallback? onTap;

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Admin profile',
      button: true,
      child: Material(
        color: AppColors.accent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            height: DashboardHeader._avatarSize,
            width: DashboardHeader._avatarSize,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  _initial,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.textOnAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
