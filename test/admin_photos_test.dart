import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
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
import 'package:shakti_saree/admin/widgets/categories/category_edit_sheet.dart';
import 'package:shakti_saree/admin/widgets/categories/category_tile.dart';
import 'package:shakti_saree/admin/widgets/common/labelled_field.dart';
import 'package:shakti_saree/admin/widgets/dashboard/dashboard_header.dart';
import 'package:shakti_saree/admin/widgets/more/more_header.dart';
import 'package:shakti_saree/admin/widgets/navigation/admin_bottom_nav.dart';

import 'support/fake_firebase_auth.dart';
import 'support/firestore_seed.dart';

/// Photos picked for a category or for the admin's own profile are saved in
/// that document's `image` field, and shown wherever the record is.

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

  group('category photos', () {
    late FakeFirebaseFirestore db;

    Future<void> openCategories(WidgetTester tester) async {
      _tallPhone(tester);
      db = await seededFirestore();
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

    testWidgets('a new category is saved with the photo picked for it', (
      tester,
    ) async {
      final gallery = _useGallery(_png);
      await openCategories(tester);
      await tester.tap(find.bySemanticsLabel('Add category'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upload category image'));
      await tester.pumpAndSettle();

      // Shrunk to thumbnail size on the way in, one photo only.
      expect(gallery.asked!.maxWidth, CategoryEditSheet.photoSize);
      expect(gallery.asked!.maxHeight, CategoryEditSheet.photoSize);
      expect(gallery.asked!.imageQuality, EmbeddedPhoto.quality);
      expect(find.text('1 of 1 selected'), findsOneWidget);

      await tester.enterText(_field('Name'), 'Green Saree');
      // The button wakes up once a name is typed, on the next frame.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      final image = (await stored('Green Saree'))['image'] as String;
      expect(EmbeddedPhoto.bytesOf(image), _png);
      final picture = tester.widget<Image>(
        find.descendant(of: tileFor('Green Saree'), matching: find.byType(Image)),
      );
      expect(picture.image, isA<MemoryImage>());
    });

    testWidgets('renaming keeps the picture, and choosing one replaces it', (
      tester,
    ) async {
      _useGallery(_png);
      await openCategories(tester);

      await openEditor(tester, 'Silk Sarees');
      await tester.enterText(_field('Name'), 'Pure Silk Sarees');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(
        (await stored('Pure Silk Sarees'))['image'],
        'assets/images/image1.png',
      );

      await openEditor(tester, 'Pure Silk Sarees');
      await tester.tap(find.text('Upload category image'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      final image = (await stored('Pure Silk Sarees'))['image'] as String;
      expect(EmbeddedPhoto.bytesOf(image), _png);
    });

    testWidgets('a picture that cannot be made to fit is refused in the sheet', (
      tester,
    ) async {
      _useGallery(Uint8List(EmbeddedPhoto.maxBytes + 1));
      await openCategories(tester);
      await tester.tap(find.bySemanticsLabel('Add category'));
      await tester.pumpAndSettle();

      await _tapAndWait(tester, find.text('Upload category image'));

      expect(find.text(_tooBig), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
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
