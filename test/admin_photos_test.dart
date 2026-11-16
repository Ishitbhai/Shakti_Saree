import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shakti_saree/admin/data/providers/backend_providers.dart';
import 'package:shakti_saree/admin/data/providers/session_providers.dart';
import 'package:shakti_saree/admin/data/repositories/admin_auth_repository.dart';
import 'package:shakti_saree/admin/screens/admin_shell.dart';
import 'package:shakti_saree/admin/screens/categories_screen.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/utils/embedded_photo.dart';
import 'package:shakti_saree/admin/widgets/categories/category_tile.dart';
import 'package:shakti_saree/admin/widgets/common/labelled_field.dart';
import 'package:shakti_saree/admin/widgets/dashboard/dashboard_header.dart';
import 'package:shakti_saree/admin/widgets/more/more_header.dart';
import 'package:shakti_saree/admin/widgets/navigation/admin_bottom_nav.dart';
import 'package:shakti_saree/admin/widgets/products/asset_picture_sheet.dart';

import 'support/fake_firebase_auth.dart';
import 'support/firestore_seed.dart';

/// A category's picture is the path of one of the app's own, chosen from
/// assets/images; the admin's profile photo is kept in their own document.
/// Both show wherever the record is.

/// A one-pixel PNG: a real picture, so painting it exercises the decoder.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

const _tooBig = 'That photo is too large to save. Please choose a smaller one.';

/// Stands in for the gallery, remembering what it was asked for.
class _FakeGallery extends ImagePickerPlatform {
  _FakeGallery(this.returns);

  final Uint8List returns;
  ImagePickerOptions? asked;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    asked = options;
    return XFile.fromData(returns, name: 'photo.png', mimeType: 'image/png');
  }
}

_FakeGallery _useGallery(Uint8List returns) {
  final previous = ImagePickerPlatform.instance;
  final gallery = _FakeGallery(returns);
  ImagePickerPlatform.instance = gallery;
  addTearDown(() => ImagePickerPlatform.instance = previous);
  return gallery;
}

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabelledField)),
  matching: find.byType(TextField),
);

