import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/order_detail.dart';

/// Vertical fulfilment timeline: completed steps carry a tick and a
/// timestamp, the rest are greyed out and read 'Pending'.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.events});

  final List<OrderEvent> events;

  /// Straight from the design; not on the base-4 scale.
  static const double _marker = 20;
  static const double _connector = 2;
  static const double _rowGap = AppSpacing.x5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < events.length; index++)
          _Step(
            event: events[index],
            isLast: index == events.length - 1,
            // The connector belongs to the step above it, so it is only
            // maroon once that step is done.
            connectorDone: events[index].isDone,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.event,
    required this.isLast,
    required this.connectorDone,
  });

  final OrderEvent event;
  final bool isLast;
  final bool connectorDone;

  @override
  Widget build(BuildContext context) {
    final done = event.isDone;
    final at = event.at;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: OrderTimeline._marker,
            child: Column(
              children: [
                _Marker(done: done),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: OrderTimeline._connector,
                      color: connectorDone
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : OrderTimeline._rowGap,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: done ? AppColors.textDark : AppColors.textMuted,
                        fontWeight: done ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    at == null ? 'Pending' : Formatters.dayTime(at),
                    style: AppTypography.caption.copyWith(
                      color: done ? AppColors.textGrey : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: OrderTimeline._marker,
      width: OrderTimeline._marker,
      decoration: BoxDecoration(
        color: done ? AppColors.primary : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: done
          ? const Icon(Icons.check, size: 13, color: AppColors.textOnPrimary)
          : null,
    );
  }
}
