import 'package:flutter/material.dart';

class VerifiedTick extends StatelessWidget {
  const VerifiedTick({super.key, this.size = 16, this.color = _blue});

  static const _blue = Color(0xFF1D9BF0);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.verified, size: size, color: color);
  }
}
