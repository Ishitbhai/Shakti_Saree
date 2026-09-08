import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../product.dart';

/// Asks whether a listing really is to be deleted.
///
/// Names the product rather than saying "this item": the delete buttons sit
/// one under another down a list of near-identical rows, and the only useful
/// check is whether the right one is about to go.
///
/// Answers false if the dialog is dismissed any other way.
Future<bool> confirmProductDeletion(
  BuildContext context, {
  required Product product,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this product?'),
      content: Text(
        '${product.name} (SKU ${product.sku}) will be removed from the '
        'catalogue. You will have a moment to undo it.',
        style: AppTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
