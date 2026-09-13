import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import '../shared/widgets/busy_label.dart';
import '../shared/widgets/swatches.dart';
import 'product.dart';
import 'products_providers.dart';

/// Stock management: every listing's quantity, stepped up or down, saved in
/// one go.
///
/// The steppers edit a draft rather than the catalogue. A single Update Stock
/// button is what the design asks for, and it is the right shape for the job
/// — counting a shelf means correcting several rows before any of it is
/// worth recording.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  /// Quantities the admin has stepped, by SKU. Only what has been touched is
  /// in here; everything else reads through to the catalogue.
  final Map<String, int> _edited = {};

  bool _saving = false;

  int _stockOf(Product product) => _edited[product.sku] ?? product.stock;

  /// The listing as the draft has it, so the dot and the tallies read off the
  /// same [Product.level] the rest of the app uses.
  Product _drafted(Product product) =>
      product.copyWith(stock: _stockOf(product));

  bool get _isDirty => _edited.isNotEmpty;

  void _step(Product product, int by) {
    final next = _stockOf(product) + by;
    // Nothing below an empty shelf.
    if (next < 0) return;

    setState(() {
      if (next == product.stock) {
        // Stepped back to where it started, so it is not an edit any more.
        _edited.remove(product.sku);
      } else {
        _edited[product.sku] = next;
      }
    });
  }

  Future<void> _save() async {
    if (!_isDirty || _saving) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final changed = await ref
          .read(productsRepositoryProvider)
          .updateStock(Map.of(_edited));
      if (!mounted) return;

      setState(_edited.clear);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            changed == 1 ? '1 listing updated' : '$changed listings updated',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(AsyncContent.messageFor(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Asks before throwing away a count that has not been recorded.
  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard stock changes?'),
        content: Text(
          'Quantities have been changed but not saved. Leaving now loses '
          'them.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep counting'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _leave(bool didPop) async {
    if (didPop || _saving) return;
    final mayLeave = !_isDirty || await _confirmDiscard();
    if (mayLeave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _leave(didPop),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const AdminPageHeader(
                title: 'Inventory',
                subtitle: 'Stock management',
              ),
              Expanded(
                child: AsyncContent<List<Product>>(
                  state: products,
                  onRetry: () => ref.invalidate(productsProvider),
                  isEmpty: (loaded) => loaded.isEmpty,
                  emptyMessage: 'Nothing to count yet.',
                  builder: (context, loaded) => _buildBody(loaded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Product> products) {
    // Tallied from the draft, so the counts move as the steppers do rather
    // than waiting for the save.
    final drafted = products.map(_drafted).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            InventoryScreen._screenPadding,
            0,
            InventoryScreen._screenPadding,
            AppSpacing.x4,
          ),
          child: _StockTallies(products: drafted),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              InventoryScreen._screenPadding,
              0,
              InventoryScreen._screenPadding,
              AppSpacing.x4,
            ),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x3),
            itemBuilder: (context, index) {
              final product = products[index];
              return _InventoryRow(
                product: _drafted(product),
                isEdited: _edited.containsKey(product.sku),
                onStep: _saving ? null : (by) => _step(product, by),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            InventoryScreen._screenPadding,
            0,
            InventoryScreen._screenPadding,
            AppSpacing.x4,
          ),
          child: FilledButton(
            // Nothing to save until something has been stepped, and saying so
            // beats a button that quietly does nothing.
            onPressed: _isDirty && !_saving ? _save : null,
            child: BusyLabel(label: 'Update Stock', busy: _saving),
          ),
        ),
      ],
    );
  }
}

/// The three tallies across the top.
class _StockTallies extends StatelessWidget {
  const _StockTallies({required this.products});

  final List<Product> products;

  int _count(StockLevel level) =>
      products.where((product) => product.level == level).length;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tally(
              value: _count(StockLevel.inStock),
              label: 'In Stock',
              background: AppColors.successBg,
              foreground: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: _Tally(
              value: _count(StockLevel.lowStock),
              label: 'Low Stock',
              background: AppColors.warningBg,
              foreground: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: _Tally(
              value: _count(StockLevel.outOfStock),
              label: 'Out of Stock',
              background: AppColors.errorBg,
              foreground: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({
    required this.value,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final int value;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: '$label, ${Formatters.count(value)}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.cardRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3,
              vertical: AppSpacing.x4,
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.count(value),
                    style: AppTypography.statValue.copyWith(color: foreground),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One listing and its stepper.
class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.product,
    required this.isEdited,
    this.onStep,
  });

  /// Already carrying the drafted quantity.
  final Product product;

  /// Whether this row is holding an unsaved change.
  final bool isEdited;

  final ValueChanged<int>? onStep;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 12;
  static const double _swatch = 48;
  static const double _dot = 8;

  Color get _levelColour => switch (product.level) {
    StockLevel.inStock => AppColors.success,
    StockLevel.lowStock => AppColors.warning,
    StockLevel.outOfStock => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    // Two digits, as the design shows: '08' rather than '8'.
    final quantity = product.stock.toString().padLeft(2, '0');

    // No MergeSemantics around the whole row: the stepper buttons are real
    // controls, and merging them into one node would leave a screen reader
    // with a paragraph and no way to press either.
    return DecoratedBox(
      key: ValueKey(product.sku),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.softShadow,
        // A touched row wears a quiet outline, so what is about to be
        // saved is obvious before the button is pressed.
        border: isEdited
            ? Border.all(color: AppColors.primary)
            : Border.all(color: AppColors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                height: _swatch,
                width: _swatch,
                decoration: BoxDecoration(
                  color: Swatches.at(product.swatchIndex),
                  borderRadius: AppRadii.cardRadius,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      'SKU: ${product.sku}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: _dot,
                          width: _dot,
                          decoration: BoxDecoration(
                            color: _levelColour,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        // Flexible, not free-sizing: what is left beside the
                        // stepper is narrow, and the line would otherwise run
                        // off the edge of the card.
                        Flexible(
                          child: Text(
                            'Stock $quantity pcs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: _levelColour,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            _Stepper(
              quantity: quantity,
              name: product.name,
              onDecrease: onStep == null || product.stock == 0
                  ? null
                  : () => onStep!(-1),
              onIncrease: onStep == null ? null : () => onStep!(1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minus, the count, plus.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.name,
    this.onDecrease,
    this.onIncrease,
  });

  final String quantity;
  final String name;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  /// Straight from the design; not on the base-4 scale.
  static const double _button = 30;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.field,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              label: 'Decrease stock of $name',
              onTap: onDecrease,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
              child: ExcludeSemantics(
                child: Text(quantity, style: AppTypography.titleMedium),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              label: 'Increase stock of $name',
              onTap: onIncrease,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _Stepper._button,
            width: _Stepper._button,
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? AppColors.textMuted : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
