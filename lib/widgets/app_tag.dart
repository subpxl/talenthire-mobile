import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small label chip for tags (jobs, skills, etc.).
class AppTag extends StatelessWidget {
  final String label;

  const AppTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
