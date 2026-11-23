import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../data/shop_providers.dart';
import '../models/shop_models.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/app_back_button.dart';
import 'add_edit_address_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Set to true for auto-success Razorpay checkout (no Success/Failure prompt).
  // Set to false to launch the official Razorpay SDK with your _razorpayKey.
  static const bool _useAutoSuccessDemo = false;
  static const String _razorpayKey = 'rzp_test_YOUR_KEY_HERE';

  late Razorpay _razorpay;

  String selectedPayment = 'UPI';
  String? selectedAddressId;
  bool _isProcessing = false;

  String errAddress = '';
  String errPayment = '';

  // Cached checkout details while Razorpay payment sheet is active
  Map<String, dynamic>? _pendingAddress;
  List<CartEntry> _pendingCartItems = [];
  int _pendingTotalPaise = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_pendingAddress == null || _pendingCartItems.isEmpty) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    _commitOrderToFirestore(
      chosenAddress: _pendingAddress!,
      cartItems: _pendingCartItems,
      totalPaise: _pendingTotalPaise,
      razorpayPaymentId: response.paymentId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Cancelled: ${response.message ?? "Transaction not completed"}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet: ${response.walletName ?? ""}'),
        ),
      );
    }
  }

  void _openRazorpayCheckout({
    required int totalPaise,
    required Map<String, dynamic> chosenAddress,
  }) {
    final profile =
        ref.read(customerProfileProvider).value ?? <String, dynamic>{};
    final String phone = Fs.stringOf(chosenAddress['phone']).isNotEmpty
        ? Fs.stringOf(chosenAddress['phone'])
        : Fs.stringOf(profile[Fs.phone]);
    final String email = Fs.stringOf(profile[Fs.email]).isNotEmpty
        ? Fs.stringOf(profile[Fs.email])
        : 'customer@shaktisaree.com';

    // Real Razorpay SDK when _useAutoSuccessDemo is false and a valid key is set
    if (!_useAutoSuccessDemo &&
        _razorpayKey.isNotEmpty &&
        _razorpayKey != 'rzp_test_YOUR_KEY_HERE') {
      final Map<String, dynamic> options = {
        'key': _razorpayKey,
        'amount': totalPaise,
        'currency': 'INR',
        'name': 'Shakti Saree',
        'description': 'Saree Order Payment',
        'prefill': {'contact': phone, 'email': email},
        'theme': {'color': '#7A1C24'},
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to launch Razorpay: $e')),
          );
        }
      }
      return;
    }

    // Razorpay Checkout Sheet with UPI, Cards, Netbanking & Pay Later (Auto-Success)
    _openAutoSuccessRazorpaySheet(
      totalPaise: totalPaise,
      phone: phone,
      email: email,
    );
  }

  Future<void> _openAutoSuccessRazorpaySheet({
    required int totalPaise,
    required String phone,
    required String email,
  }) async {
    final int totalRupees = (totalPaise / 100).round();
    String selectedDemoMethod = 'UPI (GPay / PhonePe / Paytm)';
    bool payingNow = false;

    final bool? paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Razorpay Brand Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A233A),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'SS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Shakti Saree',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.verified,
                                    color: Color(0xFF38BDF8),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Razorpay Trusted Business • ${phone.isNotEmpty ? "+91 $phone" : email}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: payingNow
                              ? null
                              : () => Navigator.pop(sheetContext, false),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Payment Methods
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAYMENT OPTIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final method in [
                          {
                            'title': 'UPI (GPay / PhonePe / Paytm)',
                            'sub': 'Instant payment via UPI ID or QR',
                            'icon': Icons.qr_code_2,
                          },
                          {
                            'title': 'Pay Later (Simpl / LazyPay / ICICI)',
                            'sub': 'Buy now, pay in 15 days at 0% interest',
                            'icon': Icons.watch_later_outlined,
                          },
                          {
                            'title': 'Credit / Debit Card',
                            'sub': 'Visa, Mastercard, RuPay',
                            'icon': Icons.credit_card,
                          },
                          {
                            'title': 'Netbanking',
                            'sub': 'All major Indian banks',
                            'icon': Icons.account_balance,
                          },
                        ])
                          GestureDetector(
                            onTap: payingNow
                                ? null
                                : () {
                                    setSheetState(() {
                                      selectedDemoMethod =
                                          method['title'] as String;
                                    });
                                  },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedDemoMethod == method['title']
                                      ? const Color(0xFF2B6CB0)
                                      : Colors.grey.shade300,
                                  width: selectedDemoMethod == method['title']
                                      ? 1.5
                                      : 1,
                                ),
                                color: selectedDemoMethod == method['title']
                                    ? const Color(0xFFEBF8FF)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    method['icon'] as IconData,
                                    color: const Color(0xFF1A233A),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method['title'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          method['sub'] as String,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selectedDemoMethod == method['title']
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selectedDemoMethod == method['title']
                                        ? const Color(0xFF2B6CB0)
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: payingNow
                                ? null
                                : () async {
                                    setSheetState(() => payingNow = true);
                                    await Future.delayed(
                                      const Duration(milliseconds: 1100),
                                    );
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext, true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B6CB0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: payingNow
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Processing Payment...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Pay ₹$totalRupees',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Secured by Razorpay',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (paid == true &&
        _pendingAddress != null &&
        _pendingCartItems.isNotEmpty) {
      final String autoTxnId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      await _commitOrderToFirestore(
        chosenAddress: _pendingAddress!,
        cartItems: _pendingCartItems,
        totalPaise: _pendingTotalPaise,
        razorpayPaymentId: autoTxnId,
      );
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = ref.read(customerUidProvider);
    final db = ref.read(firestoreProvider);
    if (uid == null || db == null) return;

    try {
      await db
          .collection(Fs.users)
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

      if (selectedAddressId == addressId) {
        setState(() => selectedAddressId = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete address: $e')));
      }
    }
  }

  Future<void> validateAndPay({
    required List addresses,
    required List<CartEntry> cartItems,
    required int totalPaise,
  }) async {
    setState(() {
      errAddress = '';
      errPayment = '';
    });

    if (addresses.isEmpty || selectedAddressId == null) {
      setState(() => errAddress = 'Please select or add a delivery address');
      return;
    }

    if (selectedPayment.isEmpty) {
      setState(() => errPayment = 'Please select a payment method');
      return;
    }

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    final chosenAddress = Map<String, dynamic>.from(
      addresses.firstWhere(
            (a) => a['id'] == selectedAddressId,
            orElse: () => addresses.first,
          )
          as Map,
    );

    setState(() => _isProcessing = true);

    if (selectedPayment == 'UPI') {
      _pendingAddress = chosenAddress;
      _pendingCartItems = List<CartEntry>.from(cartItems);
      _pendingTotalPaise = totalPaise;

      _openRazorpayCheckout(
        totalPaise: totalPaise,
        chosenAddress: chosenAddress,
      );
    } else {
      await _commitOrderToFirestore(
        chosenAddress: chosenAddress,
        cartItems: cartItems,
        totalPaise: totalPaise,
      );
    }
  }

  Future<void> _commitOrderToFirestore({
    required Map<String, dynamic> chosenAddress,
    required List<CartEntry> cartItems,
    required int totalPaise,
    String? razorpayPaymentId,
  }) async {
    final uid = ref.read(customerUidProvider);
    final db = ref.read(firestoreProvider);
    final repository = ref.read(shopRepositoryProvider);

    if (uid == null || db == null) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No active user session.')),
        );
      }
      return;
    }

    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      final String orderId = 'ORD_$now';
      final int totalRupees = (totalPaise / 100).round();
      final batch = db.batch();

      // 1. Add document to 'orders' collection
      final orderDocRef = db.collection(Fs.orders).doc(orderId);
      batch.set(orderDocRef, {
        Fs.orderId: orderId,
        Fs.userId: uid,
        Fs.totalAmount: totalRupees,
        'total_amount_paise': totalPaise,
        'order_status': 'Pending',
        'payment_method': selectedPayment,
        'payment_status': selectedPayment == 'UPI' ? 'Paid' : 'Pending',
        if (razorpayPaymentId != null) 'razorpay_payment_id': razorpayPaymentId,
        'delivery_address': chosenAddress,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Record payment entry in 'payments' collection
      final String paymentId = 'PAY_$now';
      final paymentDocRef = db.collection('payments').doc(paymentId);
      batch.set(paymentDocRef, {
        'payment_id': paymentId,
        'order_id': orderId,
        'user_id': uid,
        'amount': totalRupees,
        'payment_method': selectedPayment,
        'payment_status': selectedPayment == 'UPI' ? 'Success' : 'Pending',
        if (razorpayPaymentId != null) 'transaction_id': razorpayPaymentId,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 3. Add each purchased item to 'order_items' & decrement stock in 'products'
      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final orderItemDocRef = db.collection('order_items').doc();
        final String orderItemId = 'OITEM_${now}_$i';

        final int itemPrice = item.product != null
            ? (item.product!.pricePaise / 100).round()
            : (item.lineTotalPaise / (item.line.quantity * 100)).round();

        batch.set(orderItemDocRef, {
          'order_id': orderId,
          'order_item_id': orderItemId,
          'price': itemPrice,
          'product_id': item.line.productId,
          'quantity': item.line.quantity,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Find the matching product document by 'product_id' field and decrement stock_quantity
        final prodQuery = await db
            .collection('products')
            .where('product_id', isEqualTo: item.line.productId)
            .limit(1)
            .get();

        if (prodQuery.docs.isNotEmpty) {
          final prodDocRef = prodQuery.docs.first.reference;
          batch.update(prodDocRef, {
            'stock_quantity': FieldValue.increment(-item.line.quantity),
          });
        }
      }

      // 4. Commit order, payment, order_items, and stock decrements atomically
      await batch.commit();

      // 5. Clear customer's active cart lines
      final rawLines = [for (final item in cartItems) item.line];
      await repository.clearCart(rawLines);

      _pendingAddress = null;
      _pendingCartItems = [];
      _pendingTotalPaise = 0;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderId: '#$orderId',
              amount: '₹$totalRupees',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(customerAddressesProvider);
    final cartAsync = ref.watch(cartProvider);

    final addresses = addressesAsync.value ?? [];
    final cartItems = cartAsync.value ?? <CartEntry>[];

    final int totalPaise = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalPaise,
    );
    final String formattedTotal = '₹${(totalPaise / 100).toStringAsFixed(0)}';

    if (selectedAddressId == null && addresses.isNotEmpty) {
      selectedAddressId = addresses.first['id'];
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('Checkout', style: AppTextStyles.pageTitle),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double totalWidth = constraints.maxWidth;
                  const double circleSize = 28;
                  final double stepWidth = totalWidth / 3;

                  return Column(
                    children: [
                      SizedBox(
                        height: circleSize,
                        child: Stack(
                          children: [
                            Positioned(
                              left: stepWidth / 2,
                              top: circleSize / 2 - 1,
                              width: stepWidth,
                              child: Container(
                                height: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              left: stepWidth + (stepWidth / 2),
                              top: circleSize / 2 - 1,
                              width: stepWidth,
                              child: Container(
                                height: 2,
                                color: AppColors.muted,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: _buildStepCircle(
                                      icon: Icons.check,
                                      isActive: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: _buildStepCircle(
                                      number: '2',
                                      isActive: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: _buildStepCircle(
                                      number: '3',
                                      isActive: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'Address',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Payment',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Confirm',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Address', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 10),

                    if (addresses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.muted),
                        ),
                        child: const Text(
                          'No address saved yet. Please add one below.',
                        ),
                      )
                    else
                      ...addresses.map((addr) {
                        final String id = addr['id'] ?? '';
                        final bool isSelected = selectedAddressId == id;
                        final String recipient = Fs.stringOf(
                          addr['recipient_name'],
                        );
                        final String phone = Fs.stringOf(addr['phone']);
                        final String street = Fs.stringOf(addr['street']);
                        final String pincode = Fs.stringOf(addr['pincode']);
                        final String label = Fs.stringOf(
                          addr['label'],
                        ).toUpperCase();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAddressId = id;
                                errAddress = '';
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRadioButton(isSelected),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              recipient.isEmpty
                                                  ? 'Recipient'
                                                  : recipient,
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.pink,
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                              ),
                                              child: Text(
                                                label.isEmpty ? 'HOME' : label,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddEditAddressScreen(
                                                          addressId: id,
                                                          initialAddressData:
                                                              addr,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: const Icon(
                                                Icons.edit_outlined,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () => _deleteAddress(id),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red.shade400,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$street\nPincode - $pincode',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: AppColors.muted),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          phone.isEmpty ? '' : '+91 $phone',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    if (errAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        errAddress,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEditAddressScreen(
                              addressId: null,
                              initialAddressData: null,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            size: 20,
                            color: AppColors.black,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Add New Address',
                            style: AppTextStyles.action.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('Payment Method', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 10),

                    _buildPaymentOption(
                      title: 'Razorpay / UPI',
                      value: 'UPI',
                      icon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 12),

                    _buildPaymentOption(
                      title: 'Cash on Delivery',
                      value: 'COD',
                      icon: Icons.view_in_ar,
                    ),

                    if (errPayment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        errPayment,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.muted, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payable',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          totalPaise > 0 ? formattedTotal : '₹0',
                          style: AppTextStyles.price,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => validateAndPay(
                              addresses: addresses,
                              cartItems: cartItems,
                              totalPaise: totalPaise,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Pay Now', style: AppTextStyles.payNow),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle({
    IconData? icon,
    String? number,
    required bool isActive,
  }) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.muted,
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, color: AppColors.white, size: 16)
          : Text(
              number ?? '',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildRadioButton(bool isSelected) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.muted,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = value;
          errPayment = '';
        });
      },
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.muted,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildRadioButton(isSelected),
            const SizedBox(width: 14),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.muted,
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(title, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
