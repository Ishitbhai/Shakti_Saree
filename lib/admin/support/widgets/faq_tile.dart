import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../faq.dart';

/// One question in the help list, closed or open.
///
/// Open, it shows its answer and the two things that can be done to it. No
/// MergeSemantics around any of this: the question is a control that opens
/// and closes, and Edit and Delete are controls of their own — merging them
/// leaves a screen reader with a paragraph and nothing to press.
class FaqTile extends StatelessWidget {
  const FaqTile({
    super.key,
    required this.faq,
    required this.isExpanded,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final Faq faq;

  /// Whether the answer is showing.
  final bool isExpanded;

  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Straight from the design; not on the base-4 scale.
  static const double _padding = 14;
  static const double _chevron = 20;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey(faq.question),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        boxShadow: AppShadows.softShadow,
        // The open card wears the brand outline, as the design has it, so
        // which question is being read is obvious at a glance.
        border: Border.all(
          color: isExpanded ? AppColors.primary : AppColors.transparent,
        ),
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: faq.question,
              button: true,
              expanded: isExpanded,
              container: true,
              excludeSemantics: true,
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(_padding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Icon(
                        // Down while open, along to the right while closed:
                        // the arrow points at where the answer will appear.
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.chevron_right,
                        size: _chevron,
                        color: isExpanded
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Built only when open: an answer nobody asked for is a page of
            // text between every question.
            if (isExpanded)
              _Answer(faq: faq, onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

/// The answer, and what can be done to the entry carrying it.
class _Answer extends StatelessWidget {
  const _Answer({required this.faq, this.onEdit, this.onDelete});

  final Faq faq;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FaqTile._padding,
        0,
        FaqTile._padding,
        AppSpacing.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.x3),
          Text(faq.answer, style: AppTypography.bodySmall),
          if (onEdit != null || onDelete != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Labelled with the question they act on: out of the card, a
                // bare "Edit" says nothing about what is being edited.
                if (onEdit != null)
                  _AnswerAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    semanticsLabel: 'Edit ${faq.question}',
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  _AnswerAction(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    semanticsLabel: 'Delete ${faq.question}',
                    tint: AppColors.error,
                    onPressed: onDelete,
                  ),
              ],
            )
          else
            const SizedBox(height: AppSpacing.x2),
        ],
      ),
    );
  }
}

/// One of the two actions under an open answer.
class _AnswerAction extends StatelessWidget {
  const _AnswerAction({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    this.tint,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback? onPressed;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: tint == null
            ? null
            : TextButton.styleFrom(foregroundColor: tint),
      ),
    );
  }
}
