import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Members')),
      body: FutureBuilder<List<UserModel>>(
        future: UserService.instance
            .getMembersForTrainer(AppConstants.trainerAaravId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(message: snapshot.error.toString());
          }
          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'No members yet',
              subtitle: 'Members assigned to you will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: members.length,
            itemBuilder: (_, i) => _MemberCard(member: members[i]),
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final chatId = ChatService.chatId(member.id, AppConstants.trainerAaravId);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.trainerPrimary.withOpacity(0.1),
          child: Text(
            member.name[0].toUpperCase(),
            style: const TextStyle(
                color: AppColors.trainerPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(member.name, style: AppTextStyles.label),
        subtitle: Text(member.email,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.push('/chat/$chatId'),
              color: AppColors.trainerPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
