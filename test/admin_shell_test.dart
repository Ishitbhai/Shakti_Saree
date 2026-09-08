import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/shared/admin_tab.dart';
import 'package:shakti_saree/admin/shell/admin_shell.dart';
import 'package:shakti_saree/admin/shell/widgets/admin_bottom_nav.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

/// Drives the real shell, so the bottom bar and the headers' back arrows are
/// exercised against the same tab state the app runs on.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const AdminShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(AdminShell)),
        listen: false,
      );

  /// The tab bodies all stay in the tree, so only the painted one counts.
  Finder visibleBack() => find.bySemanticsLabel('Back').hitTestable();

  testWidgets('the bottom bar switches tabs', (tester) async {
    await pumpShell(tester);
    final container = containerOf(tester);

    expect(container.read(adminTabProvider), AdminTab.home);

    await tester.tap(
      find.descendant(
        of: find.byType(AdminBottomNav),
        matching: find.byIcon(AdminBottomNav.items[2].icon),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(adminTabProvider), 2);
  });

  // Products and Orders are the two tabs that carry an AdminPageHeader.
  // Back steps one to the left in the bar, so each has its own destination.
  for (final step in const [
    (from: 'Orders', index: 2, to: 'Products', lands: 1),
    (from: 'Products', index: 1, to: 'Dashboard', lands: 0),
  ]) {
    testWidgets('back on ${step.from} goes to ${step.to}', (tester) async {
      await pumpShell(tester);
      final container = containerOf(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(AdminBottomNav),
          matching: find.byIcon(AdminBottomNav.items[step.index].icon),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(adminTabProvider), step.index);

      // The arrow is there and pressable, not a dead square.
      expect(visibleBack(), findsOneWidget);
      await tester.tap(visibleBack());
      await tester.pumpAndSettle();

      expect(
        container.read(adminTabProvider),
        step.lands,
        reason: 'back on ${step.from} should land on ${step.to}',
      );
    });
  }

  testWidgets('back walks all the way out one tab at a time', (tester) async {
    await pumpShell(tester);
    final container = containerOf(tester);

    container.read(adminTabProvider.notifier).select(2);
    await tester.pumpAndSettle();

    await tester.tap(visibleBack());
    await tester.pumpAndSettle();
    expect(container.read(adminTabProvider), 1, reason: 'Orders to Products');

    await tester.tap(visibleBack());
    await tester.pumpAndSettle();
    expect(
      container.read(adminTabProvider),
      AdminTab.home,
      reason: 'Products to Dashboard',
    );
  });

  testWidgets('the dashboard itself has no back arrow', (tester) async {
    await pumpShell(tester);

    // Nothing to go back to from home, and the dashboard has its own header
    // rather than an AdminPageHeader.
    expect(visibleBack(), findsNothing);
  });
}
