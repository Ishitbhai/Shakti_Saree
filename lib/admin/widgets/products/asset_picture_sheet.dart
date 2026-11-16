import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../styles/app_typography.dart';

/// Lets the admin choose one of the pictures bundled in [folder].
///
/// Products and categories store the path it answers with, such as
/// `assets/images/image3.png`, which every app built from this project can
/// show. A new picture is added by copying the file into `assets/images/` in
/// the project and rebuilding the app; it then turns up here on its own,
/// because the list is read from the app's asset manifest, not typed out.
class AssetPictureSheet extends StatefulWidget {
  const AssetPictureSheet({super.key, this.selected, this.bundle});

  /// Where pictures are offered from. Only files directly inside it:
  /// `pubspec.yaml` bundles nothing deeper.
  static const String folder = 'assets/images/';

  /// The picture the record has now, outlined so the admin can see it.
  final String? selected;

  /// The app's own bundle unless a test hands in another.
  final AssetBundle? bundle;

  /// Opens the sheet. Resolves to the chosen path, or null if the admin
  /// closed it without choosing.
  static Future<String?> show(BuildContext context, {String? selected}) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        builder: (_) => AssetPictureSheet(selected: selected),
      );

  /// Every picture directly in [folder], in natural order: image2 before
  /// image10.
  static Future<List<String>> picturesIn(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final pictures = [
      for (final asset in manifest.listAssets())
        if (asset.startsWith(folder) &&
            !asset.substring(folder.length).contains('/') &&
            _isPicture(asset))
          asset,
    ]..sort(naturalOrder);
    return pictures;
  }

  static bool _isPicture(String path) => RegExp(
    r'\.(png|jpe?g|webp|gif)$',
    caseSensitive: false,
  ).hasMatch(path);

  /// Compares the runs of digits in two names as numbers, the rest as text.
  static int naturalOrder(String a, String b) {
    final chunk = RegExp(r'\d+|\D+');
    final left = [for (final m in chunk.allMatches(a)) m[0]!];
    final right = [for (final m in chunk.allMatches(b)) m[0]!];
    for (var i = 0; i < left.length && i < right.length; i++) {
      final x = int.tryParse(left[i]);
      final y = int.tryParse(right[i]);
      final order = x != null && y != null
          ? x.compareTo(y)
          : left[i].compareTo(right[i]);
      if (order != 0) return order;
    }
    return left.length.compareTo(right.length);
  }

  @override
  State<AssetPictureSheet> createState() => _AssetPictureSheetState();
}

class _AssetPictureSheetState extends State<AssetPictureSheet> {
  late final Future<List<String>> _pictures = AssetPictureSheet.picturesIn(
    widget.bundle ?? rootBundle,
  );

  /// Straight from the design of the upload box; not on the base-4 scale.
  static const double _tile = 104;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x5,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Choose a picture', style: AppTypography.sectionTitle),
                        Text(
                          'From assets/images in the app',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textGrey,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _pictures,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _Message(
                        "The app's pictures could not be read. Close this and "
                        'try again.',
                      );
                    }
                    final pictures = snapshot.data;
                    if (pictures == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (pictures.isEmpty) {
                      return const _Message(
                        'No pictures in assets/images yet. Copy image files '
                        'into that folder in the project, then rebuild the app.',
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x5),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: _tile,
                            mainAxisSpacing: AppSpacing.x2,
                            crossAxisSpacing: AppSpacing.x2,
                          ),
                      itemCount: pictures.length,
                      itemBuilder: (context, index) => _Tile(
                        path: pictures[index],
                        selected: pictures[index] == widget.selected,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.path, required this.selected});

  final String path;
  final bool selected;

  String get _name => path.substring(path.lastIndexOf('/') + 1);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _name,
      selected: selected,
      button: true,
      child: Material(
        color: AppColors.field,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 3 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('picture:$path'),
          onTap: () => Navigator.of(context).pop(path),
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            // Thumbnails: decoding every picture at full size would hold
            // megabytes for a grid of tiles a few centimetres wide.
            cacheWidth: 240,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall,
      ),
    );
  }
}
