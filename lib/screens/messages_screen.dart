import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/empty_state.dart';
import 'message_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final userId = state.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: state.conversations.isEmpty
          ? const EmptyState(
              icon: Icons.message_outlined,
              title: 'No messages yet',
              subtitle: 'Contact artists from the Artists tab',
              iconSize: 64,
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final chat = state.conversations[index];
                final otherName = chat.getOtherParticipantName(userId);
                final otherInitials = chat.getOtherParticipantInitials(userId);
                final unread = chat.unreadFor(userId);

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageDetailScreen(conversation: chat),
                      ),
                    );
                  },
                  leading: AppAvatar(
                    initials: otherInitials,
                  ),
                  title: Text(
                    otherName,
                    style: TextStyle(
                      fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatTimeAgo(chat.updatedAt),
                        style: TextStyle(
                          color: unread > 0 ? context.colors.primary : AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
