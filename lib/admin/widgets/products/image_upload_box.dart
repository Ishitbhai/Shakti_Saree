import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../styles/app_typography.dart';
import '../common/dashed_border.dart';

/// An image chosen for a listing: one of the app's own pictures, by its path
/// in the bundle, or a photo held as bytes, so the same code paints it on
/// mobile, desktop and web without touching `dart:io`.
class PickedImage {
  const PickedImage({required this.name, required Uint8List this.bytes})
    : assetPath = null;

  /// One of the pictures bundled with the app, such as
  /// `assets/images/image3.png`.
  PickedImage.asset(String this.assetPath)
    : name = assetPath.substring(assetPath.lastIndexOf('/') + 1),
      bytes = null;

  final String name;
  final Uint8List? bytes;
  final String? assetPath;
}

/// Shown under the picture box while it holds a photo an older record was
/// uploaded with: a user app that draws pictures from the app's own files
/// cannot show it, so the admin should pick one from `assets/images/`.
class SavedPhotoNote extends StatelessWidget {
  const SavedPhotoNote({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Text(
          'This is an uploaded photo, which the user app may not show. Tap × '
          'and choose a picture from assets/images instead.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textDark),
        ),
      ),
    );
  }
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
    this.prompt = 'Upload product images',
    this.caption,
    this.onAdd,
    this.onRemove,
  });

  final List<PickedImage> images;
  final int maxImages;

  /// What the empty box invites, which is also what a screen reader announces.
  final String prompt;

  /// The line under [prompt]; the formats and how many, when null.
  final String? caption;
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
      label: prompt,
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
                  prompt,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                Text(
                  caption ??
                      'PNG / JPG  ·  max $maxImages '
                          '${maxImages == 1 ? 'image' : 'images'}',
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

  /// What a thumbnail shows when its picture cannot be drawn.
  static Widget _broken(BuildContext context, Object error, StackTrace? stack) =>
      const ColoredBox(
        color: AppColors.field,
        child: Icon(Icons.broken_image_outlined),
      );

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
              child: switch (image) {
                PickedImage(:final bytes?) => Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  semanticLabel: image.name,
                  // A saved photo whose bytes are not a picture.
                  errorBuilder: _broken,
                ),
                PickedImage(:final assetPath) => Image.asset(
                  assetPath ?? '',
                  fit: BoxFit.cover,
                  semanticLabel: image.name,
                  // A file named in the database that this build lacks.
                  errorBuilder: _broken,
                ),
              },
            ),
          ),
          Positioned(
            top: -AppSpacing.x1,
            right: -AppSpacing.x1,
            child: Semantics(
              // Its own node: otherwise, inside a list, the caption below is
              // merged into this button and read out as part of its name.
              container: true,
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
