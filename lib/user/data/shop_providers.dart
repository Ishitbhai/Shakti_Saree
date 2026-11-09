import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/firestore/firestore_schema.dart';
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

// ---------------------------------------------------------------- customer profile & counts
/// Real-time stream of the current customer's Firestore profile document.
final customerProfileProvider = StreamProvider.autoDispose((ref) {
  final uid = ref.watch(customerUidProvider);
  final db = ref.watch(firestoreProvider);
  if (uid == null || db == null) return Stream.value(null);

  return db.collection(Fs.users).doc(uid).snapshots().map((doc) => doc.data());
});

/// Count of orders placed by the current customer.
final customerOrderCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(customerUidProvider);
  final db = ref.watch(firestoreProvider);
  if (uid == null || db == null) return Stream.value(0);

  return db
      .collection(Fs.orders)
      .where(Fs.userId, isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// ---------------------------------------------------------------- catalogue
final allProductsProvider = StreamProvider<List<ShopProduct>>(
  (ref) => ref.watch(shopRepositoryProvider).watchProducts(),
);

final allCategoriesProvider = StreamProvider<List<ShopCategory>>(
  (ref) => ref.watch(shopRepositoryProvider).watchCategories(),
);

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

final categoryNamesByIdProvider = Provider(
  (ref) => {
    for (final category
        in ref.watch(allCategoriesProvider).value ?? const <ShopCategory>[])
      category.id: category.name,
  },
);

final productProvider = StreamProvider.autoDispose.family<ShopProduct?, String>(
  (ref, docId) => ref.watch(shopRepositoryProvider).watchProduct(docId),
);

// --------------------------------------------------------------------- cart
final _cartIdProvider = StreamProvider.autoDispose<String?>((ref) async* {
  final repository = ref.watch(shopRepositoryProvider);
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

/// Real-time stream of all saved addresses under users/{uid}/addresses
final customerAddressesProvider = StreamProvider.autoDispose((ref) {
  final uid = ref.watch(customerUidProvider);
  final db = ref.watch(firestoreProvider);
  if (uid == null || db == null) return Stream.value([]);

  return db
      .collection(Fs.users)
      .doc(uid)
      .collection('addresses')
      .snapshots()
      .map((snapshot) => [
            for (final doc in snapshot.docs)
              {
                'id': doc.id,
                ...doc.data(),
              }
          ]);
});