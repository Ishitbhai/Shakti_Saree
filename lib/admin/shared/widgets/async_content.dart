import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Renders the four states of an async read the same way everywhere: waiting,
/// failed, empty, loaded.
///
/// [value] is null while the read is in flight. [error] wins over everything,
/// so a stale value is never shown next to a failure.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.error,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage,
  });

  /// Null while loading.
  final T? value;

  final ApiException? error;

  /// Builds the loaded state.
  final Widget Function(BuildContext context, T value) builder;

  /// Offered alongside the failure message when given.
  final VoidCallback? onRetry;

  /// Decides whether a loaded value counts as empty; omit for values that
  /// cannot be.
  final bool Function(T value)? isEmpty;

  /// Shown instead of [builder] when [isEmpty] says so.
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    if (failure != null) {
      return AsyncMessage(text: failure.message, onRetry: onRetry);
    }

    final loaded = value;
    if (loaded == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final empty = isEmpty?.call(loaded) ?? false;
    final message = emptyMessage;
    if (empty && message != null) return AsyncMessage(text: message);

    return builder(context, loaded);
  }
}

/// Centred line of explanatory text, with an optional retry beneath it.
class AsyncMessage extends StatelessWidget {
  const AsyncMessage({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            if (retry != null) ...[
              const SizedBox(height: AppSpacing.x3),
              OutlinedButton(onPressed: retry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
