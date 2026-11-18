import 'package:flutter/material.dart';

import '../../admin/utils/embedded_photo.dart';

/// The picture a `products` or `categories` document names in its `image`
/// field, or [fallback] when it names none or the file cannot be loaded.
///
/// The field holds the path of one of the app's own pictures, chosen in the
/// admin from `assets/images/`. A record saved before that may hold a photo
/// kept in the document itself (see [EmbeddedPhoto]), and blank means the
/// picture was taken off. A URL is honoured just the same, so moving the
/// catalogue's photos to hosted storage needs no change here.
class ShopImage extends StatelessWidget {
  const ShopImage({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? path;
  final Widget fallback;
  final BoxFit fit;

  static bool _isUrl(String path) =>
      path.startsWith('https://') || path.startsWith('http://');

  /// The same choice, for a picture painted as a decoration.
  static ImageProvider? providerFor(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (EmbeddedPhoto.isEmbedded(path)) {
      final bytes = EmbeddedPhoto.bytesOf(path);
      return bytes == null ? null : MemoryImage(bytes);
    }
    return _isUrl(path) ? NetworkImage(path) : AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final source = path;
    // Blank is a picture the admin took off, and reads as none.
    if (source == null || source.trim().isEmpty) return fallback;
    if (EmbeddedPhoto.isEmbedded(source)) {
      final bytes = EmbeddedPhoto.bytesOf(source);
      if (bytes == null) return fallback;
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
    return _isUrl(source)
        ? Image.network(
            source,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => fallback,
          )
        : Image.asset(
            source,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
  }
}
