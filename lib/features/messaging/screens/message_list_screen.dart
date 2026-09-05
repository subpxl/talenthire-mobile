import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/profile_list_tile.dart';
import 'package:bombay_casting/core/widgets/promo_banner.dart';
import 'package:bombay_casting/core/widgets/unread_count_badge.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final messaging = appState.messaging;
    final isPremium = appState.isPremiumUser;
    final conversations = messaging?.conversations ?? const <ConversationThread>[];
    final isLoading = messaging?.isLoading ?? true;
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
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              ProfileListTile(
                name: welcome.name,
                subtitle: welcome.lastMessage,
                meta: welcome.time,
                avatarColor: welcome.avatarColor,
                showVerified: welcome.isVerified,
                trailing: welcome.unreadCount > 0
                    ? UnreadCountBadge(count: welcome.unreadCount)
                    : null,
                onTap: () => AppNavigation.openMessageDetail(context, welcome),
              ),
              if (conversations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l10n.agenciesMessageYouAfterYouApply,
                    textAlign: TextAlign.center,
                    style: context.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...conversations.map((thread) {
                  return ProfileListTile(
                    name: thread.name,
                    subtitle: thread.lastMessage.isEmpty
                        ? l10n.startAConversation
                        : thread.lastMessage,
                    meta: thread.time,
                    avatarColor: thread.avatarColor,
                    showVerified: thread.isVerified,
                    trailing: thread.unreadCount > 0
                        ? UnreadCountBadge(count: thread.unreadCount)
                        : null,
                    onTap: () async {
                      final provider = appState.messaging;
                      if (provider == null) return;
                      await provider.openThread(thread);
                      if (!context.mounted) return;
                      AppNavigation.openMessageDetail(context, thread);
                    },
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

