import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/common/async_content.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

/// A read from the database in the shop's colours: a spinner while it loads,
/// the reason and a retry if it fails, and [builder] once it is there.
class ShopAsyncView<T> extends StatelessWidget {
  const ShopAsyncView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.placeholderHeight,
  });

  final AsyncValue<T> state;
  final Widget Function(BuildContext context, T value) builder;
  final VoidCallback? onRetry;

  /// Room to keep for the spinner or the message, for a section in a scrolling
  /// page. Left out, they are centred in whatever space there is.
  final double? placeholderHeight;

  Widget _placeholder(Widget child) {
    final height = placeholderHeight;
    if (height == null) return Center(child: child);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return state.when(
      // Reloading keeps the last value on screen: a cart that has just changed
      // should not blink through a spinner.
      skipLoadingOnReload: true,
      loading: () => _placeholder(
        const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
      error: (error, _) => _placeholder(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AsyncContent.messageFor(error),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            if (retry != null)
              TextButton(
                onPressed: retry,
                child: Text(
                  'Retry',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      data: (value) => builder(context, value),
    );
  }
}
