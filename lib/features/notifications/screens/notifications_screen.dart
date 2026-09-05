import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/profile_list_tile.dart';
import 'package:bombay_casting/core/widgets/unread_count_badge.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';
import 'package:bombay_casting/features/profile/screens/edit_profile_view_screen.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final messaging = appState.messaging;
    final conversations =
        messaging?.conversations ?? const <ConversationThread>[];
    final welcome = welcomeConversation(l10n);
    final messageThreads = [welcome, ...conversations];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const _SectionLabel('Messages'),
          ...messageThreads.map((thread) {
            final unread = thread.unreadCount > 0 ? thread.unreadCount : 1;
            return ProfileListTile(
              name: thread.name,
              subtitle: thread.lastMessage.isEmpty
                  ? l10n.startAConversation
                  : thread.lastMessage,
              meta: thread.time,
              avatarColor: thread.avatarColor,
              showVerified: thread.isVerified,
              trailing: UnreadCountBadge(count: unread),
              onTap: () async {
                if (thread.isWelcome) {
                  AppNavigation.openMessageDetail(context, thread);
                  return;
                }
                final provider = appState.messaging;
                if (provider == null) return;
                await provider.openThread(thread);
                if (!context.mounted) return;
                AppNavigation.openMessageDetail(context, thread);
              },
            );
          }),
          const _SectionLabel('Other'),
          _OtherTile(
            icon: Icons.work_outline,
            title: 'New jobs for you',
            subtitle: 'Fresh casting calls match your profile.',
            time: 'Today',
            onTap: () => Navigator.maybePop(context),
          ),
          _OtherTile(
            icon: Icons.visibility_outlined,
            title: 'Application viewed',
            subtitle: 'An agency opened your application.',
            time: 'Yesterday',
            onTap: () => Navigator.maybePop(context),
          ),
          _OtherTile(
            icon: Icons.person_outline,
            title: 'Complete your profile',
            subtitle: 'Add more details to get shortlisted faster.',
            time: '2 days ago',
            onTap: () => AppNavigation.push(
              context,
              const EditProfileScreen(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        18,
        AppSpacing.screenH,
        8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _OtherTile extends StatelessWidget {
  const _OtherTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: context.bodyMedium.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(time, style: context.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
