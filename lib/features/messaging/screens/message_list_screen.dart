import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/profile_list_tile.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = context.watch<AppState>().isPremiumUser;
    final welcome = welcomeConversation(l10n);

    return AppScreenLayout(
      title: l10n.navMessages,
      body: AppScrollBody(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isPremium)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                child: PromoBanner(
                  title: l10n.chatWithAgencies,
                  subtitle: l10n.subscribeToApply,
                  actionLabel: l10n.applyNow,
                  onAction: () {
                    if (!AppNavigation.requireSubscription(context)) return;
                  },
                ),
              ),
            ProfileListTile(
              name: welcome.name,
              subtitle: welcome.lastMessage,
              meta: welcome.time,
              avatarColor: welcome.avatarColor,
              showVerified: welcome.isVerified,
              onTap: () => AppNavigation.openMessageDetail(context, welcome),
            ),
          ],
        ),
      ),
    );
  }
}
