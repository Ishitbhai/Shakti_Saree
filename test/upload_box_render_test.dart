import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/products/presentation/widgets/image_upload_box.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

/// Smallest valid 1x1 PNG, so Image.memory has something real to decode.
final _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

PickedImage _image(String name) => PickedImage(name: name, bytes: _pngBytes);

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('empty state prompts and reports the cap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(ImageUploadBox(onAdd: () => taps++)));
    await tester.pumpAndSettle();

    expect(find.text('Upload product images'), findsOneWidget);
    expect(find.text('PNG / JPG  ·  max 5 images'), findsOneWidget);

    await tester.tap(find.text('Upload product images'));
    expect(taps, 1);
  });

  testWidgets('shows thumbnails, a count and an add tile', (tester) async {
    await tester.pumpWidget(
      _host(
        ImageUploadBox(
          images: [_image('one.png'), _image('two.png')],
          onAdd: () {},
          onRemove: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('2 of 5 selected'), findsOneWidget);
    expect(find.text('Upload product images'), findsNothing);
    expect(find.bySemanticsLabel('Add another image'), findsOneWidget);
  });

  testWidgets('remove reports the tapped index', (tester) async {
    int? removed;
    await tester.pumpWidget(
      _host(
        ImageUploadBox(
          images: [_image('one.png'), _image('two.png')],
          onRemove: (index) => removed = index,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Remove two.png'));
    expect(removed, 1);
  });

  testWidgets('the add tile disappears at the cap', (tester) async {
    await tester.pumpWidget(
      _host(
        ImageUploadBox(
          images: [for (var i = 0; i < 5; i++) _image('$i.png')],
          onAdd: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 of 5 selected'), findsOneWidget);
    expect(find.bySemanticsLabel('Add another image'), findsNothing);
  });
}
