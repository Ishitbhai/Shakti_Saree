import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../order_detail.dart';

/// Vertical fulfilment timeline: completed steps carry a tick and a
/// timestamp, the rest are greyed out and read 'Pending'.
///
/// A cancellation is drawn as its own kind of step — crossed rather than
/// ticked, and in the error colour — because it ends the timeline instead of
/// carrying it forward. The steps are given; which ones exist is the order's
/// business, not this widget's.
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
            // maroon once that step is done — and takes the error colour
            // when what comes next is the cancellation.
            connectorDone: events[index].isDone,
            connectorIsCancellation:
                index + 1 < events.length && events[index + 1].isCancellation,
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
    required this.connectorIsCancellation,
  });

  final OrderEvent event;
  final bool isLast;
  final bool connectorDone;
  final bool connectorIsCancellation;

  @override
  Widget build(BuildContext context) {
    final done = event.isDone;
    final cancelled = event.isCancellation;
    final at = event.at;
    final detail = event.detail;

    final labelColour = cancelled
        ? AppColors.error
        : done
        ? AppColors.textDark
        : AppColors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: OrderTimeline._marker,
            child: Column(
              children: [
                _Marker(done: done, cancelled: cancelled),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: OrderTimeline._connector,
                      color: connectorIsCancellation
                          ? AppColors.error
                          : connectorDone
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.label,
                          style: AppTypography.bodyMedium.copyWith(
                            color: labelColour,
                            fontWeight: done
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Text(
                        at == null ? 'Pending' : Formatters.dayTime(at),
                        style: AppTypography.caption.copyWith(
                          color: done
                              ? AppColors.textGrey
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  // The courier and AWB, or the reason it was cancelled.
                  if (detail != null) ...[
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      detail,
                      style: AppTypography.caption.copyWith(
                        color: cancelled ? AppColors.error : AppColors.textGrey,
                      ),
                    ),
                  ],
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
  const _Marker({required this.done, required this.cancelled});

  final bool done;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final filled = cancelled
        ? AppColors.error
        : done
        ? AppColors.primary
        : AppColors.border;

    return Container(
      height: OrderTimeline._marker,
      width: OrderTimeline._marker,
      decoration: BoxDecoration(color: filled, shape: BoxShape.circle),
      child: cancelled
          ? const Icon(Icons.close, size: 13, color: AppColors.textOnPrimary)
          : done
          ? const Icon(Icons.check, size: 13, color: AppColors.textOnPrimary)
          : null,
    );
  }
}
