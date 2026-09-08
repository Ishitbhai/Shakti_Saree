import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_providers.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_repository.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_screen.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_stats.dart';
import 'package:shakti_saree/admin/orders/order_detail.dart';
import 'package:shakti_saree/admin/orders/orders_providers.dart';
import 'package:shakti_saree/admin/orders/orders_repository.dart';
import 'package:shakti_saree/admin/orders/orders_screen.dart';
import 'package:shakti_saree/admin/orders/widgets/order_card.dart';
import 'package:shakti_saree/admin/shared/models/order.dart';
import 'package:shakti_saree/admin/shared/models/order_status.dart';
import 'package:shakti_saree/core/errors/api_exception.dart';
import 'package:shakti_saree/mock/mock_data.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

/// Every read and every transition fails the same way.
class _FailingOrders implements OrdersRepository {
  @override
  Future<List<Order>> fetchOrders() async => throw const RequestTimeout();

  @override
  Future<OrderDetail> fetchOrderDetail(String id) async =>
      throw const RequestTimeout();

  @override
  Future<OrderDetail> acceptOrder(String id) async =>
      throw const RequestTimeout();

  @override
  Future<OrderDetail> markPacked(String id) async =>
      throw const RequestTimeout();

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) async => throw const RequestTimeout();

  @override
  Future<OrderDetail> markDelivered(String id) async =>
      throw const RequestTimeout();

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) async =>
      throw const RequestTimeout();
}

/// Serves only the new orders from the sample data.
///
/// Every status in [MockData] has orders in it, by design, so the one thing
/// the real fixture cannot show is a filter that matches nothing. This trims
/// it down to make that case reachable again.
class _OnlyNewOrders implements OrdersRepository {
  @override
  Future<List<Order>> fetchOrders() async => [
    for (final order in MockData.summaries())
      if (order.status == OrderStatus.isNew) order,
  ];

