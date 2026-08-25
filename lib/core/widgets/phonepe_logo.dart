import 'package:flutter/material.dart';

/// PhonePe app icon — purple tile with the Devanagari "पे" mark.
class PhonePeLogo extends StatelessWidget {
  const PhonePeLogo({super.key, this.size = 42});

  final double size;

  static const brandPurple = Color(0xFF5F259F);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brandPurple,
          borderRadius: BorderRadius.circular(size * 0.17),
        ),
        child: Center(
          child: Text(
            'पे',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.48,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
