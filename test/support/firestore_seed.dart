import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// An in-process fake Firestore seeded with one document per collection —
/// field for field, type for type, the shape of what the live `shakti-saree`
/// database holds. Nothing here touches the network.
Future<FakeFirebaseFirestore> seededFirestore() async {
  final db = FakeFirebaseFirestore();
  Timestamp at(String iso) => Timestamp.fromDate(DateTime.parse(iso));

  await db.collection('users').doc('4WrRymadAHRIoer9V95B').set({
    'user_id': 'UID_123',
    'name': 'Ishitkumar Vadhavana',
    'email': 'test@example.com',
    'address': 'Rajkot, Gujarat',
    'status': 'active',
    'user_type': 'customer',
    'registered_at': at('2026-10-26T05:07:09Z'),
  });
  await db.collection('categories').doc('MVr3vUNaKQoiojHxfzuu').set({
    'category_id': 'CAT_001',
    'category_name': 'Silk Sarees',
    'image': 'assets/images/image1.png',
    'created_at': at('2026-10-26T05:17:02Z'),
  });
  await db.collection('products').doc('g5ZYM2jLRvGGJJzRbL7w').set({
    'product_id': 'PROD_001',
    'product_name': 'Banarasi Silk Saree',
    'description': 'Maroon pure Banarasi silk saree with gold zari work',
    'price': 2499.0,
    'category_id': 'CAT_001',
    'image': 'assets/images/image1.png',
    'stock_quantity': 15,
  });
  await db.collection('carts').doc('DA36xO1tYsKgv9JQqvcN').set({
    'cart_id': 'CART_001',
    'user_id': 'UID_123',
    'created_at': at('2026-10-26T05:31:11Z'),
  });
  await db.collection('cart_items').doc('Go8u374EoVZjuUL1DTkB').set({
    'cart_item_id': 'ITEM_001',
    'cart_id': 'CART_001',
    'product_id': 'PROD_001',
    'quantity': 2,
  });
  await db.collection('orders').doc('L0nsDPpMhb3xeFyHzkpo').set({
    'order_id': 'ORD_001',
    'user_id': 'UID_123',
    'total_amount': 2499.0,
    'status': 'Pending',
    'order_date': at('2026-10-26T05:33:55Z'),
    'payment_id': 'PAY_001',
  });
  await db.collection('order_items').doc('APMsQEFw1CexXk3mUMRa').set({
    'order_item_id': 'OITEM_001',
    'order_id': 'ORD_001',
    'product_id': 'PROD_001',
    'quantity': 1,
    'price': 2499.0,
  });
  await db.collection('payments').doc('9bcB337xaBUWoQaLJCcm').set({
    'payment_id': 'PAY_001',
    'order_id': 'ORD_001',
    'payment_method': 'Razor Pay',
    'payment_status': 'Success',
    'amount': 2499.0,
    'payment_date': at('2026-10-26T05:39:01Z'),
  });
  await db.collection('support').doc('4iZVU6eXdtjXZyYfiIFw').set({
    'support_id': 'SUP_001',
    'user_id': 'UID_123',
    'subject': 'Delivery Delay',
    'message': 'When can I expect my order delivery?',
    'created_at': at('2026-10-26T05:44:40Z'),
  });
  return db;
}
