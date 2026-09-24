import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shakti_saree/admin/more/admin_profile.dart';
import 'package:shakti_saree/admin/more/edit_profile_screen.dart';
import 'package:shakti_saree/admin/more/more_screen.dart';
import 'package:shakti_saree/admin/shared/widgets/labelled_field.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';
import 'package:shakti_saree/mock/profile_store.dart';

Widget _host() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    home: const MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
      child: MoreScreen(),
    ),
  ),
);

/// Tall enough that the whole form builds — a ListView only makes what fits.
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The text input under a given form label.
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabelledField)),
  matching: find.byType(TextField),
);

Finder get _saveButton => find.widgetWithText(FilledButton, 'Save Changes');

/// Found from the app rather than from the More tab, which goes offstage the
/// moment the form is pushed over it.
ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );

AdminProfile _stored(WidgetTester tester) =>
    _containerOf(tester).read(profileStoreProvider);

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_saveButton).onPressed != null;

/// A real 1x1 PNG — the avatar decodes whatever it is handed, and a fistful
/// of arbitrary bytes would fail to decode.
///
/// A fresh list each call, the way the picker hands back a fresh one, so a
/// test can tell "the same picture again" from "the very same object".
Uint8List _png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

/// Stands in for the gallery.
///
/// Extended rather than mocked with a package: image_picker is reached through
/// its platform interface, so swapping the instance is all a fake needs to do
/// — and [ImagePicker] then runs its own code down to the last step.
class _FakeGallery extends ImagePickerPlatform {
  _FakeGallery({this.returns, this.throws});

  /// What choosing hands back. Null stands for a gallery closed without
  /// choosing anything.
  final Uint8List? returns;

  /// Raised instead, for the case where the gallery will not open.
  final Exception? throws;

  /// How many times the gallery was opened.
  int openings = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    openings++;
    final failure = throws;
    if (failure != null) throw failure;

    final bytes = returns;
    return bytes == null
        ? null
        : XFile.fromData(bytes, name: 'photo.png', mimeType: 'image/png');
  }
}

