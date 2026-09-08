import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/models/order_status.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/async_content.dart';
import '../shared/widgets/status_pill.dart';
import 'order_detail.dart';
import 'orders_providers.dart';
import 'orders_repository.dart';
import '../shared/widgets/busy_label.dart';
import 'widgets/cancel_order_sheet.dart';
import 'widgets/order_timeline.dart';
import 'widgets/payment_summary.dart';
import 'widgets/ship_order_sheet.dart';

/// Full view of a single order: timeline, customer, items and payment.
///
/// Owns the order's state from here on. A transition returns the updated
/// record, so the screen holds a mutable copy of [detail] rather than
/// redrawing from the value it was constructed with.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.detail,
    this.onCall,
    this.onInvoice,
  });

  /// The record as it stood when the screen opened.
  final OrderDetail detail;

  final VoidCallback? onCall;
  final VoidCallback? onInvoice;

  /// Placeholder photo tints, cycled by position. Every entry is a token.
  static const List<Color> _swatches = [
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.info,
    AppColors.primaryLight,
  ];

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late OrderDetail detail = widget.detail;

  /// True exactly while a transition that runs from the bar itself is in
  /// flight. Ship and cancel run inside their own sheets, which show their
  /// own progress and block the bar behind a modal barrier anyway.
  bool _advancing = false;

  /// What the primary button does from here, or null once the order is
  /// finished and there is nothing left to do to it.
  ///
  /// Most statuses advance straight away. Shipping first opens a sheet,
  /// because it cannot be done without the courier details.
  VoidCallback? get _onAdvance {
    final id = detail.id;

    Future<OrderDetail> Function()? straightThrough = switch (detail.status) {
      OrderStatus.isNew => () => _repository.acceptOrder(id),
      OrderStatus.accepted => () => _repository.markPacked(id),
      OrderStatus.shipped => () => _repository.markDelivered(id),
      OrderStatus.packed => null,
      OrderStatus.delivered || OrderStatus.cancelled => null,
    };

    if (straightThrough != null) return () => _run(straightThrough);
    return detail.status == OrderStatus.packed ? _ship : null;
  }

  OrdersRepository get _repository => ref.read(ordersRepositoryProvider);

  /// Opens the ship sheet, which runs the transition itself and hands back
  /// the updated order — or null if the admin backed out.
  Future<void> _ship() async {
    final id = detail.id;
    final updated = await ShipOrderSheet.show(
      context,
      onSubmit: ({required courier, required awbNumber}) =>
          _repository.markShipped(id, courier: courier, awbNumber: awbNumber),
    );
    if (!mounted || updated == null) return;
    _settle(updated);
  }

  /// Runs one transition, holding the bar disabled until it settles.
  ///
  /// The `finally` is the point: whatever the repository does — returns, or
  /// throws anything at all — the spinner comes off. The catch is deliberately
  /// unfiltered for the same reason: a repository that throws something other
  /// than an [ApiException] is a bug, but the admin still gets told rather
  /// than watching the screen do nothing.
  Future<void> _run(Future<OrderDetail> Function() go) async {
    setState(() => _advancing = true);
    try {
      final updated = await go();
      if (!mounted) return;
      _settle(updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AsyncContent.messageFor(error))));
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  /// Takes the order the transition returned, and tells the list behind this
  /// screen that what it is holding is now stale.
  ///
  /// Every successful transition goes through here, so popping back always
  /// lands on a list that agrees with what just happened — including the
  /// header count and which filter chip the order now sits under.
  void _settle(OrderDetail updated) {
    setState(() => detail = updated);
    ref.invalidate(ordersProvider);
  }

  /// Cancels the order in two steps: confirm, then say why.
  ///
  /// Either step can be backed out of, and neither the dialog nor the sheet
  /// changes anything on its own — the sheet runs the transition and hands
  /// back the updated order.
  Future<void> _cancel() async {
    final id = detail.id;

    final confirmed = await confirmOrderCancellation(context, orderId: id);
    if (!mounted || !confirmed) return;

    final updated = await CancelOrderSheet.show(
      context,
      onSubmit: (reason) => _repository.cancelOrder(id, reason: reason),
    );
    if (!mounted || updated == null) return;
    _settle(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This screen is a single white sheet rather than cards on cream.
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: detail.id,
              subtitle: Formatters.dateTime(detail.placedAt),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x4,
                  AppSpacing.x5,
                  AppSpacing.x6,
                ),
                children: [
                  _SectionHeader(
                    title: 'Order Status',
                    trailing: StatusPill(status: detail.status),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  OrderTimeline(events: detail.timeline),
                  const _SectionGap(),
                  _SectionHeader(
                    title: 'Customer & Delivery',
                    trailing: _TextAction(label: 'Call', onTap: widget.onCall),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _IconLine(
                    icon: Icons.person_outline,
                    text: '${detail.customer}  •  ${detail.phone}',
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _IconLine(
                    icon: Icons.location_on_outlined,
                    text: detail.address,
                  ),
                  const _SectionGap(),
                  _SectionHeader(
                    title: 'Items (${Formatters.count(detail.lines.length)})',
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  for (var index = 0; index < detail.lines.length; index++) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.x3),
                    _LineTile(
                      line: detail.lines[index],
                      swatch:
                          OrderDetailScreen._swatches[index %
                              OrderDetailScreen._swatches.length],
                    ),
                  ],
                  const _SectionGap(),
                  const _SectionHeader(title: 'Payment Summary'),
                  const SizedBox(height: AppSpacing.x3),
                  PaymentSummary(detail: detail),
                ],
              ),
            ),
            _ActionBar(
              status: detail.status,
              advancing: _advancing,
              onInvoice: widget.onInvoice,
              onAdvance: _onAdvance,
              onCancel: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Divider plus the breathing room either side of it.
class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x5),
      child: Divider(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final action = trailing;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionTitle,
          ),
        ),
        if (action != null) ...[const SizedBox(width: AppSpacing.x2), action],
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x1,
          ),
          child: ExcludeSemantics(
            child: Text(label, style: AppTypography.labelMedium),
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: 16, color: AppColors.textGrey),
        ),
        const SizedBox(width: AppSpacing.x2),
        Expanded(child: Text(text, style: AppTypography.bodySmall)),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.swatch});

  final OrderLine line;
  final Color swatch;

  /// Straight from the design; not on the base-4 scale.
  static const double _thumb = 46;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label:
            '${line.name}, SKU ${line.sku}, quantity ${line.quantity}, '
            '${Formatters.rupeesFromPaise(line.pricePaise)}',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                height: _thumb,
                width: _thumb,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: AppRadii.cardRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      '${line.sku}  ·  Qty ${Formatters.count(line.quantity)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Text(
                Formatters.rupeesFromPaise(line.pricePaise),
                style: AppTypography.price,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Invoice, the status action, and cancellation — pinned below the scrolling
