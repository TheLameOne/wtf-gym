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
              primary: AppColors.guruPrimary, isDark: isDark),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroSection(isDark: isDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    child: Column(
                      children: [
                        _HomeCard(
                          icon: Icons.chat_bubble_rounded,
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
                          color: AppColors.brand,
                          onTap: () => context.push('/sessions'),
                          index: 2,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _HomeCard(
                          icon: Icons.pending_actions_rounded,
                          title: 'My Requests',
                          subtitle: 'Check call request status',
                          color: AppColors.warning,
                          onTap: () => context.push('/requests'),
                          index: 3,
                        ),
                      ],
                    ),
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
      height: 240,
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

class _HeroSection extends StatelessWidget {
  final bool isDark;

  const _HeroSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hey DK! 💪',
            style: AppTextStyles.h1.copyWith(fontSize: 34),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.2, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'What would you like to do today?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      shadowColor: color.withOpacity(0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.08),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child:
                              Icon(icon, color: AppColors.white, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.h3),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: AppTextStyles.body.copyWith(
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 100 * index), duration: 350.ms)
        .slideX(begin: 0.12, duration: 350.ms, curve: Curves.easeOut);
  }
}
