import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_providers.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_repository.dart';
import 'package:shakti_saree/admin/dashboard/dashboard_screen.dart';
import 'package:shakti_saree/admin/orders/order_detail.dart';
import 'package:shakti_saree/admin/orders/orders_providers.dart';
import 'package:shakti_saree/admin/orders/orders_repository.dart';
import 'package:shakti_saree/admin/orders/orders_screen.dart';
import 'package:shakti_saree/admin/orders/widgets/order_card.dart';
import 'package:shakti_saree/admin/shared/models/order.dart';
import 'package:shakti_saree/core/errors/api_exception.dart';
import 'package:shakti_saree/core/theme/app_theme.dart';

class _FailingOrders implements OrdersRepository {
  @override
  Future<List<Order>> fetchOrders() async => throw const RequestTimeout();

  @override
  Future<OrderDetail> fetchOrderDetail(String id) async =>
      throw const RequestTimeout();
}

class _FailingDashboard implements DashboardRepository {
  @override
  Future<List<Order>> fetchRecentOrders() async =>
      throw const NetworkUnavailable();
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
    testWidgets('renders exactly what it rendered before', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const OrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('2 new today'), findsOneWidget);
      expect(find.byType(OrderCard), findsNWidgets(2));
      expect(find.text('#SS20260726'), findsOneWidget);
      expect(find.text('16 min ago'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('₹6,297'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Accept'), findsNWidgets(2));
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

      expect(find.text('#SS20260724'), findsOneWidget);
      expect(find.text('Ship'), findsOneWidget);

      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Items (2)'), findsOneWidget);
      expect(find.text('Mark Shipped'), findsOneWidget);
    });

    testWidgets('an empty status still says so', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const OrdersScreen()));
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

  group('dashboard', () {
    testWidgets('recent orders strip is unchanged', (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recent Orders'), findsOneWidget);
      expect(find.text('Priyanshu K.  •  3 items'), findsOneWidget);
      expect(find.text('Vivek M.  •  3 items'), findsOneWidget);
      expect(find.text('₹6,297'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Packed'), findsOneWidget);
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

      // The KPI figures still come from the widget, so they survive.
      expect(find.text('1,248'), findsOneWidget);
      expect(find.text('2,150'), findsOneWidget);
      expect(find.text(const NetworkUnavailable().message), findsOneWidget);
    });
  });
}
