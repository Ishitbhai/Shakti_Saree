import 'dart:typed_data';
import 'dart:ui' as ui;

/// A photo kept inside its own Firestore document, as a `data:` URL in the
/// `image` field.
///
/// The project has no file storage, so a photo picked on the product form,
/// the category sheet or the admin's profile travels in the document itself.
/// Firestore holds a document to 1 MiB, which is why the forms shrink a photo
/// as it is picked and [fitted] has the last word on whether it may be saved.
abstract final class EmbeddedPhoto {
  /// The longest side a product photo is shrunk to: sharp on any phone screen.
  static const double maxSide = 1080;

  /// The JPEG quality the picker re-encodes a photo at.
  static const int quality = 75;

  /// The most a photo may weigh. Base64 adds a third on top, so this keeps
  /// the document under Firestore's 1 MiB with room for its other fields.
  static const int maxBytes = 600 * 1024;

  /// How much smaller each redraw in [fitted] makes the picture, and how many
  /// it tries before giving up.
  static const double _step = 0.7;
  static const int _attempts = 6;

  /// Pictures decoded at once before the oldest is let go.
  static const int _cacheSize = 64;

  /// Insertion-ordered, so the first key is always the least recently used.
  static final Map<String, Uint8List> _decoded = {};

  static bool fits(Uint8List bytes) => bytes.length <= maxBytes;

  static bool isEmbedded(String? path) =>
      path != null && path.startsWith('data:');

  /// [bytes] as a `data:` URL, typed from the picture's own first bytes: a
  /// picked file's name is not to be trusted, and on web it may have none.
  static String encode(Uint8List bytes) =>
      UriData.fromBytes(bytes, mimeType: _mimeTypeOf(bytes)).toString();

  /// The picture in [path], or null when it is not an embedded photo or is
  /// damaged.
  ///
  /// The same text gives back the same bytes, so a list rebuilt by a fresh
  /// snapshot keeps its pictures rather than decoding and flashing them again.
  static Uint8List? bytesOf(String path) {
    if (!isEmbedded(path)) return null;

    final cached = _decoded.remove(path);
    if (cached != null) return _decoded[path] = cached;

    final Uint8List bytes;
    try {
      bytes = UriData.parse(path).contentAsBytes();
    } on FormatException {
      return null;
    }
    if (bytes.isEmpty) return null;

    _decoded[path] = bytes;
    if (_decoded.length > _cacheSize) _decoded.remove(_decoded.keys.first);
    return bytes;
  }

  /// [bytes] as they may be stored: unchanged when they already fit, else
  /// redrawn smaller until they do. Null when they are not a picture, or will
  /// not fit however small.
  ///
  /// The picker shrinks a photo but keeps its format, so a big PNG — a
  /// screenshot, or a picture saved from a website — can come back still too
  /// heavy to store. Redrawing it through the engine's own codec makes it fit
  /// without adding a package.
  static Future<Uint8List?> fitted(Uint8List bytes) async {
    if (fits(bytes)) return bytes;
    try {
      final (width, height) = await _sizeOf(bytes);
      var scale = 1.0;
      for (var attempt = 0; attempt < _attempts; attempt++) {
        scale *= _step;
        final smaller = await _redrawn(
          bytes,
          width: (width * scale).round(),
          height: (height * scale).round(),
        );
        if (fits(smaller)) return smaller;
      }
    } on Exception {
      // Not something the engine can read as a picture.
    }
    return null;
  }

  static Future<(int, int)> _sizeOf(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final image = (await codec.getNextFrame()).image;
      final size = (image.width, image.height);
      image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  }

  static Future<Uint8List> _redrawn(
    Uint8List bytes, {
    required int width,
    required int height,
  }) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width < 1 ? 1 : width,
      targetHeight: height < 1 ? 1 : height,
    );
    try {
      final image = (await codec.getNextFrame()).image;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw const FormatException('Could not redraw.');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static String _mimeTypeOf(Uint8List bytes) {
    bool has(List<int> signature, {int at = 0}) {
      if (bytes.length < at + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[at + i] != signature[i]) return false;
      }
      return true;
    }

    if (has(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (has(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (has(const [0x57, 0x45, 0x42, 0x50], at: 8)) return 'image/webp';
    return 'image/jpeg';
  }
}
