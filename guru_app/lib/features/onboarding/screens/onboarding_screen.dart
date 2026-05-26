import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
      icon: Icons.fitness_center,
      title: 'Train Smarter',
      subtitle:
          'Connect directly with your personal trainer for real-time guidance and support.',
      color: AppColors.guruPrimary,
    ),
    _Slide(
      icon: Icons.video_call_rounded,
      title: 'Video Sessions',
      subtitle:
          'Schedule and join HD video sessions with your trainer from anywhere.',
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            _PageIndicator(current: _page, total: _slides.length),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CtaButton(
                label: _page == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    context.go('/create-profile');
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppTextStyles.h1, textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: AppSpacing.md),
          Text(subtitle,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.grey600),
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _PageIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: i == current ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == current ? AppColors.guruPrimary : AppColors.grey400,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
