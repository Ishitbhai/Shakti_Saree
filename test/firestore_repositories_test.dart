import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti_saree/admin/data/api_exception.dart';
import 'package:shakti_saree/admin/data/firestore/firestore_schema.dart';
import 'package:shakti_saree/admin/data/mock/profile_store.dart';
import 'package:shakti_saree/admin/data/repositories/admin_auth_repository.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_categories_repository.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_customers_repository.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_dashboard_repository.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_orders_repository.dart';
import 'package:shakti_saree/admin/data/repositories/firestore_products_repository.dart';
import 'package:shakti_saree/admin/data/repositories/profile_repository.dart';
import 'package:shakti_saree/admin/data/repositories/support_repository.dart';
import 'package:shakti_saree/admin/models/admin_profile.dart';
import 'package:shakti_saree/admin/models/category.dart';
import 'package:shakti_saree/admin/models/customer.dart';
import 'package:shakti_saree/admin/models/order.dart';
import 'package:shakti_saree/admin/models/order_detail.dart';
import 'package:shakti_saree/admin/models/order_status.dart';
import 'package:shakti_saree/admin/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/firestore_seed.dart';

Future<Map<String, dynamic>> _only(
  FakeFirebaseFirestore db,
  String collection, {
  required String where,
  required Object equals,
}) async {
  final found = await db
      .collection(collection)
      .where(where, isEqualTo: equals)
      .get();
  expect(found.docs, hasLength(1));
  return found.docs.single.data();
}

