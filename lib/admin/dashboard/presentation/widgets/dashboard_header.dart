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
    this.adminName = 'Admin',
    this.storeName = 'Shakti Saree',
    this.onAvatarTap,
  });

  final String adminName;
  final String storeName;
  final VoidCallback? onAvatarTap;

  /// Design height. A minimum rather than a fixed size so the block grows
  /// instead of clipping when the platform text scale is turned up.
  static const double minHeight = 200;

  /// How far the stat grid is lifted into this block. Owned here, next to the
  /// padding that reserves room for it — [DashboardScreen] reads it rather
  /// than declaring its own copy.
  static const double cardOverlap = 40;

  /// Clear space demanded between the date line and the top of the cards.
  static const double minCardGap = 12;

  /// Empty runway kept below the text for the cards to sit in. Deriving it
  /// from the two constants above is what guarantees the gap survives a
  /// notch and a large text scale: the block grows, so the cards move down
  /// with it.
  static const double _bottomReserve = cardOverlap + minCardGap;

  static const double _avatarSize = 38;

  @override
  Widget build(BuildContext context) {
    // Status bar height varies with the notch; read it rather than assuming.
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: minHeight),
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
        _bottomReserve,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // Top-aligned: the slack belongs below the date line, where the
        // cards land, not above the eyebrow.
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
