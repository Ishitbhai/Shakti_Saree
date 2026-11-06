import 'package:flutter/material.dart';

/// The picture a `products` or `categories` document names in its `image`
/// field, or [fallback] when it names none or the file cannot be loaded.
///
/// The field holds a path into the app's assets today, which is what the
/// admin panel writes, and a URL is honoured just the same, so moving the
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
    if (path == null) return null;
    return _isUrl(path) ? NetworkImage(path) : AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final source = path;
    if (source == null) return fallback;
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