/// detail and driven entirely by the order's current status.
///
/// Which controls exist is [OrderStatus]'s decision: the advance button
/// appears wherever there is a next status, and cancelling appears while the
/// parcel is still in hand. A terminal order is left with Invoice alone.
///
/// While an advance is in flight everything disables and that button swaps
/// its label for a spinner, so it is clear the app is working. Ship and
/// cancel report their own progress inside their sheets instead.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.status,
    required this.advancing,
    this.onInvoice,
    this.onAdvance,
    this.onCancel,
  });

  final OrderStatus status;
  final bool advancing;
  final VoidCallback? onInvoice;
  final VoidCallback? onAdvance;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final label = status.nextActionLabelLong;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // No fixed height: the theme sets a minimum and the buttons
                // grow with the platform text scale.
                Expanded(
                  child: OutlinedButton(
                    onPressed: advancing ? null : onInvoice,
                    child: const Text('Invoice'),
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: FilledButton(
                      onPressed: advancing ? null : onAdvance,
                      child: BusyLabel(label: label, busy: advancing),
                    ),
                  ),
                ],
              ],
            ),
            // Destructive, so it sits on its own line below the row rather
            // than competing with the action an admin usually wants — and
            // three buttons abreast do not fit a narrow phone.
            if (status.canCancel) ...[
              const SizedBox(height: AppSpacing.x2),
              TextButton(
                onPressed: advancing ? null : onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  disabledForegroundColor: AppColors.textMuted,
                ),
                // No spinner here: this opens a confirmation rather than
                // starting the request, and the sheet behind it reports its
                // own progress.
                child: const Text('Cancel Order'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
