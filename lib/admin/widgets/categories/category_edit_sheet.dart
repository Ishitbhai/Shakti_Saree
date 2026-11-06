import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../styles/app_typography.dart';
import '../../utils/embedded_photo.dart';
import '../common/async_content.dart';
import '../common/busy_label.dart';
import '../common/labelled_field.dart';
import '../common/swatch_picker.dart';
import '../products/image_upload_box.dart';
import '../../models/category.dart';

/// Saves the category and answers with what was stored.
typedef CategorySubmit = Future<Category> Function(Category category);

/// Collects the four things a grouping has: a picture, a name, a tint, and
/// whether it is on offer.
///
/// A sheet rather than a screen because that is the whole of it — pushing a
/// full page for one text field would be heavier than the job.
///
/// Like the order sheets, it runs the save itself and pops only on success,
/// so a rejected name stays on screen to be corrected rather than vanishing.
class CategoryEditSheet extends StatefulWidget {
  const CategoryEditSheet({super.key, required this.onSubmit, this.category});

  /// The grouping being edited, or null when creating one.
  final Category? category;

  final CategorySubmit onSubmit;

  /// How large a picked photo is kept. A category is only ever shown as a
  /// thumbnail, and every shopper downloads every category, so it stays
  /// smaller than a product photo.
  static const double photoSize = 512;

  /// Opens the sheet. Resolves to the saved category, or null if the admin
  /// backed out.
  static Future<Category?> show(
    BuildContext context, {
    required CategorySubmit onSubmit,
    Category? category,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => CategoryEditSheet(onSubmit: onSubmit, category: category),
    );
  }

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  Category? get _editing => widget.category;

  bool get _isEditing => _editing != null;

  late final _name = TextEditingController(text: _editing?.name ?? '');

  late int _swatchIndex = _editing?.swatchIndex ?? 0;
  late bool _isHidden = _editing?.isHidden ?? false;

  bool _submitting = false;

  /// Why the last attempt failed, kept so the typed name survives it.
  String? _failure;

  final _picker = ImagePicker();

  /// The photo picked in this sheet, as the upload box shows it.
  PickedImage? _picked;

  /// The same photo as it will be stored, worked out once when it is picked.
  String? _photo;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _nameValue => _name.text.trim();

  bool get _canSubmit => !_submitting && _nameValue.isNotEmpty;

  Category get _draft => Category(
    name: _nameValue,
    swatchIndex: _swatchIndex,
    isHidden: _isHidden,
    // A newly picked photo replaces the picture. Otherwise the one it has is
    // carried through, or every rename would drop the artwork.
    image: _photo ?? _editing?.image,
  );

  /// Opens the gallery for the grouping's picture.
  ///
  /// Shrunk on the way in, and redrawn smaller if it is still too heavy,
  /// because it is kept in the category's own document (see [EmbeddedPhoto]).
  /// Problems show in the sheet rather than as a snack bar, which would land
  /// behind it.
  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: CategoryEditSheet.photoSize,
        maxHeight: CategoryEditSheet.photoSize,
        imageQuality: EmbeddedPhoto.quality,
      );
      if (picked == null) return;

      final bytes = await EmbeddedPhoto.fitted(await picked.readAsBytes());
      if (!mounted) return;
      if (bytes == null) {
        setState(
          () => _failure =
              'That photo is too large to save. Please choose a smaller one.',
        );
        return;
      }
      setState(() {
        _picked = PickedImage(name: picked.name, bytes: bytes);
        _photo = EmbeddedPhoto.encode(bytes);
        _failure = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _failure = 'Could not open the gallery: $error');
    }
  }

  void _removePhoto() => setState(() {
    _picked = null;
    _photo = null;
  });

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final saved = await widget.onSubmit(_draft);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = AsyncContent.messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;

    return PopScope<Category?>(
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Category' : 'New Category',
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textGrey,
                      disabledColor: AppColors.textMuted,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x5),
                ImageUploadBox(
                  images: [?picked],
                  maxImages: 1,
                  prompt: 'Upload category image',
                  onAdd: _submitting ? null : _pickPhoto,
                  onRemove: _submitting ? null : (_) => _removePhoto(),
                ),
                const SizedBox(height: AppSpacing.x4),
                LabelledField(
                  label: 'Name',
                  child: TextField(
                    controller: _name,
                    enabled: !_submitting,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(hintText: 'Silk Saree'),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                LabelledField(
                  label: 'Colour',
                  child: SwatchPicker(
                    selected: _swatchIndex,
                    onSelect: _submitting
                        ? (_) {}
                        : (index) => setState(() => _swatchIndex = index),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                SwitchListTile.adaptive(
                  value: !_isHidden,
                  onChanged: _submitting
                      ? null
                      : (visible) => setState(() => _isHidden = !visible),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: Text('Show in store', style: AppTypography.bodyMedium),
                  subtitle: Text(
                    _isHidden
                        ? 'Hidden — shoppers will not see this grouping.'
                        : 'Shoppers can browse this grouping.',
                    style: AppTypography.caption,
                  ),
                ),
                if (_failure != null) ...[
                  const SizedBox(height: AppSpacing.x4),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: AppRadii.cardRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x3),
                      child: Text(
                        _failure!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x5),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: BusyLabel(
                    label: _isEditing ? 'Save Changes' : 'Add Category',
                    busy: _submitting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