/// Puts a fake gallery behind the picker for one test.
_FakeGallery _useGallery({Uint8List? returns, Exception? throws}) {
  final previous = ImagePickerPlatform.instance;
  final gallery = _FakeGallery(returns: returns, throws: throws);
  ImagePickerPlatform.instance = gallery;
  addTearDown(() => ImagePickerPlatform.instance = previous);
  return gallery;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Opens the form the way the app does — pushed from the More tab.
  ///
  /// Pumping it as the home route would leave nothing to pop, and the
  /// unsaved-changes guard only has a say when there is.
  Future<void> openProfile(WidgetTester tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin Edit Profile'));
    await tester.pumpAndSettle();
  }

  /// Opens the form on an admin who already has a photo.
  ///
  /// Stored before the screen is pushed, because the form takes its draft
  /// from the store as it opens — a picture arriving after that would never
  /// reach the draft.
  Future<void> openProfileWearingPhoto(
    WidgetTester tester,
    Uint8List photo,
  ) async {
    _tallPhone(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final container = _containerOf(tester);
    container
        .read(profileStoreProvider.notifier)
        .save(container.read(profileStoreProvider).copyWith(photo: photo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin Edit Profile'));
    await tester.pumpAndSettle();
  }

  /// Types into a field, replacing whatever was there.
  Future<void> enter(WidgetTester tester, String label, String text) async {
    await tester.enterText(_field(label), text);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
  }

  group('the form', () {
    testWidgets('the More row opens it', (tester) async {
      await openProfile(tester);

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('opens on the stored profile', (tester) async {
      await openProfile(tester);

      final profile = _stored(tester);
      expect(
        tester.widget<TextField>(_field('Full Name')).controller!.text,
        profile.name,
      );
      expect(
        tester.widget<TextField>(_field('Email Address')).controller!.text,
        profile.email,
      );
      expect(
        tester.widget<TextField>(_field('Mobile Number')).controller!.text,
        profile.mobile,
      );
      // A date, not a typed field: shown the way the rest of the app shows
      // one.
      expect(find.text('12 Aug 2002'), findsOneWidget);
      // The initials on the avatar come off the stored name.
      expect(find.text('PK'), findsWidgets);

      for (final gender in Gender.values) {
        expect(find.text(gender.label), findsOneWidget);
      }
    });

    testWidgets('an admin with no photo wears their initials', (tester) async {
      await openProfile(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.text('Change Photo'), findsOneWidget);
      // Nothing to take off yet.
      expect(find.text('Remove Photo'), findsNothing);
    });
  });

  group('the photo', () {
    testWidgets('choosing one shows it and leaves something to save', (
      tester,
    ) async {
      final gallery = _useGallery(returns: _png());
      await openProfile(tester);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();

      expect(gallery.openings, 1);
      expect(find.byType(Image), findsOneWidget);
      expect(_saveEnabled(tester), isTrue);
      // Not stored until Save, like every other field on the form.
      expect(_stored(tester).photo, isNull);
    });

    testWidgets('saving stores the picture', (tester) async {
      _useGallery(returns: _png());
      await openProfile(tester);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).photo, _png());
      // And the More tab is wearing it.
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a gallery closed without choosing changes nothing', (
      tester,
    ) async {
      final gallery = _useGallery();
      await openProfile(tester);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();

      expect(gallery.openings, 1);
      expect(find.byType(Image), findsNothing);
      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('a gallery that will not open says so', (tester) async {
      _useGallery(throws: Exception('no permission'));
      await openProfile(tester);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not open the gallery'), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('the same picture again is not an edit', (tester) async {
      // Already wearing this picture, and the gallery hands back the same
      // file: a new list of identical bytes, which is not a change.
      _useGallery(returns: _png());
      await openProfileWearingPhoto(tester, _png());

      await tester.tap(find.text('Replace Photo'));
      await tester.pumpAndSettle();

      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('a stored picture can be taken off again', (tester) async {
      await openProfileWearingPhoto(tester, _png());
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.text('Remove Photo'));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(_saveEnabled(tester), isTrue);

      await save(tester);
      expect(_stored(tester).photo, isNull);
    });

    testWidgets('discarding keeps the stored picture', (tester) async {
      _useGallery(returns: _png());
      await openProfile(tester);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(_stored(tester).photo, isNull);
    });
  });

  group('validation', () {
    testWidgets('a name is required', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Full Name', '');
      await save(tester);

      expect(find.text('A name is required.'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(_stored(tester).name, 'Priyanshu Kateshiya');
    });

    testWidgets('a name that is there saves', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Full Name', 'Anita Rao');
      await save(tester);

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).name, 'Anita Rao');
      expect(find.text('Profile updated'), findsOneWidget);
    });

    testWidgets('an email address is required', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Email Address', '');
      await save(tester);

      expect(find.text('An email address is required.'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('an email address has to parse as one', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Email Address', 'k@example');
      await save(tester);

      expect(
        find.text('That does not look like an email address.'),
        findsOneWidget,
      );
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('an email address that parses saves', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Email Address', 'anita.rao@shaktisaree.com');
      await save(tester);

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).email, 'anita.rao@shaktisaree.com');
    });

    testWidgets('a mobile number has to be a plausible Indian one', (
      tester,
    ) async {
      await openProfile(tester);
      await enter(tester, 'Mobile Number', '12345');
      await save(tester);

      expect(
        find.text('Enter a 10-digit Indian mobile number.'),
        findsOneWidget,
      );
      expect(find.byType(EditProfileScreen), findsOneWidget);

      // Ten digits, but starting with a digit no Indian mobile starts with.
      await enter(tester, 'Mobile Number', '1234567890');
      await save(tester);
      expect(
        find.text('Enter a 10-digit Indian mobile number.'),
        findsOneWidget,
      );
    });

    testWidgets('a plausible mobile number saves, however it is spaced', (
      tester,
    ) async {
      await openProfile(tester);
      await enter(tester, 'Mobile Number', '+91 91234-56789');
      await save(tester);

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).mobile, '+91 91234-56789');
    });

    testWidgets('a blank mobile number is allowed', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Mobile Number', '');
      await save(tester);

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).mobile, isEmpty);
    });

    testWidgets('a date of birth in the future is refused', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // The picker cannot offer one, but a stored profile can be carrying
      // one — and saving over it must not launder it.
      final container = _containerOf(tester);
      final seeded = container.read(profileStoreProvider);
      container
          .read(profileStoreProvider.notifier)
          .save(
            seeded.copyWith(
              dateOfBirth: DateTime.now().add(const Duration(days: 30)),
            ),
          );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admin Edit Profile'));
      await tester.pumpAndSettle();

      await enter(tester, 'Full Name', 'Anita Rao');
      await save(tester);

      expect(find.text('Date of birth has to be in the past.'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(_stored(tester).name, 'Priyanshu Kateshiya');
    });

    testWidgets('a date of birth from the picker saves', (tester) async {
      await openProfile(tester);

      await tester.tap(find.bySemanticsLabel('Date of Birth, 12 Aug 2002'));
      await tester.pumpAndSettle();

      // The picker opens on the stored date, so August 2002 is on screen.
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('15 Aug 2002'), findsOneWidget);

      await save(tester);
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).dateOfBirth, DateTime(2002, 8, 15));
    });
  });

  group('saving', () {
    testWidgets('there is nothing to save until something differs', (
      tester,
    ) async {
      await openProfile(tester);

      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('a field edited back to where it started is not an edit', (
      tester,
    ) async {
      await openProfile(tester);
      final profile = _stored(tester);

      await enter(tester, 'Full Name', 'Priyanshu Kateshiy');
      expect(_saveEnabled(tester), isTrue);

      await enter(tester, 'Full Name', profile.name);
      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('a gender picked and unpicked is not an edit either', (
      tester,
    ) async {
      await openProfile(tester);

      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();
      expect(_saveEnabled(tester), isTrue);

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('the gender that was picked is what gets stored', (
      tester,
    ) async {
      await openProfile(tester);

      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(_stored(tester).gender, Gender.other);
    });
  });

  group('leaving', () {
    testWidgets('cancel warns about unsaved changes and can be called off', (
      tester,
    ) async {
      await openProfile(tester);
      await enter(tester, 'Full Name', 'Anita Rao');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('Full Name')).controller!.text,
        'Anita Rao',
      );
    });

    testWidgets('discarding from cancel leaves the stored profile alone', (
      tester,
    ) async {
      await openProfile(tester);
      await enter(tester, 'Full Name', 'Anita Rao');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).name, 'Priyanshu Kateshiya');
    });

    testWidgets('back warns about unsaved changes too', (tester) async {
      await openProfile(tester);
      await enter(tester, 'Email Address', 'anita@shaktisaree.com');

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(_stored(tester).email, 'k@example.com');
    });

    testWidgets('back with nothing changed does not ask', (tester) async {
      await openProfile(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(EditProfileScreen), findsNothing);
    });
  });

  testWidgets('the monogram follows the name that was saved', (tester) async {
    await openProfile(tester);
    // What the More tab was showing before the edit.
    expect(find.text('PK'), findsWidgets);

    await enter(tester, 'Full Name', 'Anita Rao');
    await save(tester);

    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
    expect(find.text('Anita Rao'), findsOneWidget);
    expect(find.text('PK'), findsNothing);
  });
}
