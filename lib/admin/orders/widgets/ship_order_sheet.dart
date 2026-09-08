import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../shared/widgets/async_content.dart';
import '../../shared/widgets/labelled_field.dart';
import '../order_detail.dart';
import '../orders_api_contract.dart';
import 'busy_label.dart';

/// Runs the ship transition and answers with the updated order.
typedef ShipSubmit =
    Future<OrderDetail> Function({
      required String courier,
      required String awbNumber,
    });

/// Collects the courier and AWB number that the ship transition needs, then
/// runs it.
///
/// The sheet performs the request itself rather than handing the values back,
/// so a failure can leave the typed AWB on screen to retry instead of losing
/// it behind a closing animation. It pops only on success, returning the
/// updated [OrderDetail].
class ShipOrderSheet extends StatefulWidget {
  const ShipOrderSheet({super.key, required this.onSubmit});

  final ShipSubmit onSubmit;

  /// Opens the sheet. Resolves to the updated order, or null if the admin
  /// backed out without shipping.
  ///
  /// Drag-to-dismiss is off: whether the sheet may close changes while a
  /// request is in flight, and a drag closes the route directly without
  /// consulting the [PopScope] below. The barrier, the system back gesture
  /// and the close button all honour it, so those are the ways out.
  static Future<OrderDetail?> show(
    BuildContext context, {
    required ShipSubmit onSubmit,
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
      builder: (_) => ShipOrderSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<ShipOrderSheet> createState() => _ShipOrderSheetState();
}

class _ShipOrderSheetState extends State<ShipOrderSheet> {
  final TextEditingController _otherCourier = TextEditingController();
  final TextEditingController _awb = TextEditingController();

  /// The dropdown selection, which may be the 'Other' sentinel rather than a
  /// carrier. Null until the admin picks something.
  String? _selected;

  /// Set once the AWB field has been edited, so the field does not open
  /// already complaining about being empty.
  bool _awbTouched = false;

  bool _submitting = false;

  /// Why the last attempt failed, kept in the sheet so the values survive it.
  String? _failure;

  @override
  void dispose() {
    _otherCourier.dispose();
    _awb.dispose();
    super.dispose();
  }

  bool get _isOther => _selected == OrdersApiContract.otherCourierOption;

  /// What will actually be sent: the chosen carrier, or the typed one.
  String get _courierName =>
      _isOther ? _otherCourier.text.trim() : (_selected ?? '');

  String get _awbNumber => _awb.text.trim();

  /// Trimmed and long enough, and nothing else — carriers number
  /// consignments too differently for a stricter check to be safe.
  String? get _awbError {
    if (_awbNumber.isEmpty) return 'Enter the AWB number.';
    if (_awbNumber.length < OrdersApiContract.awbMinLength) {
      return 'That looks too short — AWB numbers are at least '
          '${OrdersApiContract.awbMinLength} characters.';
    }
    return null;
  }

  bool get _canSubmit =>
      !_submitting && _courierName.isNotEmpty && _awbError == null;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final updated = await widget.onSubmit(
        courier: _courierName,
        awbNumber: _awbNumber,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      // Unfiltered on purpose: anything the repository throws has to reach
      // the admin, not only the failures it was meant to throw.
      setState(() => _failure = AsyncContent.messageFor(error));
    } finally {
      // However it ended, the sheet stops being locked.
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
      // A request is already on its way to the server; closing now would
      // leave the admin unsure whether the order shipped.
      canPop: !_submitting,
      child: Padding(
        // Lifts the sheet clear of the keyboard as it opens.
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
                  label: 'Courier',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Choose a courier',
                    ),
                    items: [
                      for (final courier in OrdersApiContract.couriers)
                        DropdownMenuItem(value: courier, child: Text(courier)),
                      const DropdownMenuItem(
                        value: OrdersApiContract.otherCourierOption,
                        child: Text(OrdersApiContract.otherCourierOption),
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
                    label: 'Courier name',
                    child: TextField(
                      controller: _otherCourier,
                      enabled: !_submitting,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Who is carrying it',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x4),
                LabelledField(
                  label: 'AWB number',
                  child: TextField(
                    controller: _awb,
                    enabled: !_submitting,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Tracking number',
                      // Only once it has been touched, so the sheet does not
                      // open by telling the admin off.
                      errorText: _awbTouched ? _awbError : null,
                    ),
                    onChanged: (_) => setState(() => _awbTouched = true),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                if (_failure != null) ...[
                  const SizedBox(height: AppSpacing.x4),
                  _Failure(message: _failure!),
                ],
                const SizedBox(height: AppSpacing.x5),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: BusyLabel(
                    label: 'Confirm Shipment',
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

class _Header extends StatelessWidget {
  const _Header({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Ship Order', style: AppTypography.sectionTitle)),
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

/// The last failure, left in the sheet so the typed values stay put.
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
