import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_feed_status.dart';
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
    final conversations =
        messaging?.conversations ?? const <ConversationThread>[];
    final isLoading = messaging?.isLoading ?? true;
    final loadError = messaging?.loadError;

    return AppScreenLayout(
      title: l10n.navMessages,
      body: AppScrollBody(
        padding: EdgeInsets.zero,
        onRefresh: messaging == null
            ? null
            : () async => messaging.retry(),
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
            if (conversations.isNotEmpty)
              ...conversations.asMap().entries.map((entry) {
                final index = entry.key;
                final thread = entry.value;
                final isWelcome = thread.isCompanyWelcome;
                return ProfileListTile(
                  key: index == 0
                      ? const Key('e2e_message_thread_first')
                      : null,
                  name: isWelcome
                      ? l10n.bombayCastingCompany
                      : thread.name,
                  subtitle: isWelcome
                      ? (thread.lastSenderId == 'local'
                          ? thread.lastMessage
                          : l10n.companyWelcomeMessagePreview)
                      : (thread.lastMessage.isEmpty
                          ? l10n.startAConversation
                          : thread.lastMessage),
                  meta: thread.time,
                  avatarColor: thread.avatarColor,
                  showVerified: thread.isVerified,
                  trailing: thread.hasIncomingUnread
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
              })
            else if (isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppFeedStatus.spinner,
              )
            else
              AppFeedStatus(
                errorMessage:
                    loadError != null ? l10n.couldNotLoadMessages : null,
                emptyMessage: l10n.agenciesMessageYouAfterYouApply,
                onRetry: loadError != null ? messaging?.retry : null,
                retryLabel: l10n.tryAgain,
                textAlign: TextAlign.center,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
          ],
        ),
      ),
    );
  }
}
