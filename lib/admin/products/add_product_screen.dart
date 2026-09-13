import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../mock/product_store.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import '../shared/widgets/busy_label.dart';
import '../shared/widgets/labelled_field.dart';
import 'product.dart';
import '../shared/widgets/swatch_picker.dart';
import '../categories/categories_providers.dart';
import 'products_providers.dart';
import 'widgets/image_upload_box.dart';
import 'widgets/stock_pill.dart';

/// Form for creating a product listing, and for editing one.
///
/// One screen rather than two: the fields, their validation and their layout
/// are identical either way, and the only differences are what the form opens
/// with and what the submit button does. Pass [product] to edit that listing;
/// leave it null to create.
///
/// Only what the catalogue stores is saved — name, SKU, price, stock, the
/// category and the placeholder tint. Sale price, description and the
/// featured flag are in the design but have nowhere on [Product] to go yet,
/// so they are decoration until the model grows.
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.product});

  /// The listing being edited, or null when creating a new one.
  final Product? product;

  /// Cap on how many photos a listing can carry.
  static const int maxImages = 5;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  Product? get _editing => widget.product;

  bool get _isEditing => _editing != null;

  /// Editing opens on the stored listing; creating opens empty.
  ///
  /// The design's sample used to be typed in here, which was fine while the
  /// form saved nothing. Now that it creates real records it cannot: the
  /// sample carries SS-1024, which the catalogue already has, so a new
  /// listing would open holding a SKU it is not allowed to keep.
  late final _name = TextEditingController(text: _editing?.name ?? '');
  late final _price = TextEditingController(
    text: _editing == null ? '' : Formatters.count(_editing!.pricePaise ~/ 100),
  );
  late final _stock = TextEditingController(
    text: _editing == null ? '' : Formatters.count(_editing!.stock),
  );
  late final _sku = TextEditingController(text: _editing?.sku ?? '');

  /// Nothing on the product to load these from, so they open empty whichever
  /// mode this is.
  late final _salePrice = TextEditingController();
  late final _description = TextEditingController();

  late String _category = _editing?.category ?? '';
  late bool _featured = !_isEditing;
  late int _swatchIndex = _editing?.swatchIndex ?? 0;

  /// What the form opened with, for telling whether anything has changed.
  ///
  /// Taken in [initState] rather than lazily: a `late final` initialiser runs
  /// on first read, which would be after the first edit, and the form would
  /// then compare the typing against itself and never look dirty.
  late final String _opened;

  /// Set once submit has been pressed, so the form does not open already
  /// complaining about fields nobody has touched.
  bool _submitted = false;
  bool _saving = false;

  final _picker = ImagePicker();
  final List<PickedImage> _images = [];

  List<TextEditingController> get _fields => [
    _name,
    _price,
    _stock,
    _sku,
    _salePrice,
    _description,
  ];

  @override
  void initState() {
    super.initState();
    _opened = _snapshot();
    // The stock preview, the error text and the discard guard all depend on
    // what has been typed, so every keystroke has to reach build.
    for (final field in _fields) {
      field.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final field in _fields) {
      field
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------- validation
  String get _nameValue => _name.text.trim();

  String get _skuValue => _sku.text.trim();

  /// Digits only, so '2,499' and '2499' both read as 2499.
  int? _digits(TextEditingController field) =>
      int.tryParse(field.text.replaceAll(RegExp('[^0-9-]'), ''));

  String? get _nameError =>
      _nameValue.isEmpty ? 'Give the product a name.' : null;

  String? get _skuError {
    if (_skuValue.isEmpty) return 'A SKU is required.';
    // Its own SKU does not count against it, or an edit that changed nothing
    // else would be blocked by itself.
    final taken = ref
        .read(productStoreProvider.notifier)
        .isSkuTaken(_skuValue, exceptSku: _editing?.sku);
    return taken ? 'SKU $_skuValue is already in use.' : null;
  }

  String? get _priceError {
    final rupees = _digits(_price);
    return rupees == null || rupees <= 0
        ? 'Price must be more than zero.'
        : null;
  }

  String? get _stockError {
    final stock = _digits(_stock);
    return stock == null || stock < 0 ? 'Stock cannot be negative.' : null;
  }

  bool get _isValid =>
      _nameError == null &&
      _skuError == null &&
      _priceError == null &&
      _stockError == null;

  /// Shown only once submit has been pressed, so typing is not nagged at.
  String? _shown(String? error) => _submitted ? error : null;

  /// What the category dropdown offers.
  ///
  /// Uncategorised first, because a listing is allowed to belong nowhere.
  /// Then the groupings on offer — and the listing's own category if that is
  /// not among them, which happens when it has since been hidden or renamed
  /// away. Leaving it out would mean opening the form on a value the
  /// dropdown does not have, which is an assertion rather than a nicety.
  List<String> _categoryOptions() {
    final options = ['', ...ref.watch(categoryNamesProvider)];
    if (!options.contains(_category)) options.add(_category);
    return options;
  }

  /// The listing as currently typed.
  ///
  /// Both the stock badge below and the save go through this, so what the
  /// form previews is exactly what gets stored — and the In Stock / Low
  /// Stock / Out of Stock thresholds stay where they already live, on
  /// [Product], rather than being written out a second time here.
  Product get _draft => Product(
    name: _nameValue,
    sku: _skuValue,
    pricePaise: (_digits(_price) ?? 0) * 100,
    stock: _digits(_stock) ?? 0,
    swatchIndex: _swatchIndex,
    category: _category,
  );

  // -------------------------------------------------------- unsaved changes
  String _snapshot() => [
    _name.text,
    _price.text,
    _stock.text,
    _sku.text,
    _salePrice.text,
    _description.text,
    _category,
    '$_featured',
    '$_swatchIndex',
    '${_images.length}',
  ].join('|');

  bool get _isDirty => _snapshot() != _opened;

  /// Asks before throwing away edits. Answers true if it is fine to leave.
  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text(
          'This listing has changes that have not been saved. Leaving now '
          'loses them.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
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

  /// The one way out of this screen, whichever gesture asked for it.
  Future<void> _leave(bool didPop) async {
    if (didPop || _saving) return;
    final mayLeave = !_isDirty || await _confirmDiscard();
    if (mayLeave && mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------- saving
  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_isValid || _saving) return;

    final editing = _editing;
    setState(() => _saving = true);
    try {
      final repository = ref.read(productsRepositoryProvider);
      await (editing == null
          ? repository.createProduct(_draft)
          : repository.updateProduct(
              originalSku: editing.sku,
              product: _draft,
            ));
      if (!mounted) return;
      // Saved, so there is nothing left to warn about.
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AsyncContent.messageFor(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
  Widget build(BuildContext context) {
    return PopScope<void>(
      // Always intercepted, so the answer is worked out at the moment of the
      // gesture rather than at whenever the last rebuild happened to be.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _leave(didPop),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                title: _isEditing ? 'Edit Product' : 'Add Product',
                subtitle: _isEditing
                    ? 'SKU ${_editing!.sku}'
                    : 'Create new listing',
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
                    const SizedBox(height: AppSpacing.x4),
                    LabelledField(
                      label: 'Placeholder Colour',
                      child: SwatchPicker(
                        selected: _swatchIndex,
                        onSelect: (index) =>
                            setState(() => _swatchIndex = index),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    LabelledField(
                      label: 'Product Name',
                      child: TextField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Banarasi Silk Saree',
                          errorText: _shown(_nameError),
                        ),
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
                          for (final category in _categoryOptions())
                            DropdownMenuItem(
                              value: category,
                              child: Text(
                                category.isEmpty ? 'Uncategorised' : category,
                              ),
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
                            child: _NumberField(
                              controller: _price,
                              errorText: _shown(_priceError),
                            ),
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
                            child: _NumberField(
                              controller: _stock,
                              errorText: _shown(_stockError),
                            ),
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
                              decoration: InputDecoration(
                                hintText: 'SS-1029',
                                errorText: _shown(_skuError),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    // The badge the catalogue will show for this quantity,
                    // read off the same Product that will be saved.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StockPill(product: _draft),
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
                              'Pure Banarasi silk saree with golden zari '
                              'border and matching blouse piece...',
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
                            onPressed: _saving ? null : () => _leave(false),
                            // 'Save Draft' in the design, but there is no
                            // draft flag on a product to save one against,
                            // and a button that says Save while discarding
                            // is worse than one with a plainer name.
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: BusyLabel(
                              label: _isEditing ? 'Save Changes' : 'Publish',
                              busy: _saving,
                            ),
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
      ),
    );
  }
}

/// Digits-only field, used for the price and stock inputs.
class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(errorText: errorText),
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
