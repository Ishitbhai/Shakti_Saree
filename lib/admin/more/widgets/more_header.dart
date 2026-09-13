import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/tinted_pill.dart';
import '../admin_profile.dart';

/// Curved maroon block at the top of the More tab, carrying who is signed in.
///
/// Presentational only — every value arrives through the constructor.
class MoreHeader extends StatelessWidget {
  const MoreHeader({super.key, required this.profile, this.onBack});

  final AdminProfile profile;
  final VoidCallback? onBack;

  /// Straight from the design; not on the base-4 scale.
  static const double _avatar = 52;
  static const double _backSquare = 36;

  @override
  Widget build(BuildContext context) {
    // Status bar height varies with the notch; read it rather than assuming.
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
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
        AppSpacing.x6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Semantics(
                label: 'Back',
                button: true,
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox.square(
                    dimension: _backSquare,
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'More',
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              // Balances the back square so the title stays centred.
              const SizedBox.square(dimension: _backSquare),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          MergeSemantics(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    height: _avatar,
                    width: _avatar,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      profile.initial,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      Text(
                        profile.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnPrimarySoft,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      TintedPill(
                        label: profile.role,
                        background: AppColors.primaryLight,
                        foreground: AppColors.textOnPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
