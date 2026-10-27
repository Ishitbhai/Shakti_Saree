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
      expect(stored['status'], 'Shipped');
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
