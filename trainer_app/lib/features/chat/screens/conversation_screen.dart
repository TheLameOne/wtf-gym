import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const _myId = AppConstants.trainerAaravId;
  static const _otherUserId = AppConstants.memberDkId;

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
      appBar: AppBar(title: const Text('DK')),
      body: Column(
        children: [
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
                    itemBuilder: (_, i) => MessageBubble(
                      message: messages[i],
                      isFromMe: messages[i].senderId == _myId,
                    ),
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
          _InputBar(
            controller: _controller,
            isSending: _isSending,
            onChanged: (v) {
              ChatService.instance
                  .setTyping(widget.chatId, _myId, v.isNotEmpty);
            },
            onSend: () => _sendMessage(_controller.text),
            accentColor: AppColors.trainerPrimary,
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
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(AppConstants.quickReplies[i]),
          child: Container(
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.trainerPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.trainerPrimary.withOpacity(0.3)),
            ),
            child: Text(
              AppConstants.quickReplies[i],
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.trainerPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final Color accentColor;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
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
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: accentColor,
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }
}
