import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/dashed_border.dart';

/// An image chosen for a listing, held as bytes so the same code paints it on
/// mobile, desktop and web without touching `dart:io`.
class PickedImage {
  const PickedImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Dashed drop zone for the product photos.
///
/// Shows the prompt while [images] is empty and the thumbnails once there are
/// any, with an add tile until [maxImages] is reached.
class ImageUploadBox extends StatelessWidget {
  const ImageUploadBox({
    super.key,
    this.images = const [],
    this.maxImages = 5,
    this.onAdd,
    this.onRemove,
  });

  final List<PickedImage> images;
  final int maxImages;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  /// Straight from the design; not on the base-4 scale.
  static const double _minHeight = 118;
  static const double _button = 44;
  static const double _thumb = 72;
  static const double _removeButton = 22;

  bool get _isFull => images.length >= maxImages;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: AppColors.border,
      radius: AppRadii.card,
      child: Container(
        // A minimum, not a fixed height: the caption wraps on narrow screens
        // and at large text scales, and the box grows with it.
        constraints: const BoxConstraints(minHeight: _minHeight),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: images.isEmpty ? _buildPrompt(context) : _buildThumbnails(),
      ),
    );
  }

  Widget _buildPrompt(BuildContext context) {
    return Semantics(
      label: 'Upload product images',
      button: true,
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AddCircle(size: _button),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Upload product images',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                Text(
                  'PNG / JPG  ·  max $maxImages images',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            for (var index = 0; index < images.length; index++)
              _Thumbnail(
                image: images[index],
                onRemove: onRemove == null ? null : () => onRemove!(index),
              ),
            if (!_isFull)
              Semantics(
                label: 'Add another image',
                button: true,
                child: Material(
                  color: AppColors.field,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.cardRadius,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: onAdd,
                    child: const SizedBox.square(
                      dimension: _thumb,
                      child: ExcludeSemantics(child: _AddCircle(size: 32)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          '${images.length} of $maxImages selected',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _AddCircle extends StatelessWidget {
  const _AddCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: AppColors.tintMaroon,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, size: size / 2, color: AppColors.primary),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, this.onRemove});

  final PickedImage image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: ImageUploadBox._thumb,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadii.cardRadius,
              child: Image.memory(
                image.bytes,
                fit: BoxFit.cover,
                semanticLabel: image.name,
              ),
            ),
          ),
          Positioned(
            top: -AppSpacing.x1,
            right: -AppSpacing.x1,
            child: Semantics(
              label: 'Remove ${image.name}',
              button: true,
              child: Material(
                color: AppColors.textDark,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onRemove,
                  child: const SizedBox.square(
                    dimension: ImageUploadBox._removeButton,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
