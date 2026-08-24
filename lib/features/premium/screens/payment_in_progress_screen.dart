import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

class PaymentInProgressScreen extends StatelessWidget {
  const PaymentInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(AppLocalizations.of(context)!.paymentsAreNotAvailableYetYouCanGoBackAndKeepUsingTheApp,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
