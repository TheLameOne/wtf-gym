import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const userId = AppConstants.memberDkId;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<ChatMeta>>(
        stream: ChatService.instance.chatListStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(message: snapshot.error.toString());
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No chats yet',
              subtitle: 'Start a conversation with your trainer',
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final meta = chats[i];
              final unread = meta.unreadFor(userId);
              final other =
                  userId == meta.memberId ? meta.trainerName : meta.memberName;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.guruPrimary.withOpacity(0.15),
                  child: Text(
                    other.isNotEmpty ? other[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.guruPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(other, style: AppTextStyles.label),
                subtitle: Text(
                  meta.lastMessage ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(color: AppColors.grey600),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (meta.lastMessageAt != null)
                      Text(
                        timeago.format(meta.lastMessageAt!),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400),
                      ),
                    const SizedBox(height: 4),
                    if (unread > 0)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.guruPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () => context.push('/chat/${meta.chatId}'),
              );
            },
          );
        },
      ),
    );
  }
}
