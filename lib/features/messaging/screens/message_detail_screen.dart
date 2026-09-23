import 'dart:async';

import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/services/report_service.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';

class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({
    super.key,
    required this.conversation,
  });

  final ConversationThread conversation;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  ConversationThread get conversation => widget.conversation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().messaging?.openThread(conversation);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads an older page of messages once the user nears the top of the
  /// chat, preserving the visual scroll position after the page loads.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset > 120) return;

    final messaging = context.read<AppState>().messaging;
    if (messaging == null || messaging.isLoadingMore || !messaging.hasMoreMessages) {
      return;
    }

    final oldExtent = _scrollController.position.maxScrollExtent;
    final oldOffset = _scrollController.offset;
    unawaited(messaging.loadMoreMessages().then((_) {
      if (!mounted || !_scrollController.hasClients) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newExtent = _scrollController.position.maxScrollExtent;
        final diff = newExtent - oldExtent;
        if (diff > 0) {
          _scrollController.jumpTo(oldOffset + diff);
        }
      });
    }));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!AppNavigation.requireSubscription(context)) return;

    _controller.clear();

    try {
      await context.read<AppState>().messaging?.sendMessage(text);
    } catch (_) {
      if (!mounted) return;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      showAppToast(
        context,
        'Could not send',
        type: AppToastType.error,
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.innerTab,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messaging = context.watch<AppState>().messaging;
    final isWelcome = conversation.isCompanyWelcome;
    final stored = messaging?.activeMessages ?? conversation.messages;
    final messages = isWelcome
        ? [
            ChatMessage(
              id: '${ConversationThread.companyWelcomeId}_body',
              text: l10n.companyWelcomeMessageBody,
              isMine: false,
              time: conversation.time,
            ),
            ...stored.where((message) => message.isMine),
          ]
        : stored;
    final isSending = messaging?.isSending ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || messages.isEmpty) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= maxExtent - 80) {
        _scrollController.jumpTo(maxExtent);
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<AppState>().messaging?.closeThread();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            isWelcome
                ? PlaceholderAvatar(
                    radius: 18,
                    color: conversation.avatarColor,
                    iconSize: 18,
                  )
                : JobAvatar(
                    imageIndex: conversation.imageIndex,
                    radius: 18,
                    imageUrl: conversation.imageUrl,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      isWelcome
                          ? l10n.bombayCastingCompany
                          : conversation.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (conversation.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      color: AppColors.chatGreen,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isWelcome)
            PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'report') {
                final l10n = AppLocalizations.of(context)!;
                await ReportService.instance.submitFromDialog(
                  context,
                  dialogTitle: l10n.report,
                  successMessage: l10n.conversationReported,
                  target: ReportTarget(
                    type: ReportType.conversation,
                    targetId: conversation.id,
                    targetLabel: conversation.name,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(AppLocalizations.of(context)!.report),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isWelcome && (messaging?.isLoadingMore ?? false))
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      l10n.noMessagesYetSayHello,
                      style: context.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.md,
                      AppSpacing.screenH,
                      AppSpacing.md,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: messages[index]);
                    },
                  ),
          ),
          _ComposerBar(
            controller: _controller,
            onSend: isSending ? null : _sendMessage,
          ),
        ],
      ),
    ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.md),
                    topRight: const Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(isMine ? AppRadius.md : 4),
                    bottomRight: Radius.circular(isMine ? 4 : AppRadius.md),
                  ),
                  border: isMine
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: isMine ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(message.time, style: context.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            10,
            AppSpacing.sm,
            10,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('e2e_message_composer'),
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  enabled: true,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: onSend == null ? null : (_) => onSend!(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const Key('e2e_message_send'),
                tooltip: 'Send',
                onPressed: onSend,
                color: AppColors.primary,
                icon: onSend == null
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
