import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Loading spinner, load-error + retry, or empty copy for list feeds.
class AppFeedStatus extends StatelessWidget {
  const AppFeedStatus({
    super.key,
    this.isLoading = false,
    this.errorMessage,
    this.emptyMessage,
    this.onRetry,
    this.retryLabel,
    this.textAlign = TextAlign.start,
    this.padding = const EdgeInsets.only(top: AppSpacing.sm),
  });

  final bool isLoading;
  final String? errorMessage;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  static const Widget spinner = Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (isLoading) {
      child = const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: spinner,
      );
    } else if (errorMessage != null) {
      child = Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            errorMessage!,
            textAlign: textAlign,
            style: context.bodyMedium,
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? 'Try again'),
            ),
        ],
      );
    } else if (emptyMessage != null) {
      child = Text(
        emptyMessage!,
        textAlign: textAlign,
        style: context.bodyMedium,
      );
    } else {
      child = const SizedBox.shrink();
    }

    return Padding(padding: padding, child: child);
  }
}
