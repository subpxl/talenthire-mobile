import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

class ShareLinkButton extends StatelessWidget {
  const ShareLinkButton({
    super.key,
    required this.url,
    required this.message,
  });

  final String url;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Share',
      icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
      onPressed: () {
        SharePlus.instance.share(
          ShareParams(text: '$message\n$url'),
        );
      },
    );
  }
}
