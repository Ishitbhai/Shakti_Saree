// Writes the placeholder artwork that ships in `assets/images/`.
//
// The catalogue has no photographs. Until it does, every listing and grouping
// still needs a picture in its frame, so this draws one: a woven-looking
// gradient in the item's own palette tint, which is the colour that stood in
// for the photo before there were any image files at all.
//
// Run it from the project root when a seed item is added or renamed:
//
//     dart run tool/generate_placeholder_art.dart
//
// It is a development tool. Nothing in `lib/` imports it, it ships with no
// build, and the files it writes are meant to be overwritten one by one as
// real photography arrives — same path, same name, and the app picks them up
// with no code change.
library;

import 'dart:io';
import 'dart:typed_data';

/// The swatch palette, matching `AppColors` exactly. Kept as literals because
/// this script runs outside the Flutter app and cannot import the theme.
const List<int> _palette = [
  0x7B1E3B, // primary
  0xE0A82E, // warning
  0x2E7D5B, // success
  0x3A6EA5, // info
  0x9B3352, // primaryLight
];

/// One picture to draw: where it goes, which tint, how big.
class _Art {
  const _Art(this.path, this.swatchIndex, this.size);

  final String path;
  final int swatchIndex;
  final int size;
}

/// The five seeded listings, in catalogue order.
const List<_Art> _products = [
  _Art('assets/images/products/banarasi_silk_saree.png', 0, 512),
  _Art('assets/images/products/kanjivaram_pure_silk.png', 1, 512),
  _Art('assets/images/products/cotton_daily_saree.png', 2, 512),
  _Art('assets/images/products/georgette_party_wear.png', 3, 512),
  _Art('assets/images/products/paithani_silk_saree.png', 4, 512),
];

/// The twelve seeded groupings, in the order the categories screen lists
/// them.
const List<_Art> _categories = [
  _Art('assets/images/categories/silk_saree.png', 0, 384),
  _Art('assets/images/categories/banarasi.png', 1, 384),
  _Art('assets/images/categories/cotton_saree.png', 2, 384),
  _Art('assets/images/categories/georgette.png', 3, 384),
  _Art('assets/images/categories/kanjivaram.png', 4, 384),
  _Art('assets/images/categories/bridal_wear.png', 0, 384),
  _Art('assets/images/categories/designer.png', 1, 384),
  _Art('assets/images/categories/daily_wear.png', 2, 384),
  _Art('assets/images/categories/chanderi.png', 3, 384),
  _Art('assets/images/categories/patola.png', 4, 384),
  _Art('assets/images/categories/paithani.png', 0, 384),
  _Art('assets/images/categories/organza.png', 1, 384),
];

void main() {
  for (final art in [..._products, ..._categories]) {
    final file = File(art.path)..parent.createSync(recursive: true);
    file.writeAsBytesSync(_draw(art));
    stdout.writeln('wrote ${art.path}');
  }
}

/// Paints one placeholder and encodes it.
///
/// A diagonal gradient from a deepened tint to a washed one, crossed by two
/// sets of thin lighter lines — near enough to a woven border to read as
/// fabric at thumbnail size, and plainly not a photograph at full size.
Uint8List _draw(_Art art) {
  final colour = _palette[art.swatchIndex % _palette.length];
  final size = art.size;
  final pixels = Uint8List(size * size * 3);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // 0 at the top-left corner, 1 at the bottom-right.
      final diagonal = (x + y) / (2 * size - 2);
      var shade = _mix(_scale(colour, 0.72), _wash(colour, 0.55), diagonal);

      // The zari lines: two spacings, so they cross rather than stripe.
      if ((x + y) % 96 < 3) shade = _wash(shade, 0.22);
      if ((x - y) % 128 == 0) shade = _wash(shade, 0.12);

      // A soft vignette, which keeps the corners from looking flat.
      final edge = _edgeDistance(x, y, size);
      if (edge < size * 0.06) shade = _scale(shade, 0.88);

      final offset = (y * size + x) * 3;
      pixels[offset] = (shade >> 16) & 0xFF;
      pixels[offset + 1] = (shade >> 8) & 0xFF;
      pixels[offset + 2] = shade & 0xFF;
    }
  }

  return _encodePng(pixels, size, size);
}

/// How far a pixel sits from the nearest edge.
int _edgeDistance(int x, int y, int size) {
  final horizontal = x < size - 1 - x ? x : size - 1 - x;
  final vertical = y < size - 1 - y ? y : size - 1 - y;
  return horizontal < vertical ? horizontal : vertical;
}

/// Darkens or brightens every channel by [factor].
int _scale(int colour, double factor) => _rgb(
  (((colour >> 16) & 0xFF) * factor).round(),
  (((colour >> 8) & 0xFF) * factor).round(),
  ((colour & 0xFF) * factor).round(),
);

/// Moves a colour [amount] of the way towards white.
int _wash(int colour, double amount) => _mix(colour, 0xFFFFFF, amount);

/// Blends two colours, [amount] of the way from [from] to [to].
int _mix(int from, int to, double amount) {
  int channel(int shift) {
    final a = (from >> shift) & 0xFF;
    final b = (to >> shift) & 0xFF;
    return (a + (b - a) * amount).round();
  }

  return _rgb(channel(16), channel(8), channel(0));
}

int _rgb(int r, int g, int b) =>
    (_clamp(r) << 16) | (_clamp(g) << 8) | _clamp(b);

int _clamp(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

// ---------------------------------------------------------------- encoding
/// The smallest PNG that renders: header, one compressed image block, end.
///
/// Written out by hand rather than with a package — this is the only thing in
/// the project that needs an encoder, and a development script is not worth a
/// dependency.
Uint8List _encodePng(Uint8List pixels, int width, int height) {
  // Every scanline carries a filter byte; 0 means "stored as-is".
  final raw = Uint8List(height * (width * 3 + 1));
  for (var y = 0; y < height; y++) {
    final from = y * width * 3;
    final to = y * (width * 3 + 1);
    raw[to] = 0;
    raw.setRange(to + 1, to + 1 + width * 3, pixels, from);
  }

  final header = BytesBuilder()
    ..add(_be32(width))
    ..add(_be32(height))
    ..add([8, 2, 0, 0, 0]); // 8-bit, truecolour, no interlacing.

  return Uint8List.fromList([
    ...[137, 80, 78, 71, 13, 10, 26, 10],
    ..._chunk('IHDR', header.toBytes()),
    ..._chunk('IDAT', Uint8List.fromList(zlib.encode(raw))),
    ..._chunk('IEND', Uint8List(0)),
  ]);
}

/// One PNG chunk: length, type, payload, checksum.
List<int> _chunk(String type, Uint8List data) {
  final body = [...type.codeUnits, ...data];
  return [..._be32(data.length), ...body, ..._be32(_crc32(body))];
}

List<int> _be32(int value) => [
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];

final List<int> _crcTable = List<int>.generate(256, (index) {
  var value = index;
  for (var bit = 0; bit < 8; bit++) {
    value = (value & 1) == 1 ? 0xEDB88320 ^ (value >> 1) : value >> 1;
  }
  return value;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
