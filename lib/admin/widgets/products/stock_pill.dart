import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../utils/formatters.dart';
import '../common/tinted_pill.dart';
import '../../models/product.dart';

/// Stock chip for a product: the count when healthy, a warning otherwise.
class StockPill extends StatelessWidget {
  const StockPill({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (product.level) {
      StockLevel.inStock => (
        'In Stock ${Formatters.count(product.stock)}',
        AppColors.successBg,
        AppColors.success,
      ),
      StockLevel.lowStock => (
        'Low Stock',
        AppColors.warningBg,
        AppColors.warning,
      ),
      StockLevel.outOfStock => (
        'Out of Stock',
        AppColors.errorBg,
        AppColors.error,
      ),
    };

    return TintedPill(
      label: label,
      background: background,
      foreground: foreground,
    );
  }
}
