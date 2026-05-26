import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../widgets/dev_panel_overlay.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBarBadge(
        title: 'Guru App',
        roleLabel: 'Member • DK',
        roleColor: AppColors.guruPrimary,
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => ref.read(themeNotifierProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text('Hey DK! 👋', style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.xs),
                  Text('What would you like to do today?',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.grey600)),
                  const SizedBox(height: AppSpacing.xl),
                  _HomeCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat with Trainer',
                    subtitle: 'Message Aarav anytime',
                    color: AppColors.guruPrimary,
                    onTap: () => context.push(
                        '/chat/${ChatService.chatId(AppConstants.memberDkId, AppConstants.trainerAaravId)}'),
                    index: 0,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HomeCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Schedule Call',
                    subtitle: 'Book a video session',
                    color: AppColors.success,
                    onTap: () => context.push('/schedule'),
                    index: 1,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HomeCard(
                    icon: Icons.history_rounded,
                    title: 'My Sessions',
                    subtitle: 'View past sessions',
                    color: AppColors.warning,
                    onTap: () => context.push('/sessions'),
                    index: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HomeCard(
                    icon: Icons.pending_actions_rounded,
                    title: 'My Requests',
                    subtitle: 'Check call request status',
                    color: AppColors.guruPrimary,
                    onTap: () => context.push('/requests'),
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
          const DevPanelOverlay(),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int index;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.grey600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.grey400),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.15);
  }
}
