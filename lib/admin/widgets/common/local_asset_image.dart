import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';

/// A square picture from the app's own assets, with something to show when
/// there is no picture.
///
/// [Image.asset] only — this never reaches the network, and neither should
/// anything that replaces it. Paths come from `AppAssets` rather than being
/// typed at the call site.
///
/// Two things can go wrong with a bundled image, and both end up in the same
/// place: there may be no path at all, which is what a listing created in the
/// app looks like, or the file named may be missing from the bundle. Either
/// way the frame fills with [tint] — the colour that stood in for the photo
/// before there were any image files — rather than throwing a grey box or an
/// exception into the middle of a list.
class LocalAssetImage extends StatelessWidget {
  const LocalAssetImage({
    super.key,
    required this.assetPath,
    required this.size,
    this.tint,
    this.borderRadius = AppRadii.cardRadius,
    this.fit = BoxFit.cover,
  });

  /// What to show, or null where the item has no picture.
  final String? assetPath;

  /// The frame is square: the design gives these thumbnails equal sides
  /// everywhere they appear.
  final double size;

  /// Filled in behind a missing picture. Defaults to the neutral field
  /// colour, but callers pass the item's own tint so a listing keeps its
  /// colour whether or not it has a photo yet.
  final Color? tint;

  final BorderRadius borderRadius;
  final BoxFit fit;

  Color get _tint => tint ?? AppColors.field;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox.square(
        dimension: size,
        child: path == null
            ? _Fallback(tint: _tint, size: size)
            : Image.asset(
                path,
                fit: fit,
                width: size,
                height: size,
                // Decorative: every frame sits beside the name it belongs to,
                // and a screen reader reading both says it twice.
                excludeFromSemantics: true,
                // The picture is in the bundle, so there is no loading state
                // worth animating through.
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    _Fallback(tint: _tint, size: size),
              ),
      ),
    );
  }
}

/// What a frame holds when the picture is missing.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.tint, required this.size});

  final Color tint;
  final double size;

  /// Big enough to read as an icon, small enough to leave the tint visible.
  static const double _iconFraction = 0.42;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: tint,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: size * _iconFraction,
          // The tint carries the colour; the mark only has to be legible on
          // top of it.
          color: AppColors.textOnPrimary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
