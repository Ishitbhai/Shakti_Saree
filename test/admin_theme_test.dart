import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/admin_tab.dart';
import 'package:shakti_saree/admin/screens/admin_shell.dart';
import 'package:shakti_saree/admin/screens/more_screen.dart';
import 'package:shakti_saree/admin/screens/order_detail_screen.dart';
import 'package:shakti_saree/admin/screens/orders_screen.dart';
import 'package:shakti_saree/admin/styles/app_colors.dart';
import 'package:shakti_saree/admin/widgets/navigation/admin_bottom_nav.dart';
import 'package:shakti_saree/main.dart';
import 'package:shakti_saree/user/screens/login_screen.dart';

/// The app as main() starts it: the customer side's MaterialApp, on the
/// default theme, with the admin a route pushed from the login form.
Widget _app() => const ProviderScope(child: ShaktiSaree());

/// A phone a little wider than the other tests use: at 390 the test font
/// pushes the login form's 'Admin Login' past its half of the toggle, which
/// the framework reports as an overflow. Tall enough that every new order's
/// card builds.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Material 3's baseline primary — what the default theme gives anything
/// that takes its colour from the theme, and what the admin's buttons were
/// wearing instead of maroon.
const Color _defaultPurple = Color(0xFF6750A4);

/// The login form's two inputs, found by what they ask for.
Finder get _emailField =>
    find.widgetWithText(TextField, 'Enter Your Email Address');

Finder get _passwordField => find.widgetWithText(TextField, '••••••••');

/// The Material a button paints itself with: its fill, and its outline as the
/// side of its shape.
Material _materialOf(WidgetTester tester, Finder button) => tester
    .widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    );

/// The colour a button is filled with.
Color? _fillOf(WidgetTester tester, Finder button) =>
    _materialOf(tester, button).color;

/// The colour a button's outline is drawn in.
Color? _outlineOf(WidgetTester tester, Finder button) =>
    (_materialOf(tester, button).shape as OutlinedBorder?)?.side.color;

/// The colour a button's label is drawn in.
Color? _labelOf(WidgetTester tester, Finder button) => tester
    .widget<RichText>(
      find.descendant(of: button, matching: find.byType(RichText)).first,
    )
    .text
    .style
    ?.color;

/// Asserts the login form is drawn the way the customer side was laid out:
/// on the default theme, so the email field has no fill of its own and a
/// purple caret. Either one going maroon means the admin theme has reached
/// the customer side.
void _expectCustomerLogin(WidgetTester tester) {
  expect(find.byType(LoginScreen), findsOneWidget);
  expect(
    tester
        .widget<InputDecorator>(
          find.descendant(
            of: _emailField,
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration
        .filled,
    isFalse,
    reason: 'the login field should not pick up the admin field fill',
  );
  expect(
    tester
        .widget<EditableText>(
          find.descendant(of: _emailField, matching: find.byType(EditableText)),
        )
        .cursorColor,
    _defaultPurple,
    reason: 'the login caret should keep the default theme colour',
  );
}

/// The admin wears its own maroon, reached the way the app reaches it.
///
/// Every other admin test hosts its screen in a MaterialApp built on
/// AppTheme.light. The running app has not done that since the 2026-10-06
/// merge: the one MaterialApp left is the customer side's, on the default
/// theme, and the admin is a route pushed from the login form. Those tests
/// stayed green while every admin button went Material 3 purple.
///
/// So this one pumps the real app and signs in through the form. No
/// overrides: the admin reads the seeded stores, as it does when it runs.
/// The colours are read off what is painted — a button's fill, outline and
/// label — rather than off a Theme widget, so it holds however the admin's
/// routes bring their theme with them.
void main() {
  /// Past the splash and onto the login form, the way a cold start goes.
  Future<void> openLogin(WidgetTester tester) async {
    _phone(tester);
    await tester.pumpWidget(_app());

    // The splash hands over to the form on a 2.5 second timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  /// Signs in the way an admin does: switch the form to Admin, fill it in,
  /// press Login. The form only checks the shape of what is typed.
  Future<void> signInAsAdmin(WidgetTester tester) async {
    await openLogin(tester);

    await tester.tap(find.text('Admin Login'));
    await tester.pump();
    await tester.enterText(_emailField, 'admin@shaktisaree.com');
    await tester.enterText(_passwordField, 'Admin@123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminShell), findsOneWidget);
  }

  /// Moves to a tab by its icon in the bar, the way a thumb would.
  Future<void> openTab(WidgetTester tester, int index) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AdminBottomNav),
        matching: find.byIcon(AdminBottomNav.items[index].icon),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('signed in through the login form', () {
    testWidgets('the order cards wear the admin maroon', (tester) async {
      await signInAsAdmin(tester);
      await openTab(tester, AdminTab.orders);
      expect(find.byType(OrdersScreen), findsOneWidget);

      // The list opens on the new orders, and each card carries a filled
      // Accept beside an outlined View Details. Neither sets a colour of its
      // own, so both take it from the theme around them.
      final accept = find.widgetWithText(FilledButton, 'Accept').first;
      expect(
        _fillOf(tester, accept),
        AppColors.primary,
        reason: 'Accept should be filled in the admin maroon',
      );
      expect(
        _labelOf(tester, accept),
        AppColors.textOnPrimary,
        reason: 'Accept should be lettered in white',
      );

      final details = find.widgetWithText(OutlinedButton, 'View Details').first;
      expect(
        _labelOf(tester, details),
        AppColors.primary,
        reason: 'View Details should be lettered in the admin maroon',
      );
      expect(
        _outlineOf(tester, details),
        AppColors.primary,
        reason: 'View Details should be outlined in the admin maroon',
      );
    });

    testWidgets('so does a page pushed from inside the admin', (tester) async {
      await signInAsAdmin(tester);
      await openTab(tester, AdminTab.orders);

      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailScreen), findsOneWidget);

      // A pushed page is a route of its own, built beside the shell rather
      // than inside it, so theming the shell alone would leave this purple.
      expect(
        _fillOf(tester, find.widgetWithText(FilledButton, 'Accept Order')),
        AppColors.primary,
        reason: 'Accept Order should be filled in the admin maroon',
      );

      // A button that names its own colour keeps it: cancelling is
      // destructive, and says so in red rather than in the brand.
      expect(
        _labelOf(tester, find.widgetWithText(TextButton, 'Cancel Order')),
        AppColors.error,
        reason: 'Cancel Order should keep its own red',
      );
    });
  });

  // The app-wide theme belongs to the customer side, so the admin's colours
  // have to travel with the admin's own routes. Re-theming the whole app
  // would pass the two tests above and repaint the customer side with them.
  group('the customer side', () {
    testWidgets('keeps the default theme it was laid out on', (tester) async {
      await openLogin(tester);

      _expectCustomerLogin(tester);
    });

    testWidgets('gets it back after an admin logs out', (tester) async {
      await signInAsAdmin(tester);
      await openTab(tester, AdminBottomNav.items.length - 1);
      expect(find.byType(MoreScreen), findsOneWidget);

      // Logging out leaves the admin for the customer's login form, so that
      // route is the customer's, not the admin's.
      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsNothing);
      _expectCustomerLogin(tester);
    });
  });
}
