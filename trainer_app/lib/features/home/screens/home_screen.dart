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
            icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () =>
                ref.read(themeNotifierProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _GradientBackground(
              primary: AppColors.trainerPrimary, isDark: isDark),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Aarav! 💪',
                      style: AppTextStyles.h1.copyWith(fontSize: 34),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(
                            begin: -0.2,
                            duration: 400.ms,
                            curve: Curves.easeOut),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage your members and sessions',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: AppSpacing.xl),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.05,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _GridTile(
                          icon: Icons.people_rounded,
                          title: 'Members',
                          color: AppColors.trainerPrimary,
                          onTap: () => context.push('/members'),
                          index: 0,
                        ),
                        _GridTile(
                          icon: Icons.chat_bubble_rounded,
                          title: 'Messages',
                          color: AppColors.guruPrimary,
                          onTap: () => context.push('/chat'),
                          index: 1,
                        ),
                        _GridTile(
                          icon: Icons.pending_actions_rounded,
                          title: 'Requests',
                          color: AppColors.warning,
                          onTap: () => context.push('/requests'),
                          index: 2,
                        ),
                        _GridTile(
                          icon: Icons.history_rounded,
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
          ),
          const _DevPanelFloat(),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  final Color primary;
  final bool isDark;

  const _GradientBackground({required this.primary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 260,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [primary.withOpacity(0.22), AppColors.darkBg]
                : [primary.withOpacity(0.10), AppColors.white],
          ),
        ),
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
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.white.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 80 * index), duration: 300.ms)
        .scale(
            begin: const Offset(0.88, 0.88),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.easeOut);
  }
}

class _DevPanelFloat extends StatelessWidget {
  const _DevPanelFloat();

  @override
  Widget build(BuildContext context) => const DevPanel(appName: 'WTF Trainer');
}
