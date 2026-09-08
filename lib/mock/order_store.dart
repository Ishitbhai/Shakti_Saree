import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/orders/order_detail.dart';
import '../admin/shared/models/order.dart';
import '../admin/shared/models/order_status.dart';
import '../core/errors/api_exception.dart';
import 'mock_data.dart';

/// The app's one copy of the orders, standing in for the backend's database.
///
/// Every feature reads through this: the orders list, the filter chips, the
/// detail screen and the dashboard all see the same rows, so a status changed
/// in one place is the changed status everywhere. Nothing copies the list —
/// a second copy is a second answer to the same question.
///
/// Writing replaces the whole list, which is what makes that work: every
/// provider watching this recomputes on its own, and no screen has to
/// remember to tell another screen that something moved.
///
/// State lives only as long as the process. A restart re-seeds from
/// [MockData], which is the intended behaviour while there is no backend.
///
/// Legality is not decided here. A store is a place things are kept; whether
/// a given move is allowed is the repository's business, the same way a real
/// database would take the write its endpoint had already approved.
class OrderStore extends Notifier<List<OrderDetail>> {
  @override
  List<OrderDetail> build() => MockData.orders();

  /// Everything the store holds.
  ///
  /// `state` is the notifier's own business; this is how anything outside
  /// reads the rows.
  List<OrderDetail> get orders => List.unmodifiable(state);

  /// Every order as the list screen sees it.
  List<Order> get summaries => [
    for (final order in state) MockData.summaryOf(order),
  ];

  /// The most recent handful, for the dashboard strip.
  List<Order> recent(int count) => summaries.take(count).toList();

  /// The stored order, or a [NotFound] if there is no such id.
  OrderDetail find(String id) => state[_indexOf(id)];

  /// Records a transition against the stored order and answers with what it
  /// became.
  ///
  /// The timestamp is taken here, at the moment of the write, so the timeline
  /// reads as when the tap actually happened rather than when the data was
  /// seeded. Anything not supplied is carried over untouched.
  OrderDetail write(
    String id,
    OrderStatus to, {
    String? courier,
    String? awbNumber,
    String? cancellationReason,
  }) {
    final index = _indexOf(id);
    final current = state[index];

    final updated = OrderDetail(
      id: current.id,
      customer: current.customer,
      phone: current.phone,
      address: current.address,
      placedAt: current.placedAt,
      status: to,
      reachedAt: {...current.reachedAt, to: DateTime.now()},
      lines: current.lines,
      paidVia: current.paidVia,
      deliveryPaise: current.deliveryPaise,
      discountPaise: current.discountPaise,
      courier: courier ?? current.courier,
      awbNumber: awbNumber ?? current.awbNumber,
      cancellationReason: cancellationReason ?? current.cancellationReason,
    );

    // A new list rather than a mutation in place: that is the signal every
    // watcher is waiting on.
    state = [...state]..[index] = updated;
    return updated;
  }

  int _indexOf(String id) {
    final index = state.indexWhere((candidate) => candidate.id == id);
    // Repositories are documented to surface ApiException, so an unknown id
    // reads as the 404 it would be against a real backend rather than as a
    // StateError nothing above here is prepared to catch.
    if (index == -1) throw const NotFound();
    return index;
  }
}

/// The single store, alive for as long as the app is.
///
/// Not auto-disposing — the default in Riverpod 3 — so switching tabs away
/// from the orders list does not quietly throw away everything the admin has
/// done since launch.
final orderStoreProvider = NotifierProvider<OrderStore, List<OrderDetail>>(
  OrderStore.new,
);
