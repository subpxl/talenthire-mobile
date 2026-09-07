import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared content URLs used across the app.
/// Change these here when a link needs to be updated.
class AppLinks {
  AppLinks._();

  /// Example introduction video shown on the job apply sheet.
  static const exampleIntroductionVideo =
      'https://m.youtube.com/results?sp=mAEA&search_query=example+introduction+video+india+modeling';
}

Future<void> openAppLink(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppToast(
      context,
      'Could not open this link right now',
      type: AppToastType.error,
    );
  }
}
