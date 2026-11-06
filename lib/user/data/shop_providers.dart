import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/providers/backend_providers.dart';
import '../models/shop_models.dart';
import 'customer_auth_repository.dart';
import 'shop_repository.dart';

/// Customer sign-in and registration, or null without Firebase, where the
/// login screen lets a customer straight in as it does an admin.
final customerAuthRepositoryProvider = Provider<CustomerAuthRepository?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final db = ref.watch(firestoreProvider);
  if (auth == null || db == null) return null;
  return CustomerAuthRepository(auth, db);
});

/// Unlike the admin panel there is no in-memory stand-in to fall back on: a
/// shopper is only ever shown what the database holds.
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  if (db == null) {
    throw StateError('The shop needs Firestore; main.dart provides it.');
  }
  return ShopRepository(db, ref.watch(firebaseAuthProvider));
});

/// Who is signed in, as Firebase Authentication reports it.
///
/// Auto-disposed because a stream nobody is listening to is only paused, and
/// a paused stream saves its events up. Kept alive, it would replay every
/// sign-in and sign-out from while the shop was closed on the next visit, and
/// the shop would take an old "signed out" for a new one. Disposed, each visit
/// starts from who Firebase says is signed in now.
final authUserProvider = StreamProvider.autoDispose<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth == null ? Stream.value(null) : auth.authStateChanges();
});

final customerUidProvider = Provider.autoDispose<String?>(
  (ref) => ref.watch(authUserProvider).value?.uid,
);

final customerNameProvider = StreamProvider.autoDispose<String>((ref) {
  final uid = ref.watch(customerUidProvider);
  if (uid == null) return Stream.value('');
  return ref.watch(shopRepositoryProvider).watchCustomerName(uid);
});

// ---------------------------------------------------------------- catalogue
// One listener per collection, shared by every screen, which filter what it
// delivers rather than each running a query of their own.

/// Every product, including those a shopper is not offered: a cart line still
/// has to find its product after the category has been hidden.
final allProductsProvider = StreamProvider<List<ShopProduct>>(
  (ref) => ref.watch(shopRepositoryProvider).watchProducts(),
);

final allCategoriesProvider = StreamProvider<List<ShopCategory>>(
  (ref) => ref.watch(shopRepositoryProvider).watchCategories(),
);

/// The products on offer: all but those filed under a hidden category, which
/// the admin panel promises shoppers will not see.
final shopProductsProvider = Provider<AsyncValue<List<ShopProduct>>>(
  (ref) => _both(
    ref.watch(allProductsProvider),
    ref.watch(allCategoriesProvider),
    (products, categories) {
      final hidden = {
        for (final category in categories)
          if (category.isHidden) category.id,
      };
      return [
        for (final product in products)
          if (!hidden.contains(product.categoryId)) product,
      ];
    },
  ),
);

/// The categories on offer, each with its product count.
final shopCategoriesProvider = Provider<AsyncValue<List<ShopCategory>>>(
  (ref) => _both(
    ref.watch(allCategoriesProvider),
    ref.watch(allProductsProvider),
    (categories, products) {
      final counts = <String, int>{};
      for (final product in products) {
        counts[product.categoryId] = (counts[product.categoryId] ?? 0) + 1;
      }
      return [
        for (final category in categories)
          if (!category.isHidden) category.withCount(counts[category.id] ?? 0),
      ];
    },
  ),
);

/// category_id → category_name, hidden categories included.
final categoryNamesByIdProvider = Provider<Map<String, String>>(
  (ref) => {
    for (final category
        in ref.watch(allCategoriesProvider).value ?? const <ShopCategory>[])
      category.id: category.name,
  },
);

/// One product, opened by its document id.
final productProvider = StreamProvider.autoDispose.family<ShopProduct?, String>(
  (ref, docId) => ref.watch(shopRepositoryProvider).watchProduct(docId),
);

// --------------------------------------------------------------------- cart
// All of these are auto-disposed, so a listener on one customer's cart never
// outlives the screens showing it, and the next person to sign in on the same
// device starts from nothing.

final _cartIdProvider = StreamProvider.autoDispose<String?>((ref) async* {
  final repository = ref.watch(shopRepositoryProvider);
  // Waited for rather than read, so the moment before Firebase has said who
  // is signed in shows as loading, not as an empty cart.
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* repository.watchCartId(user.uid);
});

final cartLinesProvider = StreamProvider.autoDispose<List<CartLine>>((
  ref,
) async* {
  final repository = ref.watch(shopRepositoryProvider);
  final cartId = await ref.watch(_cartIdProvider.future);
  if (cartId == null) {
    yield const [];
    return;
  }
  yield* repository.watchCartLines(cartId);
});

/// The signed-in customer's cart, each line with the product it points at.
final cartProvider = Provider.autoDispose<AsyncValue<List<CartEntry>>>(
  (ref) => _both(ref.watch(cartLinesProvider), ref.watch(allProductsProvider), (
    lines,
    products,
  ) {
    final byId = {for (final product in products) product.productId: product};
    return [
      for (final line in lines)
        CartEntry(line: line, product: byId[line.productId]),
    ];
  }),
);

// ------------------------------------------------------------------- search
/// What has been searched for this session, newest first.
///
/// Held in memory only: the database has nowhere to keep it, and the app has
/// no local storage. The login screen resets it, so one person's searches are
/// not shown to the next.
class RecentSearches extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String term) {
    if (!state.contains(term)) state = [term, ...state];
  }

  void remove(String term) {
    state = [
      for (final other in state)
        if (other != term) other,
    ];
  }

  void clear() => state = const [];
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

/// Two reads as one: failed if either failed, loaded once both have.
AsyncValue<R> _both<A, B, R>(
  AsyncValue<A> first,
  AsyncValue<B> second,
  R Function(A first, B second) combine,
) {
  for (final state in [first, second]) {
    if (state.hasError) {
      return AsyncError<R>(
        state.error!,
        state.stackTrace ?? StackTrace.current,
      );
    }
  }
  if (first.hasValue && second.hasValue) {
    return AsyncData(combine(first.requireValue, second.requireValue));
  }
  return AsyncLoading<R>();
}
