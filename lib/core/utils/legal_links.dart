import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  LegalLinks._();

  static const terms = 'https://bombaycastingcompany.com/terms';
  static const privacy = 'https://bombaycastingcompany.com/privacy';
  static const refunds = 'https://bombaycastingcompany.com/refunds';
  static const website = 'https://bombaycastingcompany.com';
}

Future<void> openLegalPage(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppToast(
      context,
      AppLocalizations.of(context)!.couldNotOpenThisPageRightNow,
      type: AppToastType.error,
    );
  }
}
