import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/busy_label.dart';
import '../../shared/widgets/labelled_field.dart';
import '../faq.dart';

/// Saves the entry and answers with what was stored.
typedef FaqSubmit = Future<Faq> Function(Faq faq);

/// Collects the two things a help entry has: a question and its answer.
///
/// A sheet rather than a screen, on the same reasoning as the category one —
/// two fields do not need a page of their own.
///
/// It runs the save itself and pops only on success, so a question that is
/// already answered elsewhere stays on screen to be reworded rather than
/// vanishing with the typing in it.
class FaqEditSheet extends StatefulWidget {
  const FaqEditSheet({super.key, required this.onSubmit, this.faq});

  /// The entry being edited, or null when adding one.
  final Faq? faq;

  final FaqSubmit onSubmit;

  /// Opens the sheet. Resolves to the saved entry, or null if the admin
  /// backed out.
  static Future<Faq?> show(
    BuildContext context, {
    required FaqSubmit onSubmit,
    Faq? faq,
  }) {
    return showModalBottomSheet<Faq>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => FaqEditSheet(onSubmit: onSubmit, faq: faq),
    );
  }

  @override
  State<FaqEditSheet> createState() => _FaqEditSheetState();
}

class _FaqEditSheetState extends State<FaqEditSheet> {
  Faq? get _editing => widget.faq;

  bool get _isEditing => _editing != null;

  late final _question = TextEditingController(text: _editing?.question ?? '');
  late final _answer = TextEditingController(text: _editing?.answer ?? '');

  bool _submitting = false;

  /// Why the last attempt failed, kept so the typing survives it.
  String? _failure;

  @override
  void initState() {
    super.initState();
    for (final field in [_question, _answer]) {
      field.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final field in [_question, _answer]) {
      field
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  String get _questionValue => _question.text.trim();

  String get _answerValue => _answer.text.trim();

  /// Both halves, or there is nothing worth storing: a question with no
  /// answer helps nobody, and an answer with no question is unreachable.
  bool get _canSubmit =>
      !_submitting && _questionValue.isNotEmpty && _answerValue.isNotEmpty;

  Faq get _draft => Faq(question: _questionValue, answer: _answerValue);

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
    return PopScope<Faq?>(
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
                        _isEditing ? 'Edit Question' : 'New Question',
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
                LabelledField(
                  label: 'Question',
                  child: TextField(
                    controller: _question,
                    enabled: !_submitting,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'How do I track an order?',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                LabelledField(
                  label: 'Answer',
                  child: TextField(
                    controller: _answer,
                    enabled: !_submitting,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(
                      hintText:
                          'Go to Profile > My Orders. Every order carries '
                          'its status and a tracking link...',
                    ),
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
                    label: _isEditing ? 'Save Changes' : 'Add Question',
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
