import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Renders the four states of an async read the same way everywhere: waiting,
/// failed, empty, loaded.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage,
  });

  final AsyncValue<T> state;

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
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          AsyncMessage(text: messageFor(error), onRetry: onRetry),
      data: (value) {
        final empty = isEmpty?.call(value) ?? false;
        final message = emptyMessage;
        if (empty && message != null) return AsyncMessage(text: message);
        return builder(context, value);
      },
    );
  }

  /// Wording for whatever a repository threw.
  ///
  /// Repositories are meant to surface [ApiException]; anything else is a bug
  /// rather than something a user can act on, so it gets the generic line.
  static String messageFor(Object error) => error is ApiException
      ? error.message
      : const UnknownApiException().message;
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
