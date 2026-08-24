import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final inset = stroke / 2;
    final arcRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    paint.color = _blue;
    canvas.drawArc(arcRect, -45 * math.pi / 180, 135 * math.pi / 180, false, paint);

    paint.color = _green;
    canvas.drawArc(arcRect, 90 * math.pi / 180, 70 * math.pi / 180, false, paint);

    paint.color = _yellow;
    canvas.drawArc(arcRect, 160 * math.pi / 180, 70 * math.pi / 180, false, paint);

    paint.color = _red;
    canvas.drawArc(arcRect, 230 * math.pi / 180, 85 * math.pi / 180, false, paint);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width / 2 - inset * 0.2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
