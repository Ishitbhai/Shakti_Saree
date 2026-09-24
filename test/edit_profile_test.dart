import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

    testWidgets('a photo it cannot store says so rather than nothing', (
      tester,
    ) async {
      await openProfile(tester);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Change Photo has not been built yet'), findsOneWidget);
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
