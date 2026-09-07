import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border.dart';

/// Dashed drop zone for the product photos.
class ImageUploadBox extends StatelessWidget {
  const ImageUploadBox({super.key, this.maxImages = 5, this.onTap});

  final int maxImages;
  final VoidCallback? onTap;

  /// Straight from the design; not on the base-4 scale.
  static const double _height = 118;
  static const double _button = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Upload product images',
      button: true,
      child: DashedBorder(
        color: AppColors.border,
        radius: AppRadii.card,
        child: Material(
          color: AppColors.transparent,
          borderRadius: AppRadii.cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              // A minimum, not a fixed height: the caption wraps on narrow
              // screens and at large text scales, and the box grows with it.
              constraints: const BoxConstraints(minHeight: _height),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: AppSpacing.x4,
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: _button,
                      width: _button,
                      decoration: const BoxDecoration(
                        color: AppColors.tintMaroon,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Upload product images',
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      'PNG / JPG  ·  max $maxImages images',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
