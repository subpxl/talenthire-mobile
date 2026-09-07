import 'package:flutter/material.dart';

/// Local poster stand-ins when a job has no `image_url`.
///
/// These are painted gradients, not bundled photos — the seed JPEGs live under
/// `scripts/job-posters/` and are uploaded to Storage, not shipped in the APK.
class JobAssets {
  JobAssets._();

  static const count = 8;

  static const palettes = <List<Color>>[
    [Color(0xFFFFC1C8), Color(0xFFDC1C38)],
    [Color(0xFFFFE0B2), Color(0xFFEF6C00)],
    [Color(0xFFBBDEFB), Color(0xFF1565C0)],
    [Color(0xFFC8E6C9), Color(0xFF2E7D32)],
    [Color(0xFFE1BEE7), Color(0xFF7B1FA2)],
    [Color(0xFFB2EBF2), Color(0xFF00838F)],
    [Color(0xFFFFF59D), Color(0xFFF9A825)],
    [Color(0xFFCFD8DC), Color(0xFF546E7A)],
  ];

  static List<Color> colorsFor(int index) {
    final i = ((index - 1) % count + count) % count;
    return palettes[i];
  }
}
