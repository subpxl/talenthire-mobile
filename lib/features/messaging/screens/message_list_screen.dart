import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremiumUser;
    return AppScreenLayout(
      title: 'Messages',
      body: AppScrollBody(
        child: Column(
          children: [
            if (!isPremium)
              PromoBanner(
                title: 'Chat with agencies',
                subtitle:
                    'Apply to a job and your conversations will show up here',
                actionLabel: 'Apply now',
                onAction: () {
                  if (!AppNavigation.requireSubscription(context)) return;
                },
              ),
            if (!isPremium) const SizedBox(height: AppSpacing.lg - 4),
            Text(AppLocalizations.of(context)!.agenciesMessageYouAfterYouApply,
              style: context.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
