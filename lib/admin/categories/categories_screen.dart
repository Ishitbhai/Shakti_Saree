import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'categories_providers.dart';
import 'category.dart';
import 'widgets/category_edit_sheet.dart';
import 'widgets/category_tile.dart';

/// The catalogue's groupings: add, rename, recolour, hide, delete.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  /// How long undo stays on offer after a deletion.
  static const Duration undoWindow = Duration(seconds: 6);

  Future<void> _add(BuildContext context, WidgetRef ref) {
    final repository = ref.read(categoriesRepositoryProvider);
    return CategoryEditSheet.show(context, onSubmit: repository.createCategory);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category category) {
    final repository = ref.read(categoriesRepositoryProvider);
    return CategoryEditSheet.show(
      context,
      category: category,
      onSubmit: (edited) => repository.updateCategory(
        originalName: category.name,
        category: edited,
      ),
    );
  }

  Future<void> _toggleHidden(WidgetRef ref, CategoryListing listing) {
    return ref
        .read(categoriesRepositoryProvider)
        .setHidden(listing.name, isHidden: !listing.isHidden);
  }

  /// Confirms, deletes, then offers to put it back.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryListing listing,
  ) async {
    final confirmed = await _confirmDeletion(context, listing);
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(categoriesRepositoryProvider);

    try {
      final removed = await repository.deleteCategory(listing.name);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${listing.name} deleted'),
            duration: undoWindow,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await repository.restoreCategory(removed);
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(AsyncContent.messageFor(error))),
                  );
                }
              },
            ),
          ),
        );
    } catch (error) {
      // A grouping that still holds listings is refused, and this is where
      // the admin finds out why.
      messenger.showSnackBar(
        SnackBar(content: Text(AsyncContent.messageFor(error))),
      );
    }
  }

  Future<bool> _confirmDeletion(
    BuildContext context,
    CategoryListing listing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this category?'),
        content: Text(
          '${listing.name} will be removed. You will have a moment to undo '
          'it.',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Manage Categories',
              subtitle: categories.maybeWhen(
                data: (loaded) =>
                    '${Formatters.count(loaded.length)} categories',
                orElse: () => '',
              ),
              action: AdminHeaderAction(
                icon: Icons.add,
                label: 'Add category',
                onTap: () => _add(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Expanded(
              child: AsyncContent<List<CategoryListing>>(
                state: categories,
                onRetry: () => ref.invalidate(categoriesProvider),
                isEmpty: (loaded) => loaded.isEmpty,
                emptyMessage: 'No categories yet.',
                builder: (context, loaded) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    _screenPadding,
                    0,
                    _screenPadding,
                    AppSpacing.x6,
                  ),
                  itemCount: loaded.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.x3),
                  itemBuilder: (context, index) {
                    final listing = loaded[index];
                    return CategoryTile(
                      listing: listing,
                      onEdit: () => _edit(context, ref, listing.category),
                      onDelete: () => _delete(context, ref, listing),
                      onToggleHidden: () => _toggleHidden(ref, listing),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
