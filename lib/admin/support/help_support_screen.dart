import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/tinted_pill.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import 'faq.dart';
import 'faqs_providers.dart';
import 'widgets/faq_edit_sheet.dart';
import 'widgets/faq_tile.dart';

/// Help & Support: the questions the panel answers, and the admin's own
/// copy of them.
///
/// One answer open at a time, as the design has it — a list where everything
/// is open is a wall of text, and the question being read stays findable.
///
/// The design shows only the add button. Edit and Delete are here too,
/// inside an open answer: these entries are the admin's own writing, and one
/// with a typo in it that could never be corrected would be a worse screen
/// than the mock describes.
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  static const double _screenPadding = AppSpacing.x5;

  /// How long undo stays on offer after a deletion.
  static const Duration undoWindow = Duration(seconds: 6);

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  /// The question showing its answer, by its wording, or null while they are
  /// all closed.
  ///
  /// The wording rather than the position, so an entry added or deleted above
  /// the open one does not slide the answer onto a different question.
  String? _open;

  void _toggle(Faq faq) =>
      setState(() => _open = _open == faq.question ? null : faq.question);

  Future<void> _add() async {
    final repository = ref.read(faqsRepositoryProvider);
    final added = await FaqEditSheet.show(
      context,
      onSubmit: repository.createFaq,
    );
    // Opened on arrival, so what was just written is there to be read back.
    if (added != null) setState(() => _open = added.question);
  }

  Future<void> _edit(Faq faq) async {
    final repository = ref.read(faqsRepositoryProvider);
    final saved = await FaqEditSheet.show(
      context,
      faq: faq,
      onSubmit: (edited) =>
          repository.updateFaq(originalQuestion: faq.question, faq: edited),
    );
    // A reworded question is a different key, and the answer should stay
    // open on it rather than snapping shut.
    if (saved != null) setState(() => _open = saved.question);
  }

  /// Confirms, deletes, then offers to put it back.
  Future<void> _delete(Faq faq) async {
    final confirmed = await _confirmDeletion(faq);
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(faqsRepositoryProvider);

    try {
      final removed = await repository.deleteFaq(faq.question);
      if (mounted) setState(() => _open = null);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Question deleted'),
            duration: HelpSupportScreen.undoWindow,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await repository.restoreFaq(removed);
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
      messenger.showSnackBar(
        SnackBar(content: Text(AsyncContent.messageFor(error))),
      );
    }
  }

  Future<bool> _confirmDeletion(Faq faq) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this question?'),
        content: Text(
          '"${faq.question}" will be removed. You will have a moment to undo '
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
  Widget build(BuildContext context) {
    final faqs = ref.watch(faqsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AdminPageHeader(
              title: 'Help & Support',
              subtitle: 'Guides for managing your panel',
              // Not an action — it says whose panel this is, which is the
              // one thing the design puts up here.
              trailing: TintedPill(
                label: 'ADMIN',
                background: AppColors.primary,
                foreground: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HelpSupportScreen._screenPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Frequently Asked Questions',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  AdminHeaderSquare(
                    icon: Icons.add,
                    label: 'Add question',
                    onTap: _add,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Expanded(
              child: AsyncContent<List<Faq>>(
                state: faqs,
                onRetry: () => ref.invalidate(faqsProvider),
                isEmpty: (loaded) => loaded.isEmpty,
                emptyMessage: 'No questions answered yet.',
                builder: (context, loaded) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    HelpSupportScreen._screenPadding,
                    0,
                    HelpSupportScreen._screenPadding,
                    AppSpacing.x6,
                  ),
                  itemCount: loaded.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.x3),
                  itemBuilder: (context, index) {
                    final faq = loaded[index];
                    return FaqTile(
                      faq: faq,
                      isExpanded: faq.question == _open,
                      onToggle: () => _toggle(faq),
                      onEdit: () => _edit(faq),
                      onDelete: () => _delete(faq),
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
