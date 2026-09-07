import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_feed_status.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/notifications/models/app_notification.dart';
import 'package:bombay_casting/features/profile/screens/edit_profile_view_screen.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final appState = context.read<AppState>();
    await appState.notifications?.markRead(notification);

    if (!context.mounted) return;

    if (notification.isMessage) {
      final thread = await appState.messaging?.openConversation(
        notification.conversationId,
      );
      if (!context.mounted) return;
      if (thread != null) {
        AppNavigation.openMessageDetail(context, thread);
      }
      return;
    }

    if (notification.isJob && notification.jobId.isNotEmpty) {
      final job = await appState.fetchJobById(notification.jobId);
      if (!context.mounted) return;
      if (job != null) {
        AppNavigation.openJobDetail(context, JobDetailData.fromJob(job));
      }
      return;
    }

    if (notification.isApplication) {
      appState.setHomeInnerTab(2);
      Navigator.maybePop(context);
      return;
    }

    if (notification.isProfile) {
      AppNavigation.push(context, const EditProfileScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<AppState>().notifications;
    final items = inbox?.items ?? const <AppNotification>[];
    final isLoading = inbox?.isLoading ?? true;
    final unreadCount = inbox?.unreadCount ?? 0;
    final loadError = inbox?.loadError;
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (isLoading) {
      body = const Center(child: AppFeedStatus.spinner);
    } else if (items.isEmpty) {
      body = Center(
        child: AppFeedStatus(
          errorMessage:
              loadError != null ? l10n.couldNotLoadNotifications : null,
          emptyMessage:
              'No notifications yet. Agency messages and admin alerts will show up here.',
          onRetry: loadError != null ? inbox?.retry : null,
          retryLabel: l10n.tryAgain,
          textAlign: TextAlign.center,
          padding: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    } else {
      body = ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _NotificationTile(
            notification: item,
            onTap: () => _openNotification(context, item),
          );
        },
      );
    }

    if (inbox != null) {
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => inbox.retry(),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: body,
                  ),
                ],
              )
            : body,
      );
    }

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
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => inbox?.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.read ? AppColors.surface : AppColors.primaryLight,
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title.isEmpty
                          ? 'Notification'
                          : notification.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: notification.read
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: context.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ],
                    if (notification.timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(notification.timeLabel, style: context.caption),
                    ],
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.brandRed,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
