import 'package:flutter/material.dart';
import 'package:bombay_casting/core/widgets/google_logo.dart';

/// Google Pay app icon — white tile with the Google "G" mark.
class GooglePayLogo extends StatelessWidget {
  const GooglePayLogo({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.17),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Center(
          child: GoogleLogo(size: size * 0.52),
        ),
      ),
    );
  }
}