/// Random pixels, so the PNG barely compresses: a picture genuinely too
/// heavy to store. Only callable inside [WidgetTester.runAsync].
Future<Uint8List> _noisyPng(int side) async {
  final pixels = Uint8List(side * side * 4);
  var seed = 7;
  for (var i = 0; i < pixels.length; i++) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    pixels[i] = i % 4 == 3 ? 255 : (seed >> 16) & 0xff;
  }
  final decoded = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    side,
    side,
    ui.PixelFormat.rgba8888,
    decoded.complete,
  );
  final image = await decoded.future;
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Taps something whose handler waits on the gallery and the image codec,
/// letting both answer in real time before the frame is drawn.
Future<void> _tapAndWait(WidgetTester tester, Finder target) async {
  await tester.runAsync(() async {
    await tester.tap(target);
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  await tester.pumpAndSettle();
}

void main() {
  group('a picture too heavy to store', () {
    testWidgets('one that already fits is left exactly as it is', (
      tester,
    ) async {
      final fitted = await tester.runAsync(() => EmbeddedPhoto.fitted(_png));
      expect(identical(fitted, _png), isTrue);
    });

    testWidgets('is redrawn smaller until it fits, still a picture', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final heavy = await _noisyPng(700);
        expect(EmbeddedPhoto.fits(heavy), isFalse);

        final fitted = await EmbeddedPhoto.fitted(heavy);
        expect(fitted, isNotNull);
        expect(EmbeddedPhoto.fits(fitted!), isTrue);

        final codec = await ui.instantiateImageCodec(fitted);
        final image = (await codec.getNextFrame()).image;
        expect(image.width, lessThan(700));
        // Shrunk evenly, not squashed.
        expect(image.width, image.height);
        image.dispose();
        codec.dispose();
      });
    });

    testWidgets('something that is not a picture is given up on', (
      tester,
    ) async {
      final fitted = await tester.runAsync(
        () => EmbeddedPhoto.fitted(Uint8List(EmbeddedPhoto.maxBytes + 1)),
      );
      expect(fitted, isNull);
    });
  });

  group('the picture sheet', () {
    test('orders names the way a person reads them', () {
      final names = ['image10.png', 'image2.png', 'auth_model.png', 'image1.png']
        ..sort(AssetPictureSheet.naturalOrder);
      expect(names, ['auth_model.png', 'image1.png', 'image2.png', 'image10.png']);
    });

    testWidgets('offers every picture in assets/images, and only those', (
      tester,
    ) async {
      final onDisk = [
        for (final file in Directory('assets/images').listSync().whereType<File>())
          if (RegExp(r'\.(png|jpe?g|webp|gif)$', caseSensitive: false)
              .hasMatch(file.path))
            'assets/images/${file.uri.pathSegments.last}',
      ]..sort(AssetPictureSheet.naturalOrder);

      final offered = await AssetPictureSheet.picturesIn(rootBundle);

      expect(onDisk, isNotEmpty);
      expect(offered, onDisk);
    });

    testWidgets('outlines the current picture and answers with the one tapped', (
      tester,
    ) async {
      _tallPhone(tester);
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => chosen = await AssetPictureSheet.show(
                context,
                selected: 'assets/images/image1.png',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a picture'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('image1.png')),
        containsSemantics(label: 'image1.png', isButton: true, isSelected: true),
      );

      await tester.tap(find.byKey(const ValueKey('picture:assets/images/image5.png')));
      await tester.pumpAndSettle();

      expect(chosen, 'assets/images/image5.png');
      expect(find.text('Choose a picture'), findsNothing);
    });
  });

  group('category pictures', () {
    late FakeFirebaseFirestore db;

    Future<void> openCategories(WidgetTester tester, {String? photo}) async {
      _tallPhone(tester);
      db = await seededFirestore();
      if (photo != null) {
        await db
            .collection('categories')
            .doc('MVr3vUNaKQoiojHxfzuu')
            .update({'image': photo});
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [firestoreProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MediaQuery(
              data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
              child: CategoriesScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder tileFor(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(CategoryTile));

    Future<void> openEditor(WidgetTester tester, String name) async {
      await tester.tap(
        find.descendant(
          of: tileFor(name),
          matching: find.byIcon(Icons.edit_outlined),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<Map<String, dynamic>> stored(String name) async => (await db
            .collection('categories')
            .where('category_name', isEqualTo: name)
            .get())
        .docs
        .single
        .data();

    /// Opens the picture box's sheet and taps one of the app's own pictures.
    Future<void> choose(WidgetTester tester, String path) async {
      await tester.tap(find.text('Choose category picture'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('picture:$path')));
      await tester.pumpAndSettle();
    }

    /// The picture a tile draws, as the asset it names.
    String? assetIn(WidgetTester tester, Finder tile) {
      final found = find.descendant(of: tile, matching: find.byType(Image));
      if (found.evaluate().isEmpty) return null;
      final image = tester.widget<Image>(found).image;
      return image is AssetImage ? image.assetName : '$image';
    }

    testWidgets('a new category is saved with the path of the picture chosen', (
      tester,
    ) async {
      await openCategories(tester);
      await tester.tap(find.bySemanticsLabel('Add category'));
      await tester.pumpAndSettle();
      expect(find.text('From assets/images in the app'), findsOneWidget);

      await choose(tester, 'assets/images/image3.png');
      expect(find.text('1 of 1 selected'), findsOneWidget);

      await tester.enterText(_field('Name'), 'Green Saree');
      // The button wakes up once a name is typed, on the next frame.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      expect((await stored('Green Saree'))['image'], 'assets/images/image3.png');
      expect(assetIn(tester, tileFor('Green Saree')), 'assets/images/image3.png');
    });

    testWidgets('editing shows the picture it has, keeps it, and can swap it', (
      tester,
    ) async {
      await openCategories(tester);

      await openEditor(tester, 'Silk Sarees');
      // The current picture, not an empty box.
      expect(find.bySemanticsLabel('image1.png'), findsOneWidget);
      await tester.enterText(_field('Name'), 'Pure Silk Sarees');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(
        (await stored('Pure Silk Sarees'))['image'],
        'assets/images/image1.png',
      );

      await openEditor(tester, 'Pure Silk Sarees');
      await tester.tap(find.bySemanticsLabel('Remove image1.png'));
      await tester.pumpAndSettle();
      await choose(tester, 'assets/images/image2.png');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(
        (await stored('Pure Silk Sarees'))['image'],
        'assets/images/image2.png',
      );
    });

    testWidgets('taking the picture off stores none', (tester) async {
      await openCategories(tester);

      await openEditor(tester, 'Silk Sarees');
      await tester.tap(find.bySemanticsLabel('Remove image1.png'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect((await stored('Silk Sarees'))['image'], '');
      expect(assetIn(tester, tileFor('Silk Sarees')), isNull);
      expect(
        find.descendant(
          of: tileFor('Silk Sarees'),
          matching: find.byIcon(Icons.image_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a photo a grouping was saved with before is kept and shown', (
      tester,
    ) async {
      final photo = EmbeddedPhoto.encode(_png);
      await openCategories(tester, photo: photo);

      await openEditor(tester, 'Silk Sarees');
      expect(find.bySemanticsLabel('Saved photo'), findsOneWidget);
      await tester.enterText(_field('Name'), 'Silk');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect((await stored('Silk'))['image'], photo);
    });
  });

  group('the admin profile photo', () {
    const admin = 'uid_admin';
    late FakeFirebaseFirestore db;
    late FakeFirebaseAuth auth;

    Future<void> seedAdmin({String? image}) async {
      db = await seededFirestore();
      auth = FakeFirebaseAuth();
      await db.collection('users').doc(admin).set({
        'name': 'Test Admin',
        'email': 'admin@example.com',
        'phone': '9876543210',
        'user_type': 'admin',
        'image': ?image,
      });
    }

    /// The panel as signing in, or reopening the app, leaves it: the session
    /// read from the admin's `users` document, nothing carried in memory.
    Future<void> openPanel(WidgetTester tester) async {
      _tallPhone(tester);
      auth.signInAs(admin, email: 'admin@example.com');
      final session = await AdminAuthRepository(
        auth,
        db,
      ).sessionFor(auth.currentUser!);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(db),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const AdminShell()),
        ),
      );
      ProviderScope.containerOf(
        tester.element(find.byType(AdminShell)),
        listen: false,
      ).read(adminSessionProvider.notifier).start(session!);
      await tester.pumpAndSettle();
    }

    Future<void> openTab(WidgetTester tester, int index) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AdminBottomNav),
          matching: find.byIcon(AdminBottomNav.items[index].icon),
        ),
      );
      await tester.pumpAndSettle();
    }

    Image? pictureIn(WidgetTester tester, Type header) {
      final found = find.descendant(
        of: find.byType(header),
        matching: find.byType(Image),
      );
      return found.evaluate().isEmpty ? null : tester.widget<Image>(found);
    }

    Future<Map<String, dynamic>> storedProfile() async =>
        (await db.collection('users').doc(admin).get()).data()!;

    testWidgets('a saved photo is stored, and shown on More and the Dashboard', (
      tester,
    ) async {
      await seedAdmin();
      _useGallery(_png);
      await openPanel(tester);

      // Nothing yet: the initial stands in.
      expect(pictureIn(tester, DashboardHeader), isNull);

      await openTab(tester, 4);
      await tester.tap(find.text('Admin Edit Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final image = (await storedProfile())['image'] as String;
      expect(EmbeddedPhoto.bytesOf(image), _png);
      expect(pictureIn(tester, MoreHeader)?.image, isA<MemoryImage>());

      await openTab(tester, 0);
      expect(pictureIn(tester, DashboardHeader)?.image, isA<MemoryImage>());
    });

    testWidgets('a stored photo is back after the app reopens', (tester) async {
      await seedAdmin(image: EmbeddedPhoto.encode(_png));
      await openPanel(tester);

      expect(pictureIn(tester, DashboardHeader)?.image, isA<MemoryImage>());
      await openTab(tester, 4);
      final shown = pictureIn(tester, MoreHeader)!.image as MemoryImage;
      expect(shown.bytes, _png);
    });

    testWidgets('removing the photo takes it off the stored profile', (
      tester,
    ) async {
      await seedAdmin(image: EmbeddedPhoto.encode(_png));
      await openPanel(tester);

      await openTab(tester, 4);
      await tester.tap(find.text('Admin Edit Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect((await storedProfile()).containsKey('image'), isFalse);
      expect(pictureIn(tester, MoreHeader), isNull);
      // The rest of the profile is untouched.
      expect((await storedProfile())['name'], 'Test Admin');
    });

    testWidgets('a picture that cannot be made to fit is refused', (
      tester,
    ) async {
      await seedAdmin();
      _useGallery(Uint8List(EmbeddedPhoto.maxBytes + 1));
      await openPanel(tester);

      await openTab(tester, 4);
      await tester.tap(find.text('Admin Edit Profile'));
      await tester.pumpAndSettle();
      await _tapAndWait(tester, find.text('Change Photo'));

      expect(find.text(_tooBig), findsOneWidget);
      // Still offering a photo rather than holding the refused one.
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Remove Photo'), findsNothing);
    });
  });
}
