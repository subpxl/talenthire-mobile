import 'package:flutter/material.dart';

/// Paytm app icon — blue tile with brand mark.
class PaytmLogo extends StatelessWidget {
  const PaytmLogo({super.key, this.size = 42});

  final double size;

  static const brandBlue = Color(0xFF00BAF2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brandBlue,
          borderRadius: BorderRadius.circular(size * 0.17),
        ),
        child: Center(
          child: Text(
            'pay',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}
