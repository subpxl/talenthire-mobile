import 'package:flutter/material.dart';

/// PhonePe app icon — circular purple mark from brand asset.
class PhonePeLogo extends StatelessWidget {
  const PhonePeLogo({super.key, this.size = 32});

  final double size;

  static const assetPath = 'assets/icons/phonepe.webp';

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
