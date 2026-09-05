import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/report_dialog.dart';

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
  late List<ChatMessage> _localMessages;

  ConversationThread get conversation => widget.conversation;

  bool get _isWelcome => conversation.isWelcome;

  @override
  void initState() {
    super.initState();
    _localMessages = List<ChatMessage>.from(conversation.messages);
    if (!_isWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppState>().messaging?.openThread(conversation);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    if (_isWelcome) {
      setState(() {
        _localMessages.add(
          ChatMessage(
            text: text,
            isMine: true,
            time: 'Now',
          ),
        );
      });
    } else {
      await context.read<AppState>().messaging?.sendMessage(text);
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
    final messages = _isWelcome
        ? _localMessages
        : (messaging?.activeMessages ?? conversation.messages);
    final isSending = !_isWelcome && (messaging?.isSending ?? false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || messages.isEmpty) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= maxExtent - 80) {
        _scrollController.jumpTo(maxExtent);
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_isWelcome) {
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
            JobAvatar(
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
                      conversation.name,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'report') {
                final l10n = AppLocalizations.of(context)!;
                final result = await showReportDialog(
                  context,
                  title: l10n.report,
                );
                if (result != null && context.mounted) {
                  showAppSuccessToast(context, l10n.conversationReported);
                }
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
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  enabled: onSend != null,
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
