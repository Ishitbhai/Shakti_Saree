import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/order.dart';
import 'dashboard_repository.dart';

/// The dashboard source. Overridden in tests and, later, swapped for the HTTP
/// implementation in one place.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => const InMemoryDashboardRepository(),
);

/// The recent-orders strip under the monogram.
final recentOrdersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchRecentOrders(),
);