  @override
  Future<OrderDetail> fetchOrderDetail(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> acceptOrder(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> markPacked(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> markShipped(
    String id, {
    required String courier,
    required String awbNumber,
  }) => throw UnimplementedError();

  @override
  Future<OrderDetail> markDelivered(String id) => throw UnimplementedError();

  @override
  Future<OrderDetail> cancelOrder(String id, {required String reason}) =>
      throw UnimplementedError();
}

/// The strip fails; the figures do not.
///
/// They are separate reads, and the point of the test below is that one
/// falling over does not take the other with it.
class _FailingDashboard implements DashboardRepository {
  @override
  Future<List<Order>> fetchRecentOrders() async =>
      throw const NetworkUnavailable();

  @override
  Future<DashboardStats> fetchStats() async =>
      const DashboardStats(totalOrders: 14, products: 5, customers: 14);
}

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 47)),
          child: child,
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('orders', () {
    testWidgets('renders a card per new order, in full', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();

      // Three of the sample orders are new, and the screen opens on them.
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('3 new today'), findsNWidgets(1));
      expect(find.byType(OrderCard), findsNWidgets(3));
      expect(find.text('Accept'), findsNWidgets(3));

      // The newest one, in full: number, age, phone, and the total after its
      // ₹500 discount.
      expect(find.text('#SS20260914'), findsOneWidget);
      expect(find.text('16 min ago'), findsOneWidget);
      expect(find.text('+91 98250 41267'), findsOneWidget);
      expect(find.text('₹4,149'), findsOneWidget);

      // The single-item order still reads in the singular.
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('filtering and the detail still work', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.bySemanticsLabel('Packed'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Packed'));
      await tester.pumpAndSettle();

      // Two orders are packed, and each offers the next move.
      expect(find.text('#SS20260909'), findsOneWidget);
      expect(find.text('Ship'), findsNWidgets(2));

      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();

      // #SS20260909 is a three-line order.
      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Items (3)'), findsOneWidget);
      expect(find.text('Mark Shipped'), findsOneWidget);
    });

    testWidgets('an empty status still says so', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Against a source with nothing delivered, since the full sample has
      // orders in every status.
      await tester.pumpWidget(
        _host(
          const OrdersScreen(),
          overrides: [
            ordersRepositoryProvider.overrideWithValue(_OnlyNewOrders()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.bySemanticsLabel('Delivered'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Delivered'));
      await tester.pumpAndSettle();

      expect(find.text('No delivered orders'), findsOneWidget);
      expect(find.byType(OrderCard), findsNothing);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const OrdersScreen(),
          overrides: [
            ordersRepositoryProvider.overrideWithValue(_FailingOrders()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(const RequestTimeout().message), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('one store behind both screens', () {
    test(
      'a transition on the orders side is what the dashboard reads',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final orders = container.read(ordersRepositoryProvider);
        final dashboard = container.read(dashboardRepositoryProvider);

        final before = await dashboard.fetchRecentOrders();
        expect(before.first.status, OrderStatus.isNew);

        await orders.acceptOrder(before.first.id);

        // Same order, moved on — not a second copy still saying 'New'.
        final after = await dashboard.fetchRecentOrders();
        expect(after.first.id, before.first.id);
        expect(after.first.status, OrderStatus.accepted);
      },
    );

    test(
      'the store keeps a transition for the life of the container',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final orders = container.read(ordersRepositoryProvider);
        final id = (await orders.fetchOrders()).first.id;

        await orders.acceptOrder(id);
        await orders.markPacked(id);

        // Read back through a fresh call, not the value the write returned.
        final reread = await orders.fetchOrderDetail(id);
        expect(reread.status, OrderStatus.packed);
        expect(reread.reachedAt.containsKey(OrderStatus.accepted), isTrue);
      },
    );

    testWidgets('the strip catches up after a transition elsewhere', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Three new and one accepted among the four newest.
      expect(find.text('New'), findsNWidgets(3));
      expect(find.text('Accepted'), findsOneWidget);

      // Accept one through the orders repository — the other screen's door
      // into the same store — without touching the dashboard at all.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DashboardScreen)),
        listen: false,
      );
      await container.read(ordersRepositoryProvider).acceptOrder('#SS20260914');
      await tester.pumpAndSettle();

      // The strip moved on its own; nothing invalidated it by hand.
      expect(find.text('New'), findsNWidgets(2));
      expect(find.text('Accepted'), findsNWidgets(2));
    });
  });

  group('dashboard', () {
    testWidgets('the strip shows the latest orders from the store', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recent Orders'), findsOneWidget);

      // The four newest sample orders, newest first, with their real totals.
      expect(find.text('Priyanshu Kateshiya  •  2 items'), findsOneWidget);
      expect(find.text('₹4,149'), findsOneWidget);
      expect(find.text('Meera Trivedi  •  1 item'), findsOneWidget);
      expect(find.text('Nidhi Chauhan  •  2 items'), findsOneWidget);

      // Far enough down the list to reach a second status.
      expect(find.text('New'), findsNWidgets(3));
      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('the KPI tiles count what the store holds', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Fourteen sample orders from fourteen distinct customers, against a
      // five-line catalogue. Nothing here is written down in the widget.
      expect(find.bySemanticsLabel('Total Orders, 14'), findsOneWidget);
      expect(find.bySemanticsLabel('Customers, 14'), findsOneWidget);
      expect(find.bySemanticsLabel('Products, 5'), findsOneWidget);
    });

    testWidgets('stat grid keeps rendering while orders fail', (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const DashboardScreen(),
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(_FailingDashboard()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Two separate reads: the figures survive a strip that could not load.
      expect(find.bySemanticsLabel('Total Orders, 14'), findsOneWidget);
      expect(find.bySemanticsLabel('Customers, 14'), findsOneWidget);
      expect(find.text(const NetworkUnavailable().message), findsOneWidget);
    });
  });
}
