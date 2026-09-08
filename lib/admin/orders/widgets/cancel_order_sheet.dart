import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/labelled_field.dart';
import '../order_detail.dart';
import '../orders_api_contract.dart';
import 'busy_label.dart';

/// Runs the cancel transition and answers with the updated order.
typedef CancelSubmit = Future<OrderDetail> Function(String reason);

/// Asks whether the order really is to be cancelled.
///
/// The first of the two steps: cancelling is irreversible and sits one tap
/// away from the actions an admin uses all day, so it is never the single tap
/// that does it. Resolves false if the dialog is dismissed any other way.
Future<bool> confirmOrderCancellation(
  BuildContext context, {
  required String orderId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel this order?'),
      content: Text(
        'Order $orderId will be cancelled. This cannot be undone, and you '
        'will be asked why on the next step.',
        style: AppTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep order'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel order'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Collects the reason the cancel transition needs, then runs it.
///
/// The second of the two steps, opened only once
/// [confirmOrderCancellation] has been answered. Like the ship sheet it runs
/// the request itself, so a failure leaves the reason on screen rather than
/// losing it, and it pops only on success with the updated [OrderDetail].
class CancelOrderSheet extends StatefulWidget {
  const CancelOrderSheet({super.key, required this.onSubmit});

  final CancelSubmit onSubmit;

  /// Opens the sheet. Resolves to the updated order, or null if the admin
  /// backed out without cancelling.
  ///
  /// Drag-to-dismiss is off for the same reason as the ship sheet: a drag
  /// pops the route directly, without consulting the [PopScope] that holds
  /// the sheet shut mid-request.
  static Future<OrderDetail?> show(
    BuildContext context, {
    required CancelSubmit onSubmit,
  }) {
    return showModalBottomSheet<OrderDetail>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => CancelOrderSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<CancelOrderSheet> {
  final TextEditingController _otherReason = TextEditingController();

  /// The dropdown selection, which may be the 'Other' sentinel. Null until
  /// the admin picks something.
  String? _selected;

  bool _submitting = false;

  /// Why the last attempt failed, kept so the chosen reason survives it.
  String? _failure;

  @override
  void dispose() {
    _otherReason.dispose();
    super.dispose();
  }

  bool get _isOther => _selected == OrdersApiContract.otherReasonOption;

  /// What will actually be sent: the chosen line, or the typed one.
  String get _reason => _isOther ? _otherReason.text.trim() : (_selected ?? '');

  bool get _canSubmit => !_submitting && _reason.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final updated = await widget.onSubmit(_reason);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      // Unfiltered on purpose: anything the repository throws has to reach
      // the admin, not only the failures it was meant to throw.
      setState(() => _failure = AsyncContent.messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _close() {
    if (_submitting) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<OrderDetail?>(
      // The cancellation is already on its way; closing now would leave the
      // admin unsure whether it took.
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
                _Header(onClose: _submitting ? null : _close),
                const SizedBox(height: AppSpacing.x5),
                LabelledField(
                  label: 'Reason',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Why is it being cancelled',
                    ),
                    items: [
                      for (final reason
                          in OrdersApiContract.cancellationReasons)
                        DropdownMenuItem(value: reason, child: Text(reason)),
                      const DropdownMenuItem(
                        value: OrdersApiContract.otherReasonOption,
                        child: Text(OrdersApiContract.otherReasonOption),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _selected = value),
                  ),
                ),
                if (_isOther) ...[
                  const SizedBox(height: AppSpacing.x4),
                  LabelledField(
                    label: 'Reason in your own words',
                    child: TextField(
                      controller: _otherReason,
                      enabled: !_submitting,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'What happened',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
                if (_failure != null) ...[
                  const SizedBox(height: AppSpacing.x4),
                  _Failure(message: _failure!),
                ],
                const SizedBox(height: AppSpacing.x5),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  // Destructive, and the last step of a flow that has already
                  // been confirmed once.
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                  child: BusyLabel(label: 'Cancel Order', busy: _submitting),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Reason for cancelling',
            style: AppTypography.sectionTitle,
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          color: AppColors.textGrey,
          disabledColor: AppColors.textMuted,
          tooltip: 'Close',
        ),
      ],
    );
  }
}

/// The last failure, left in the sheet so the chosen reason stays put.
class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
