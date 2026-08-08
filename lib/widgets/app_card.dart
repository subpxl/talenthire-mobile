import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent card wrapper used across list and dashboard views.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.cardRadius);
    final card = Card(
      margin: margin,
      color: color,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            )
          : Padding(padding: padding, child: child),
    );

    if (margin == null) return card;
    return card;
  }
}
