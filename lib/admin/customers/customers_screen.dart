import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'customer.dart';
import 'customer_orders_screen.dart';
import 'customers_providers.dart';
import 'widgets/customer_tile.dart';

/// Everyone who has ordered: search, then a scrolling list.
///
/// The people are counted out of the orders rather than stored, so this is a
/// view over the same rows the orders tab shows.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  /// Everything that matches what has been typed.
  ///
  /// Name or number, because those are the two things anyone knows about a
  /// customer when they go looking. The number is compared digits-only, so
  /// '98250' finds '+91 98250 41267' however it was spaced.
  List<Customer> _matching(List<Customer> customers) {
    if (_query.isEmpty) return customers;

    final name = _query.toLowerCase();
    final digits = _digitsOf(_query);

    return customers.where((customer) {
      if (customer.name.toLowerCase().contains(name)) return true;
      return digits.isNotEmpty && _digitsOf(customer.phone).contains(digits);
    }).toList();
  }

  static String _digitsOf(String value) =>
      value.replaceAll(RegExp('[^0-9]'), '');

  Future<void> _openOrders(Customer customer) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerOrdersScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Customers',
              // Everyone on record, not the number matching the search —
              // the list below already says how many that is.
              subtitle: customers.maybeWhen(
                data: (loaded) =>
                    '${Formatters.count(loaded.length)} registered',
                orElse: () => '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CustomersScreen._screenPadding,
                AppSpacing.x2,
                CustomersScreen._screenPadding,
                AppSpacing.x4,
              ),
              child: TextField(
                controller: _search,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search name or mobile',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textGrey,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.textGrey,
                          tooltip: 'Clear search',
                          onPressed: _search.clear,
                        ),
                ),
              ),
            ),
            Expanded(
              child: AsyncContent<List<Customer>>(
                state: customers,
                onRetry: () => ref.invalidate(customersProvider),
                isEmpty: (loaded) => loaded.isEmpty,
                emptyMessage: 'No customers yet.',
                builder: (context, loaded) => _buildList(_matching(loaded)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Customer> visible) {
    if (visible.isEmpty) {
      return AsyncMessage(text: 'Nobody matches "$_query"');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        CustomersScreen._screenPadding,
        0,
        CustomersScreen._screenPadding,
        AppSpacing.x6,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x3),
      itemBuilder: (context, index) {
        final customer = visible[index];
        return CustomerTile(
          customer: customer,
          onTap: () => _openOrders(customer),
        );
      },
    );
  }
}