void main() {
  group('schema', () {
    test('reads the statuses the database uses', () {
      expect(Fs.statusOf('Pending'), OrderStatus.isNew);
      expect(Fs.statusOf('confirmed'), OrderStatus.accepted);
      expect(Fs.statusOf('Canceled'), OrderStatus.cancelled);
      expect(Fs.statusValue(OrderStatus.isNew), 'Pending');
      expect(Fs.statusValue(OrderStatus.shipped), 'Shipped');
    });

    test('carries rupees to paise and back', () {
      expect(Fs.paiseOf(2499.0), 249900);
      expect(Fs.paiseOf(19.99), 1999);
      expect(Fs.paiseOf('120'), 12000);
      expect(Fs.rupeesOf(249900), 2499.0);
    });

    test('numbers new records after the highest one', () {
      expect(Fs.nextId('CAT', ['CAT_001', 'CAT_007', 'odd']), 'CAT_008');
      expect(Fs.nextId('CAT', const []), 'CAT_001');
    });
  });

  group('products', () {
    test('reads a product with its category by name', () async {
      final products = await FirestoreProductsRepository(
        await seededFirestore(),
      ).fetchProducts();

      final product = products.single;
      expect(product.name, 'Banarasi Silk Saree');
      expect(product.sku, 'PROD_001');
      expect(product.pricePaise, 249900);
      expect(product.stock, 15);
      expect(product.category, 'Silk Sarees');
      expect(product.image, 'assets/images/image1.png');
      expect(product.description, startsWith('Maroon pure Banarasi'));
    });

    test('creates in the database\'s own field names', () async {
      final db = await seededFirestore();
      await FirestoreProductsRepository(db).createProduct(
        const Product(
          name: 'Kanjivaram Saree',
          sku: 'PROD_002',
          pricePaise: 549950,
          stock: 4,
          category: 'Silk Sarees',
          description: 'Temple border',
        ),
      );

      final stored = await _only(
        db,
        'products',
        where: 'product_id',
        equals: 'PROD_002',
      );
      expect(stored['product_name'], 'Kanjivaram Saree');
      expect(stored['price'], 5499.5);
      expect(stored['stock_quantity'], 4);
      expect(stored['category_id'], 'CAT_001');
      expect(stored['description'], 'Temple border');
    });

    test('refuses a SKU already in use', () async {
      final repository = FirestoreProductsRepository(await seededFirestore());
      expect(
        repository.createProduct(
          const Product(
            name: 'Copy',
            sku: 'PROD_001',
            pricePaise: 100,
            stock: 1,
          ),
        ),
        throwsA(isA<BadRequest>()),
      );
    });

    test('an edit keeps the document and fields it does not touch', () async {
      final db = await seededFirestore();
      await db.collection('products').doc('g5ZYM2jLRvGGJJzRbL7w').update({
        'unrelated_field': 'kept',
      });
      final repository = FirestoreProductsRepository(db);
      final product = (await repository.fetchProducts()).single;

      await repository.updateProduct(
        originalSku: 'PROD_001',
        product: product.copyWith(name: 'Banarasi Silk Saree (Maroon)'),
      );

      final stored =
          (await db.collection('products').doc('g5ZYM2jLRvGGJJzRbL7w').get())
              .data()!;
      expect(stored['product_name'], 'Banarasi Silk Saree (Maroon)');
      expect(stored['unrelated_field'], 'kept');
      expect(stored['image'], 'assets/images/image1.png');
    });

    test('a renumbered product takes its cart and order lines along', () async {
      final db = await seededFirestore();
      final repository = FirestoreProductsRepository(db);
      final product = (await repository.fetchProducts()).single;

      await repository.updateProduct(
        originalSku: 'PROD_001',
        product: product.copyWith(sku: 'PROD_100'),
      );

      expect(
        (await _only(
          db,
          'order_items',
          where: 'order_id',
          equals: 'ORD_001',
        ))['product_id'],
        'PROD_100',
      );
      expect(
        (await _only(
          db,
          'cart_items',
          where: 'cart_id',
          equals: 'CART_001',
        ))['product_id'],
        'PROD_100',
      );
    });

    test('stock updates only what changed and refuses negatives', () async {
      final db = await seededFirestore();
      final repository = FirestoreProductsRepository(db);

      expect(await repository.updateStock({'PROD_001': 15}), 0);
      expect(await repository.updateStock({'PROD_001': 9, 'GONE': 3}), 1);
      expect((await repository.fetchProducts()).single.stock, 9);
      expect(
        repository.updateStock({'PROD_001': -1}),
        throwsA(isA<BadRequest>()),
      );
    });

    test('delete then undo puts back the same document', () async {
      final db = await seededFirestore();
      final repository = FirestoreProductsRepository(db);

      final removed = await repository.deleteProduct('PROD_001');
      expect(await repository.fetchProducts(), isEmpty);

      await repository.restoreProduct(removed);
      final back = await db
          .collection('products')
          .doc('g5ZYM2jLRvGGJJzRbL7w')
          .get();
      expect(back.exists, isTrue);
      expect(back.data()!['description'], startsWith('Maroon'));
    });
  });

  group('categories', () {
    test('counts the products filed under each', () async {
      final listings = await FirestoreCategoriesRepository(
        await seededFirestore(),
      ).fetchCategories();

      expect(listings.single.name, 'Silk Sarees');
      expect(listings.single.productCount, 1);
      expect(listings.single.isHidden, isFalse);
    });

    test('a new category gets the next id and a creation date', () async {
      final db = await seededFirestore();
      await FirestoreCategoriesRepository(
        db,
      ).createCategory(const Category(name: 'Cotton Sarees'));

      final stored = await _only(
        db,
        'categories',
        where: 'category_name',
        equals: 'Cotton Sarees',
      );
      expect(stored['category_id'], 'CAT_002');
      expect(stored['created_at'], isA<Timestamp>());
    });

    test('refuses a name already in use, whatever its case', () async {
      final repository = FirestoreCategoriesRepository(await seededFirestore());
      expect(
        repository.createCategory(const Category(name: 'silk sarees')),
        throwsA(isA<BadRequest>()),
      );
    });

    test('a rename leaves its products pointing at it', () async {
      final db = await seededFirestore();
      final categories = FirestoreCategoriesRepository(db);
      await categories.updateCategory(
        originalName: 'Silk Sarees',
        category: const Category(name: 'Pure Silk'),
      );

      final product = (await FirestoreProductsRepository(
        db,
      ).fetchProducts()).single;
      expect(product.category, 'Pure Silk');
    });

    test('hiding is stored and read back', () async {
      final db = await seededFirestore();
      final categories = FirestoreCategoriesRepository(db);
      await categories.setHidden('Silk Sarees', isHidden: true);
      expect((await categories.fetchCategories()).single.isHidden, isTrue);
    });

    test('a category that still holds products is not deleted', () async {
      final repository = FirestoreCategoriesRepository(await seededFirestore());
      expect(
        repository.deleteCategory('Silk Sarees'),
        throwsA(isA<BadRequest>()),
      );
    });

    test('an empty category deletes and comes back on undo', () async {
      final db = await seededFirestore();
      final repository = FirestoreCategoriesRepository(db);
      await repository.createCategory(const Category(name: 'Empty'));

      final removed = await repository.deleteCategory('Empty');
      expect(await repository.fetchCategories(), hasLength(1));
      await repository.restoreCategory(removed);
      expect(await repository.fetchCategories(), hasLength(2));
    });
  });

  group('orders', () {
    test('a summary joins the customer and the items', () async {
      final orders = await FirestoreOrdersRepository(
        await seededFirestore(),
      ).fetchOrders();

      final order = orders.single;
      expect(order.id, 'ORD_001');
      expect(order.customer, 'Ishitkumar Vadhavana');
      expect(order.itemCount, 1);
      expect(order.amountPaise, 249900);
      expect(order.status, OrderStatus.isNew);
      expect(order.placedAt?.toUtc(), DateTime.parse('2026-10-26T05:33:55Z'));
    });

    test('the detail joins lines, address and payment', () async {
      final detail = await FirestoreOrdersRepository(
        await seededFirestore(),
      ).fetchOrderDetail('ORD_001');

      expect(detail.customer, 'Ishitkumar Vadhavana');
      expect(detail.address, 'Rajkot, Gujarat');
      expect(detail.lines.single.name, 'Banarasi Silk Saree');
      expect(detail.lines.single.pricePaise, 249900);
      expect(detail.paidVia, 'Razor Pay');
      expect(detail.totalPaise, 249900);
      expect(detail.timeline.first.isDone, isTrue);
    });

    group('an order from the customer app', () {
      final placed = DateTime.utc(2026, 11, 2, 9, 30);

      /// Shaped as the customer app writes it: who it is for is on the order,
      /// and the account's document holds only an address.
      Future<FakeFirebaseFirestore> withCheckoutOrder({
        Object? delivery = const {
          'recipient_name': 'Asha Patel',
          'phone': '9876543210',
          'street': 'Kalawad Road',
          'pincode': '360005',
        },
        Map<String, dynamic> account = const {'street': 'Kalawad Road'},
      }) async {
        final db = await seededFirestore();
        await db.collection('users').doc('uidCheckout').set(account);
        await db.collection('orders').doc('ORD_CHECKOUT').set({
          'order_id': 'ORD_CHECKOUT',
          'user_id': 'uidCheckout',
          'total_amount': 12000,
          'created_at': Timestamp.fromDate(placed),
          'delivery_address': ?delivery,
        });
        return db;
      }

      Future<Order> summaryIn(FakeFirebaseFirestore db) async =>
          (await FirestoreOrdersRepository(
            db,
          ).fetchOrders()).firstWhere((order) => order.id == 'ORD_CHECKOUT');

      test('is listed under the name, number and time given', () async {
        final order = await summaryIn(await withCheckoutOrder());

        expect(order.customer, 'Asha Patel');
        expect(order.phone, '9876543210');
        expect(order.placedAt?.toUtc(), placed);
      });

      test('says the same on its detail screen', () async {
        final detail = await FirestoreOrdersRepository(
          await withCheckoutOrder(),
        ).fetchOrderDetail('ORD_CHECKOUT');

        expect(detail.customer, 'Asha Patel');
        expect(detail.phone, '9876543210');
        expect(detail.placedAt.toUtc(), placed);
      });

      test('sorts by when it was placed', () async {
        final orders = await FirestoreOrdersRepository(
          await withCheckoutOrder(),
        ).fetchOrders();

        // Newer than the seeded order, so first rather than dropped last.
        expect(orders.first.id, 'ORD_CHECKOUT');
      });

      test('falls back to the account, then the id', () async {
        final onAccount = await summaryIn(
          await withCheckoutOrder(
            delivery: const {'recipient_name': ' ', 'phone': ''},
            account: const {'name': 'Asha P', 'phone': '9000011111'},
          ),
        );
        expect(onAccount.customer, 'Asha P');
        expect(onAccount.phone, '9000011111');

        final nothing = await summaryIn(
          await withCheckoutOrder(delivery: 'Kalawad Road, Rajkot'),
        );
        expect(nothing.customer, 'uidCheckout');
        expect(nothing.phone, isNull);
      });
    });

    group('cash on delivery', () {
      /// Shaped as the customer app writes it: the method and status on the
      /// order, and again on its own document in `payments`.
      Future<FakeFirebaseFirestore> withOrder({
        String orderStatus = 'Shipped',
        String method = 'COD',
        String? onOrder = 'Pending',
        String? onPayment = 'Pending',
        bool hasPayment = true,
      }) async {
        final db = FakeFirebaseFirestore();
        await db.collection('orders').doc('ORD_CASH').set({
          'order_id': 'ORD_CASH',
          'user_id': 'uidCash',
          'total_amount': 12000,
          'order_status': orderStatus,
          'payment_method': method,
          'payment_status': ?onOrder,
          'created_at': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
        });
        if (hasPayment) {
          await db.collection('payments').doc('payCash').set({
            'payment_id': 'PAY_CASH',
            'order_id': 'ORD_CASH',
            'user_id': 'uidCash',
            'amount': 12000,
            'payment_method': method,
            'payment_status': ?onPayment,
            'created_at': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
          });
        }
        return db;
      }

      Future<Map<String, dynamic>> orderIn(FakeFirebaseFirestore db) async =>
          (await db.collection('orders').doc('ORD_CASH').get()).data()!;

      Future<Map<String, dynamic>> paymentIn(FakeFirebaseFirestore db) async =>
          (await db.collection('payments').doc('payCash').get()).data()!;

      String acceptedStepOf(OrderDetail detail) => detail.timeline
          .firstWhere((event) => event.status == OrderStatus.accepted)
          .label;

      test('accepting it confirms the order, not a payment', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder(orderStatus: 'Accepted'),
        ).fetchOrderDetail('ORD_CASH');

        expect(detail.isCashOnDelivery, isTrue);
        expect(acceptedStepOf(detail), 'Order Confirmed');
      });

      test('an order paid online confirms its payment', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder(
            orderStatus: 'Accepted',
            method: 'UPI',
            onOrder: 'Paid',
            onPayment: 'Success',
          ),
        ).fetchOrderDetail('ORD_CASH');

        expect(detail.isCashOnDelivery, isFalse);
        expect(acceptedStepOf(detail), 'Payment Confirmed');
      });

      test('goes by the order where there is no payments document', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder(orderStatus: 'Accepted', hasPayment: false),
        ).fetchOrderDetail('ORD_CASH');

        expect(acceptedStepOf(detail), 'Order Confirmed');
      });

      test('the payments document decides between the two', () async {
        final db = await withOrder(orderStatus: 'Accepted');
        await db.collection('payments').doc('payCash').update({
          'payment_method': 'UPI',
        });

        final detail = await FirestoreOrdersRepository(
          db,
        ).fetchOrderDetail('ORD_CASH');

        expect(acceptedStepOf(detail), 'Payment Confirmed');
      });

      test('delivering it settles the order and the payment', () async {
        final db = await withOrder();

        final delivered = await FirestoreOrdersRepository(
          db,
        ).markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Paid');
        expect((await paymentIn(db))['payment_status'], 'Success');
        expect(delivered.paidVia, 'COD');
      });

      test('says pending until it is delivered', () async {
        final db = await withOrder(orderStatus: 'Pending');
        final repository = FirestoreOrdersRepository(db);

        final accepted = await repository.acceptOrder('ORD_CASH');
        final packed = await repository.markPacked('ORD_CASH');
        final shipped = await repository.markShipped(
          'ORD_CASH',
          courier: 'Blue Dart',
          awbNumber: 'NEW123456',
        );

        for (final step in [accepted, packed, shipped]) {
          expect(step.paidVia, 'COD (Pending)');
        }
        expect((await orderIn(db))['payment_status'], 'Pending');
        expect((await paymentIn(db))['payment_status'], 'Pending');
      });

      test('cancelling it does not mark it paid', () async {
        final db = await withOrder(orderStatus: 'Pending');

        final cancelled = await FirestoreOrdersRepository(
          db,
        ).cancelOrder('ORD_CASH', reason: 'Out of stock');

        expect(cancelled.paidVia, 'COD (Pending)');
        expect((await orderIn(db))['payment_status'], 'Pending');
        expect((await paymentIn(db))['payment_status'], 'Pending');
      });

      test('a refused delivery settles nothing', () async {
        final db = await withOrder(orderStatus: 'Packed');

        await expectLater(
          FirestoreOrdersRepository(db).markDelivered('ORD_CASH'),
          throwsA(isA<BadRequest>()),
        );

        expect((await orderIn(db))['payment_status'], 'Pending');
        expect((await paymentIn(db))['payment_status'], 'Pending');
      });

      test('an order paid online is left as it was', () async {
        final db = await withOrder(
          method: 'UPI',
          onOrder: 'Paid',
          onPayment: 'Success',
        );

        final delivered = await FirestoreOrdersRepository(
          db,
        ).markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Paid');
        expect((await paymentIn(db))['payment_status'], 'Success');
        expect(delivered.paidVia, 'UPI');
      });

      test('an online payment still pending is not taken as paid', () async {
        final db = await withOrder(method: 'UPI');

        final delivered = await FirestoreOrdersRepository(
          db,
        ).markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Pending');
        expect((await paymentIn(db))['payment_status'], 'Pending');
        expect(delivered.paidVia, 'UPI (Pending)');
      });

      test('a failed payment is not written over', () async {
        final db = await withOrder(onOrder: 'Failed', onPayment: 'Failed');

        final delivered = await FirestoreOrdersRepository(
          db,
        ).markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Failed');
        expect((await paymentIn(db))['payment_status'], 'Failed');
        expect(delivered.paidVia, 'COD (Failed)');
      });

      test(
        'one delivered earlier reads as paid, and is not rewritten',
        () async {
          final db = await withOrder(orderStatus: 'Delivered');

          final detail = await FirestoreOrdersRepository(
            db,
          ).fetchOrderDetail('ORD_CASH');

          expect(detail.paidVia, 'COD');
          expect((await orderIn(db))['payment_status'], 'Pending');
          expect((await paymentIn(db))['payment_status'], 'Pending');
        },
      );

      test('settles an order with no document in payments', () async {
        final db = await withOrder(hasPayment: false);
        final repository = FirestoreOrdersRepository(db);

        expect(
          (await repository.fetchOrderDetail('ORD_CASH')).paidVia,
          'COD (Pending)',
        );

        final delivered = await repository.markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Paid');
        expect(delivered.paidVia, 'COD');
      });

      test('adds no payment_status to an order without one', () async {
        final db = await withOrder(onOrder: null);

        await FirestoreOrdersRepository(db).markDelivered('ORD_CASH');

        expect((await orderIn(db)).containsKey('payment_status'), isFalse);
        expect((await paymentIn(db))['payment_status'], 'Success');
      });

      test('finds the payment by payment_id where the order has one', () async {
        final db = await withOrder();
        await db.collection('orders').doc('ORD_CASH').update({
          'payment_id': 'PAY_CASH',
        });
        await db.collection('payments').doc('payCash').update({
          'order_id': 'SOMETHING_ELSE',
        });

        await FirestoreOrdersRepository(db).markDelivered('ORD_CASH');

        expect((await paymentIn(db))['payment_status'], 'Success');
      });

      test(
        'an online payment on record outranks the order saying COD',
        () async {
          final db = await withOrder();
          await db.collection('payments').doc('payCash').update({
            'payment_method': 'UPI',
          });

          final delivered = await FirestoreOrdersRepository(
            db,
          ).markDelivered('ORD_CASH');

          expect((await orderIn(db))['payment_status'], 'Pending');
          expect((await paymentIn(db))['payment_status'], 'Pending');
          expect(delivered.paidVia, 'UPI (Pending)');
        },
      );

      test('COD on record outranks the order saying otherwise', () async {
        final db = await withOrder(method: 'UPI');
        await db.collection('payments').doc('payCash').update({
          'payment_method': 'COD',
        });

        final delivered = await FirestoreOrdersRepository(
          db,
        ).markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Paid');
        expect((await paymentIn(db))['payment_status'], 'Success');
        expect(delivered.paidVia, 'COD');
      });

      test('settles from pending in any case', () async {
        final db = await withOrder(onOrder: 'pending', onPayment: 'PENDING');

        final delivered = await FirestoreOrdersRepository(
          db,
        ).markDelivered('ORD_CASH');

        expect((await orderIn(db))['payment_status'], 'Paid');
        expect((await paymentIn(db))['payment_status'], 'Success');
        expect(delivered.paidVia, 'COD');
      });

      test('one delivered earlier reads as paid in any case', () async {
        final db = await withOrder(
          orderStatus: 'Delivered',
          onOrder: 'pending',
          onPayment: 'PENDING',
        );

        final detail = await FirestoreOrdersRepository(
          db,
        ).fetchOrderDetail('ORD_CASH');

        expect(detail.paidVia, 'COD');
      });

      test('recognises the method however it is spelled', () {
        for (final method in [
          'COD',
          'cod',
          ' Cod ',
          'C.O.D',
          'Cash on Delivery',
          'cash_on_delivery',
          'CashOnDelivery',
        ]) {
          expect(Fs.isCashOnDelivery(method), isTrue, reason: method);
        }
        for (final method in ['UPI', 'Card', 'Razor Pay', 'Cash', '', null]) {
          expect(Fs.isCashOnDelivery(method), isFalse, reason: '$method');
        }
      });
    });

    group('order_status', () {
      final at = Timestamp.fromDate(DateTime.utc(2026, 11, 2, 9, 30));

      /// Every step on record, as on an order the panel finished while it was
      /// still writing `status`.
      final finished = {
        'status': 'Delivered',
        'status_history': {
          'Accepted': at,
          'Packed': at,
          'Shipped': at,
          'Delivered': at,
        },
        'courier': 'Delhivery',
        'awb_number': 'OLD123456',
      };

      Future<FakeFirebaseFirestore> withOrder(
        Map<String, dynamic> fields,
      ) async {
        final db = await seededFirestore();
        await db.collection('orders').doc('ORD_STATUS').set({
          'order_id': 'ORD_STATUS',
          'user_id': 'UID_123',
          'total_amount': 1000.0,
          'created_at': Timestamp.fromDate(DateTime.utc(2026, 11, 1)),
          ...fields,
        });
        return db;
      }

      Future<Map<String, dynamic>> stored(FakeFirebaseFirestore db) async =>
          (await db.collection('orders').doc('ORD_STATUS').get()).data()!;

      Future<OrderStatus> listedAs(FakeFirebaseFirestore db) async =>
          (await FirestoreOrdersRepository(
            db,
          ).fetchOrders()).firstWhere((o) => o.id == 'ORD_STATUS').status;

      List<OrderStatus> done(OrderDetail detail) => [
        for (final event in detail.timeline)
          if (event.isDone) event.status,
      ];

      test('a cancelled order does not claim an earlier run', () async {
        final cancelled = await FirestoreOrdersRepository(
          await withOrder({'order_status': 'Pending', ...finished}),
        ).cancelOrder('ORD_STATUS', reason: 'Out of stock');

        expect(done(cancelled), [OrderStatus.isNew, OrderStatus.cancelled]);
        expect(cancelled.courier, isNull);
        expect(cancelled.awbNumber, isNull);
      });

      test('nor once it has been taken part of the way again', () async {
        final repository = FirestoreOrdersRepository(
          await withOrder({'order_status': 'Pending', ...finished}),
        );

        await repository.acceptOrder('ORD_STATUS');
        final cancelled = await repository.cancelOrder(
          'ORD_STATUS',
          reason: 'Out of stock',
        );

        expect(done(cancelled), [
          OrderStatus.isNew,
          OrderStatus.accepted,
          OrderStatus.cancelled,
        ]);
      });

      test('a cancelled order keeps the steps it went through', () async {
        final repository = FirestoreOrdersRepository(
          await withOrder({'order_status': 'Pending'}),
        );

        await repository.acceptOrder('ORD_STATUS');
        await repository.markPacked('ORD_STATUS');
        final cancelled = await repository.cancelOrder(
          'ORD_STATUS',
          reason: 'Out of stock',
        );

        expect(done(cancelled), [
          OrderStatus.isNew,
          OrderStatus.accepted,
          OrderStatus.packed,
          OrderStatus.cancelled,
        ]);
      });

      test('a status set by hand ticks the steps up to it', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder({'order_status': 'Shipped'}),
        ).fetchOrderDetail('ORD_STATUS');

        expect(done(detail), [
          OrderStatus.isNew,
          OrderStatus.accepted,
          OrderStatus.packed,
          OrderStatus.shipped,
        ]);
      });

      test('a courier on record stays hidden until it has shipped', () async {
        for (final stage in ['Accepted', 'Packed']) {
          final detail = await FirestoreOrdersRepository(
            await withOrder({'order_status': stage, ...finished}),
          ).fetchOrderDetail('ORD_STATUS');

          expect(detail.courier, isNull, reason: stage);
          expect(detail.awbNumber, isNull, reason: stage);
        }
      });

      test('an order with only status moves on from there', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder({'status': 'Shipped'}),
        ).markDelivered('ORD_STATUS');

        expect(detail.status, OrderStatus.delivered);
      });

      test('the order screen reads an order with only status', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder({'status': 'Delivered'}),
        ).fetchOrderDetail('ORD_STATUS');

        expect(detail.status, OrderStatus.delivered);
      });

      test('cancelled under status alone is not money spent', () async {
        final db = await withOrder({'status': 'Cancelled'});

        final customer = (await FirestoreCustomersRepository(
          db,
          FirestoreOrdersRepository(db),
        ).fetchCustomers()).single;

        expect(customer.spentPaise, 249900);
      });

      test('decides over an older status beside it', () async {
        final db = await withOrder({
          'order_status': 'Shipped',
          'status': 'Delivered',
        });

        expect(await listedAs(db), OrderStatus.shipped);
        expect(
          (await FirestoreOrdersRepository(
            db,
          ).fetchOrderDetail('ORD_STATUS')).status,
          OrderStatus.shipped,
        );
      });

      test('gives way to status only when there is none', () async {
        for (final fields in <Map<String, dynamic>>[
          {'status': 'Delivered'},
          {'status': 'Delivered', 'order_status': null},
          {'status': 'Delivered', 'order_status': '  '},
        ]) {
          expect(
            await listedAs(await withOrder(fields)),
            OrderStatus.delivered,
          );
        }
      });

      test('takes every step, and leaves status as it was', () async {
        final db = await withOrder({'order_status': 'Pending', ...finished});
        final repository = FirestoreOrdersRepository(db);

        await repository.acceptOrder('ORD_STATUS');
        expect((await stored(db))['order_status'], 'Accepted');

        await repository.markPacked('ORD_STATUS');
        expect((await stored(db))['order_status'], 'Packed');

        await repository.markShipped(
          'ORD_STATUS',
          courier: 'Blue Dart',
          awbNumber: 'NEW123456',
        );
        expect((await stored(db))['order_status'], 'Shipped');

        final delivered = await repository.markDelivered('ORD_STATUS');
        expect(delivered.status, OrderStatus.delivered);
        expect((await stored(db))['order_status'], 'Delivered');
        expect(await listedAs(db), OrderStatus.delivered);

        expect((await stored(db))['status'], 'Delivered');
      });

      test('does not add a status to an order without one', () async {
        final db = await withOrder({'order_status': 'Pending'});

        await FirestoreOrdersRepository(db).acceptOrder('ORD_STATUS');

        final fields = await stored(db);
        expect(fields['order_status'], 'Accepted');
        expect(fields.containsKey('status'), isFalse);
      });

      test('is what the next step is judged by', () async {
        final behind = FirestoreOrdersRepository(
          await withOrder({'order_status': 'Pending', 'status': 'Shipped'}),
        );
        await expectLater(
          behind.markDelivered('ORD_STATUS'),
          throwsA(isA<BadRequest>()),
        );

        final ahead = FirestoreOrdersRepository(
          await withOrder({'order_status': 'Shipped', 'status': 'Pending'}),
        );
        expect(
          (await ahead.markDelivered('ORD_STATUS')).status,
          OrderStatus.delivered,
        );
      });

      test('takes a cancellation, which the spend then leaves out', () async {
        final db = await withOrder({
          'order_status': 'Pending',
          'status': 'Accepted',
        });
        final orders = FirestoreOrdersRepository(db);
        final customers = FirestoreCustomersRepository(db, orders);

        expect((await customers.fetchCustomers()).single.spentPaise, 349900);

        await orders.cancelOrder('ORD_STATUS', reason: 'Out of stock');

        final fields = await stored(db);
        expect(fields['order_status'], 'Cancelled');
        expect(fields['status'], 'Accepted');
        expect((await customers.fetchCustomers()).single.spentPaise, 249900);
      });

      test('an older cancelled status does not cancel the order', () async {
        final db = await withOrder({
          'order_status': 'Pending',
          'status': 'Cancelled',
        });

        final customer = (await FirestoreCustomersRepository(
          db,
          FirestoreOrdersRepository(db),
        ).fetchCustomers()).single;

        expect(customer.spentPaise, 349900);
      });

      test('the timeline stops where the order has got to', () async {
        final db = await withOrder({'order_status': 'Pending', ...finished});
        final repository = FirestoreOrdersRepository(db);

        final opened = await repository.fetchOrderDetail('ORD_STATUS');
        expect(opened.status, OrderStatus.isNew);
        expect(done(opened), [OrderStatus.isNew]);
        expect(opened.courier, isNull);
        expect(opened.awbNumber, isNull);

        final accepted = await repository.acceptOrder('ORD_STATUS');
        expect(done(accepted), [OrderStatus.isNew, OrderStatus.accepted]);

        await repository.markPacked('ORD_STATUS');
        final shipped = await repository.markShipped(
          'ORD_STATUS',
          courier: 'Blue Dart',
          awbNumber: 'NEW123456',
        );
        expect(done(shipped), [
          OrderStatus.isNew,
          OrderStatus.accepted,
          OrderStatus.packed,
          OrderStatus.shipped,
        ]);
        expect(shipped.courier, 'Blue Dart');
        expect(shipped.awbNumber, 'NEW123456');
      });

      test('a finished order keeps its whole timeline and courier', () async {
        final detail = await FirestoreOrdersRepository(
          await withOrder({'order_status': 'Delivered', ...finished}),
        ).fetchOrderDetail('ORD_STATUS');

        expect(detail.timeline.every((event) => event.isDone), isTrue);
        expect(detail.courier, 'Delhivery');
        expect(detail.awbNumber, 'OLD123456');
      });
    });

    test('an unknown order is a 404', () async {
      expect(
        FirestoreOrdersRepository(
          await seededFirestore(),
        ).fetchOrderDetail('NOPE'),
        throwsA(isA<NotFound>()),
      );
    });

    test('moves through the flow, recording each step', () async {
      final db = await seededFirestore();
      final repository = FirestoreOrdersRepository(db);

      await repository.acceptOrder('ORD_001');
      await repository.markPacked('ORD_001');
      final shipped = await repository.markShipped(
        'ORD_001',
        courier: 'Delhivery',
        awbNumber: 'AWB123456',
      );

      expect(shipped.status, OrderStatus.shipped);
      expect(shipped.courier, 'Delhivery');
      expect(shipped.awbNumber, 'AWB123456');

      final stored = await _only(
        db,
        'orders',
        where: 'order_id',
        equals: 'ORD_001',
      );
      expect(stored['order_status'], 'Shipped');
      expect(
        (stored['status_history'] as Map).keys,
        containsAll(['Accepted', 'Packed', 'Shipped']),
      );
      // Fields the panel does not own are left exactly as they were.
      expect(stored['total_amount'], 2499.0);
      expect(stored['payment_id'], 'PAY_001');
    });

    test('refuses a step out of order', () async {
      final repository = FirestoreOrdersRepository(await seededFirestore());
      expect(repository.markDelivered('ORD_001'), throwsA(isA<BadRequest>()));
    });

    test('cancels with a reason, but not once shipped', () async {
      final db = await seededFirestore();
      final repository = FirestoreOrdersRepository(db);

      final cancelled = await repository.cancelOrder(
        'ORD_001',
        reason: 'Customer requested',
      );
      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.cancellationReason, 'Customer requested');

      expect(
        repository.cancelOrder('ORD_001', reason: 'Again'),
        throwsA(isA<BadRequest>()),
      );
    });
  });

  group('customers and dashboard', () {
    test('customers come from users, with their spend', () async {
      final db = await seededFirestore();
      // An admin account is not a customer.
      await db.collection('users').doc('admin-uid').set({
        'name': 'Shop Admin',
        'email': 'admin@example.com',
        'user_type': 'admin',
      });
      final repository = FirestoreCustomersRepository(
        db,
        FirestoreOrdersRepository(db),
      );

      final customer = (await repository.fetchCustomers()).single;
      expect(customer.id, 'UID_123');
      expect(customer.name, 'Ishitkumar Vadhavana');
      expect(customer.phone, 'test@example.com');
      expect(customer.orderCount, 1);
      expect(customer.spentPaise, 249900);

      final theirs = await repository.fetchOrdersFor('UID_123');
      expect(theirs.single.id, 'ORD_001');
    });

    group('an account from the customer app', () {
      const saved = {
        'recipient_name': 'Asha Patel',
        'phone': '9876543210',
        'street': 'Kalawad Road',
      };

      Future<void> placeOrder(
        FakeFirebaseFirestore db,
        String id, {
        required DateTime at,
        required String name,
        required String phone,
        String userId = 'uidNameless',
      }) => db.collection('orders').doc(id).set({
        'order_id': id,
        'user_id': userId,
        'total_amount': 100.0,
        'order_status': 'Pending',
        'created_at': Timestamp.fromDate(at),
        'delivery_address': {'recipient_name': name, 'phone': phone},
      });

      Future<Customer> customerIn(
        FakeFirebaseFirestore db, [
        String id = 'uidNameless',
      ]) async => (await FirestoreCustomersRepository(
        db,
        FirestoreOrdersRepository(db),
      ).fetchCustomers()).firstWhere((customer) => customer.id == id);

      test('goes by the delivery address it saved', () async {
        final db = await seededFirestore();
        await db.collection('users').doc('uidNameless').set({
          'street': 'Kalawad Road',
          'delivery_address': saved,
        });
        await placeOrder(
          db,
          'ORD_A',
          at: DateTime.utc(2026, 11, 2),
          name: 'Someone Else',
          phone: '9000011111',
        );

        final customer = await customerIn(db);
        expect(customer.name, 'Asha Patel');
        expect(customer.phone, '9876543210');
      });

      test('then by its latest order', () async {
        final db = await seededFirestore();
        await db.collection('users').doc('uidNameless').set({
          'street': 'Kalawad Road',
        });
        await placeOrder(
          db,
          'ORD_OLD',
          at: DateTime.utc(2026, 11, 1),
          name: 'Old Name',
          phone: '9000011111',
        );
        await placeOrder(
          db,
          'ORD_NEW',
          at: DateTime.utc(2026, 11, 5),
          name: 'New Name',
          phone: '9000022222',
        );

        final customer = await customerIn(db);
        expect(customer.name, 'New Name');
        expect(customer.phone, '9000022222');
        expect(customer.orderCount, 2);
      });

      test('keeps its own name and number first', () async {
        final db = await seededFirestore();
        await db.collection('users').doc('uidNameless').set({
          'name': 'Account Name',
          'phone': '9000033333',
          'delivery_address': saved,
        });

        final customer = await customerIn(db);
        expect(customer.name, 'Account Name');
        expect(customer.phone, '9000033333');
      });

      test('prefers a number from an address over an email', () async {
        final db = await seededFirestore();
        await db.collection('users').doc('uidNameless').set({
          'name': 'Account Name',
          'email': 'asha@example.com',
          'delivery_address': saved,
        });

        expect((await customerIn(db)).phone, '9876543210');
      });

      test('falls back to the email, then the id', () async {
        final db = await seededFirestore();
        await db.collection('users').doc('uidNameless').set({
          'email': 'asha@example.com',
        });

        final customer = await customerIn(db);
        expect(customer.name, 'uidNameless');
        expect(customer.phone, 'asha@example.com');
      });

      test('an order with no account is named by its checkout', () async {
        final db = await seededFirestore();
        await placeOrder(
          db,
          'ORD_ORPHAN',
          at: DateTime.utc(2026, 11, 2),
          name: 'Asha Patel',
          phone: '9876543210',
          userId: 'uidNoAccount',
        );

        final customer = await customerIn(db, 'uidNoAccount');
        expect(customer.name, 'Asha Patel');
        expect(customer.phone, '9876543210');
      });
    });

    test('a cancelled order is not money spent', () async {
      final db = await seededFirestore();
      final orders = FirestoreOrdersRepository(db);
      await orders.cancelOrder('ORD_001', reason: 'Out of stock');

      final customer = (await FirestoreCustomersRepository(
        db,
        orders,
      ).fetchCustomers()).single;
      expect(customer.orderCount, 1);
      expect(customer.spentPaise, 0);
    });

    test('the dashboard counts what the lists show', () async {
      final db = await seededFirestore();
      final orders = FirestoreOrdersRepository(db);
      final dashboard = FirestoreDashboardRepository(
        db,
        orders,
        FirestoreCustomersRepository(db, orders),
      );

      final stats = await dashboard.fetchStats();
      expect(stats.totalOrders, 1);
      expect(stats.products, 1);
      expect(stats.customers, 1);
      expect((await dashboard.fetchRecentOrders()).single.id, 'ORD_001');
    });
  });

  group('support and profile', () {
    test('support queries name who sent them', () async {
      final tickets = await FirestoreSupportRepository(
        await seededFirestore(),
      ).fetchTickets();

      expect(tickets.single.subject, 'Delivery Delay');
      expect(tickets.single.customer, 'Ishitkumar Vadhavana');
    });

    test('an admin profile is read from and saved to users/{uid}', () async {
      final db = await seededFirestore();
      await db.collection('users').doc('admin-uid').set({
        'name': 'Shop Admin',
        'email': 'admin@example.com',
        'user_type': 'admin',
      });

      final profile = AdminAuthRepository.profileOf(
        (await db.collection('users').doc('admin-uid').get()).data()!,
      );
      expect(profile.name, 'Shop Admin');
      expect(profile.role, 'Admin');
      expect(profile.dateOfBirth, isNull);
      expect(profile.gender, isNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await FirestoreProfileRepository(
        db,
        'admin-uid',
        container.read(profileStoreProvider.notifier),
      ).saveProfile(
        AdminProfile(
          name: 'Shop Admin',
          email: 'admin@example.com',
          role: 'Admin',
          mobile: '9876543210',
          dateOfBirth: DateTime(1995, 4, 2),
          gender: Gender.female,
        ),
      );

      final stored = (await db.collection('users').doc('admin-uid').get())
          .data()!;
      expect(stored['phone'], '9876543210');
      expect(stored['gender'], 'female');
      expect(stored['user_type'], 'admin');
      expect(container.read(profileStoreProvider).mobile, '9876543210');
    });
  });
}
