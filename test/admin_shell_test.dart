import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/screens/categories_screen.dart';
import 'package:shakti_saree/admin/screens/more_screen.dart';
import 'package:shakti_saree/admin/data/admin_tab.dart';
import 'package:shakti_saree/admin/models/order_status.dart';
import 'package:shakti_saree/admin/screens/admin_shell.dart';
import 'package:shakti_saree/admin/widgets/orders/status_filter_chips.dart';
import 'package:shakti_saree/admin/widgets/navigation/admin_bottom_nav.dart';
import 'package:shakti_saree/admin/styles/app_theme.dart';
import 'package:shakti_saree/admin/data/mock/mock_data.dart';

/// Drives the real shell, so the bottom bar and the headers' back arrows are
/// exercised against the same tab state the app runs on.
void main() {
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

  testWidgets("the dashboard's 'View all' opens the Orders tab", (
    tester,
  ) async {
    await pumpShell(tester);
    final container = containerOf(tester);

    // Starts on the dashboard, where the recent-orders strip lives.
    expect(container.read(adminTabProvider), AdminTab.home);

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    // The tab, not a pushed route: the bar has to agree with what is on
    // screen, which a route over the top of it would not.
    expect(container.read(adminTabProvider), AdminTab.orders);
    expect(find.text('Orders'), findsWidgets);
  });

  group('swiping the pages', () {
    /// A drag across the pages, far enough to settle on the next one.
    Future<void> swipe(WidgetTester tester, {required bool forward}) async {
      await tester.drag(
        find.byType(TabBarView),
        Offset(forward ? -400 : 400, 0),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('left walks forward and the bar keeps up', (tester) async {
      await pumpShell(tester);
      final container = containerOf(tester);

      // All the way out to the last tab, one swipe at a time. The bar is
      // driven off the same state, so if it ever disagreed with the page
      // this would catch it.
      for (var expected = 1; expected < AdminBottomNav.items.length;
          expected++) {
        await swipe(tester, forward: true);
        expect(
          container.read(adminTabProvider),
          expected,
          reason: 'swipe $expected should land on tab $expected',
        );
        expect(
          tester.widget<AdminBottomNav>(find.byType(AdminBottomNav))
              .currentIndex,
          expected,
          reason: 'the bar should follow the swipe',
        );
      }
    });

    testWidgets('right walks back again', (tester) async {
      await pumpShell(tester);
      final container = containerOf(tester);

      await swipe(tester, forward: true);
      await swipe(tester, forward: true);
      expect(container.read(adminTabProvider), 2);

      await swipe(tester, forward: false);
      expect(container.read(adminTabProvider), 1);
    });

    testWidgets('a tab keeps its state while another is showing', (
      tester,
    ) async {
      await pumpShell(tester);
      final container = containerOf(tester);

      container.read(adminTabProvider.notifier).select(AdminTab.orders);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accepted'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StatusFilterChips>(find.byType(StatusFilterChips))
            .selected,
        OrderStatus.accepted,
      );

      // Away and back. A TabBarView throws its off-screen pages away, so
      // without the keep-alive the chip would be back on New.
      await swipe(tester, forward: true);
      await swipe(tester, forward: false);

      expect(container.read(adminTabProvider), AdminTab.orders);
      expect(
        tester.widget<StatusFilterChips>(find.byType(StatusFilterChips))
            .selected,
        OrderStatus.accepted,
        reason: 'the filter should have survived the swipe away',
      );
    });

    testWidgets('a page keeps its controls separately labelled', (
      tester,
    ) async {
      // A page inside a TabBarView has its semantics merged unless something
      // stops it, which once collapsed the whole header into one node that a
      // screen reader read as "Back Orders 3 new today".
      final handle = tester.ensureSemantics();
      await pumpShell(tester);

      containerOf(tester).read(adminTabProvider.notifier).select(
            AdminTab.orders,
          );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Back')).label, 'Back');
      handle.dispose();
    });
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

  testWidgets('the More tab is the settings page', (tester) async {
    await pumpShell(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AdminBottomNav),
        matching: find.byIcon(AdminBottomNav.items[4].icon),
      ),
    );
    await tester.pumpAndSettle();

    // Signed-in admin, the two sections, and the way out — not the
    // categories list, which now sits behind this page.
    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.text(MockData.admin().email), findsOneWidget);
    expect(find.text('STORE'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byType(CategoriesScreen), findsNothing);
  });
}
