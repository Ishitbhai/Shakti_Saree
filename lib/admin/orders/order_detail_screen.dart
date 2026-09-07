import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/admin_page_header.dart';
import '../shared/widgets/status_pill.dart';
import 'order_detail.dart';
import 'widgets/order_timeline.dart';
import 'widgets/payment_summary.dart';

/// Full view of a single order: timeline, customer, items and payment.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.detail,
    this.onCall,
    this.onInvoice,
    this.onAdvanceStatus,
  });

  final OrderDetail detail;
  final VoidCallback? onCall;
  final VoidCallback? onInvoice;

  /// Moves the order to its next state — 'Mark Shipped' and so on.
  final VoidCallback? onAdvanceStatus;

  /// Placeholder photo tints, cycled by position. Every entry is a token.
  static const List<Color> _swatches = [
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.info,
    AppColors.primaryLight,
  ];

  @override
  Widget build(BuildContext context) {
    final advanceLabel = detail.status.nextActionLabelLong;

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
                    trailing: _TextAction(label: 'Call', onTap: onCall),
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
                      swatch: _swatches[index % _swatches.length],
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
              advanceLabel: advanceLabel,
              onInvoice: onInvoice,
              onAdvance: onAdvanceStatus,
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

/// Invoice and the status action, pinned below the scrolling detail.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.advanceLabel,
    this.onInvoice,
    this.onAdvance,
  });

  final String? advanceLabel;
  final VoidCallback? onInvoice;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    final label = advanceLabel;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Row(
          children: [
            // No fixed height: the theme sets a minimum and the buttons grow
            // with the platform text scale.
            Expanded(
              child: OutlinedButton(
                onPressed: onInvoice,
                child: const Text('Invoice'),
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: FilledButton(onPressed: onAdvance, child: Text(label)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
