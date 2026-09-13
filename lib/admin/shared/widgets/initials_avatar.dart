import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Circle of initials, standing in for a photograph nobody has uploaded.
///
/// The tint is picked from [seed] rather than from list position, so a person
/// keeps the same colour however the list is sorted or filtered — a row that
/// changed colour when you typed in the search box would read as a different
/// person.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.seed,
    this.size = 44,
  });

  final String initials;

  /// What the colour is derived from — a name or a phone number.
  final String seed;

  final double size;

  /// Tint pairs, every one an existing token.
  static const List<({Color background, Color foreground})> palette = [
    (background: AppColors.tintMaroon, foreground: AppColors.primary),
    (background: AppColors.infoBg, foreground: AppColors.info),
    (background: AppColors.successBg, foreground: AppColors.success),
    (background: AppColors.warningBg, foreground: AppColors.warning),
    (background: AppColors.errorBg, foreground: AppColors.error),
  ];

  /// Summed code units rather than [Object.hashCode], which Dart does not
  /// promise to keep the same between runs — the colour would then change
  /// when the app restarted.
  static ({Color background, Color foreground}) tintFor(String seed) {
    if (seed.isEmpty) return palette.first;
    final total = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return palette[total % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final tint = tintFor(seed);

    return ExcludeSemantics(
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint.background,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: AppTypography.labelMedium.copyWith(color: tint.foreground),
        ),
      ),
    );
  }
}
