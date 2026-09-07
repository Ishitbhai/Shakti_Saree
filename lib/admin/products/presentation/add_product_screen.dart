import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../shared/widgets/admin_page_header.dart';
import '../../shared/widgets/labelled_field.dart';
import 'widgets/image_upload_box.dart';

/// Form for creating a product listing.
///
/// Nothing is persisted yet — Save Draft and Publish land with the repository.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  /// Options in the category dropdown.
  static const List<String> categories = [
    'Silk Saree',
    'Banarasi',
    'Cotton',
    'Georgette',
    'Kanjivaram',
    'Designer',
    'Bridal',
    'Daily Wear',
  ];

  /// Cap on how many photos a listing can carry.
  static const int maxImages = 5;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  /// Seeded with the sample listing from the design so the form reads as it
  /// does in the mock; swap for empty strings once this creates real records.
  late final _name = TextEditingController(text: 'Banarasi Silk Saree');
  late final _price = TextEditingController(text: Formatters.count(4999));
  late final _salePrice = TextEditingController(text: Formatters.count(2499));
  late final _stock = TextEditingController(text: Formatters.count(24));
  late final _sku = TextEditingController(text: 'SS-1024');
  late final _description = TextEditingController();

  String _category = AddProductScreen.categories.first;
  bool _featured = true;

  final _picker = ImagePicker();
  final List<PickedImage> _images = [];

  /// Opens the gallery and appends what comes back, up to the cap.
  ///
  /// Bytes are read here so the thumbnails render the same way on mobile and
  /// on web, where a file path is a blob URL rather than something on disk.
  Future<void> _pickImages() async {
    final remaining = AddProductScreen.maxImages - _images.length;
    if (remaining <= 0) return;

    try {
      final picked = await _picker.pickMultiImage(limit: remaining);
      if (picked.isEmpty) return;

      final loaded = [
        for (final file in picked.take(remaining))
          PickedImage(name: file.name, bytes: await file.readAsBytes()),
      ];
      if (!mounted) return;
      setState(() => _images.addAll(loaded));
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the gallery: $error')),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _salePrice.dispose();
    _stock.dispose();
    _sku.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AdminPageHeader(
              title: 'Add Product',
              subtitle: 'Create new listing',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x4,
                  AppSpacing.x5,
                  AppSpacing.x8,
                ),
                children: [
                  ImageUploadBox(
                    images: _images,
                    maxImages: AddProductScreen.maxImages,
                    onAdd: _pickImages,
                    onRemove: (index) =>
                        setState(() => _images.removeAt(index)),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  LabelledField(
                    label: 'Product Name',
                    child: TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  LabelledField(
                    label: 'Category',
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textGrey,
                      ),
                      style: AppTypography.bodyMedium,
                      items: [
                        for (final category in AddProductScreen.categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabelledField(
                          label: 'Price (₹)',
                          child: _NumberField(controller: _price),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: LabelledField(
                          label: 'Sale Price (₹)',
                          child: _NumberField(controller: _salePrice),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabelledField(
                          label: 'Stock Qty',
                          child: _NumberField(controller: _stock),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: LabelledField(
                          label: 'SKU Code',
                          child: TextField(
                            controller: _sku,
                            textInputAction: TextInputAction.next,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  LabelledField(
                    label: 'Description',
                    child: TextField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(
                        hintText:
                            'Pure Banarasi silk saree with golden zari border '
                            'and matching blouse piece...',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  _FeaturedToggle(
                    value: _featured,
                    onChanged: (value) => setState(() => _featured = value),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Row(
                    children: [
                      // No fixed height: the theme sets a minimum and the
                      // buttons grow with the platform text scale.
                      Expanded(
                        child: OutlinedButton(
                          // Enabled but inert: styling comes from the design,
                          // the handler lands with the repository.
                          onPressed: () {},
                          child: const Text('Save Draft'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text('Publish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Digits-only field, used for the price and stock inputs.
class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium,
    );
  }
}

class _FeaturedToggle extends StatelessWidget {
  const _FeaturedToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadii.cardRadius,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (next) => onChanged(next ?? false),
            activeColor: AppColors.primary,
            checkColor: AppColors.textOnPrimary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Text(
              'Mark as Featured product',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
