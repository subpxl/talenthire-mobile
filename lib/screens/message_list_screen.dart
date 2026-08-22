import 'package:flutter/material.dart';
import 'package:bombay_casting/navigation/app_navigation.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/app_screen_layout.dart';
import 'package:bombay_casting/widgets/promo_banner.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenLayout(
      title: 'Messages',
      body: AppScrollBody(
        child: Column(
          children: [
            PromoBanner(
              title: 'Chat with agencies',
              subtitle:
                  'Apply to a job and your conversations will show up here',
              actionLabel: 'Apply now',
              onAction: () {
                if (!AppNavigation.requireSubscription(context)) return;
              },
            ),
            const SizedBox(height: AppSpacing.lg - 4),
            Text(
              'Agencies message you after you apply',
              style: context.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
