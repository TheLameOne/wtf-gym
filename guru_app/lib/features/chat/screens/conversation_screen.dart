import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ConversationScreen({super.key, required this.chatId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _simulatingTyping = false;
  int _messageLimit = 50;
  static const _myId = AppConstants.memberDkId;
  static const _otherUserId = AppConstants.trainerAaravId;

  @override
  void initState() {
    super.initState();
    ChatService.instance.markAsRead(widget.chatId, _myId, _otherUserId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    ChatService.instance.setTyping(widget.chatId, _myId, false);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    setState(() => _isSending = true);
    ChatService.instance.setTyping(widget.chatId, _myId, false);
    try {
      await ChatService.instance.sendMessage(
        senderId: _myId,
        receiverId: _otherUserId,
        text: msg,
      );
      _scrollToBottom();
      // Simulate the other side typing for 400–800 ms
      final delay = 400 + Random().nextInt(401);
      setState(() => _simulatingTyping = true);
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) setState(() => _simulatingTyping = false);
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aarav'),
        actions: [
          StreamBuilder<List<CallRequestModel>>(
            stream: CallRequestService.instance
                .memberRequestsStream(AppConstants.memberDkId),
            builder: (context, snap) {
              final joinable =
                  (snap.data ?? []).where((r) => r.isJoinable).toList();
              if (joinable.isEmpty) return const SizedBox.shrink();
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.video_call),
                    tooltip: 'Join upcoming call',
                    onPressed: () =>
                        context.push('/pre-join/${joinable.first.id}'),
                  ),
                  Positioned(
                    right: 8,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: ChatService.instance.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allMessages = snapshot.data ?? [];
                // Paginate: show last _messageLimit messages; pull to load more
                final messages = allMessages.length > _messageLimit
                    ? allMessages.sublist(allMessages.length - _messageLimit)
                    : allMessages;
                ChatService.instance
                    .markAsRead(widget.chatId, _myId, _otherUserId);
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No messages yet. Start the conversation.',
                        style: TextStyle(color: AppColors.grey400),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _messageLimit += 50);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      return MessageBubble(
                        message: messages[i],
                        isFromMe: messages[i].senderId == _myId,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Typing indicator (real + simulated)
          StreamBuilder<bool>(
            stream:
                ChatService.instance.typingStream(widget.chatId, _otherUserId),
            builder: (_, snap) {
              if (snap.data == true || _simulatingTyping) {
                return const Padding(
                  padding: EdgeInsets.only(
                      left: AppSpacing.md, bottom: AppSpacing.xs),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicator(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Quick replies
          _QuickReplies(onTap: _sendMessage),
          // Input bar
          _InputBar(
            controller: _controller,
            isSending: _isSending,
            onChanged: (v) {
              ChatService.instance
                  .setTyping(widget.chatId, _myId, v.isNotEmpty);
            },
            onSend: () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickReplies({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.quickReplies.length,
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => onTap(AppConstants.quickReplies[i]),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.guruPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppColors.guruPrimary.withOpacity(0.3)),
              ),
              child: Text(
                AppConstants.quickReplies[i],
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.guruPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                filled: true,
                fillColor: AppColors.grey100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.guruPrimary,
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }
}
