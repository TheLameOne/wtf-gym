import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBarBadge(
        title: 'Trainer App',
        roleLabel: 'Trainer • Aarav',
        roleColor: AppColors.trainerPrimary,
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
                  Text('Welcome, Aarav! 💪', style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Manage your members and sessions',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.grey600)),
                  const SizedBox(height: AppSpacing.xl),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _GridTile(
                        icon: Icons.people_outline,
                        title: 'Members',
                        color: AppColors.trainerPrimary,
                        onTap: () => context.push('/members'),
                        index: 0,
                      ),
                      _GridTile(
                        icon: Icons.chat_bubble_outline,
                        title: 'Messages',
                        color: AppColors.guruPrimary,
                        onTap: () => context.push('/chat'),
                        index: 1,
                      ),
                      _GridTile(
                        icon: Icons.pending_actions,
                        title: 'Requests',
                        color: AppColors.warning,
                        onTap: () => context.push('/requests'),
                        index: 2,
                      ),
                      _GridTile(
                        icon: Icons.history,
                        title: 'Sessions',
                        color: AppColors.success,
                        onTap: () => context.push('/sessions'),
                        index: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const _DevPanelFloat(),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final int index;

  const _GridTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTextStyles.label),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 80 * index))
          .slideY(begin: 0.15),
    );
  }
}

class _DevPanelFloat extends StatelessWidget {
  const _DevPanelFloat();

  @override
  Widget build(BuildContext context) => const DevPanel(appName: 'WTF Trainer');
}
