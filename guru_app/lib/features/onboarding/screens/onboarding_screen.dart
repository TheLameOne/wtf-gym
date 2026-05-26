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

  static const _slides = [
    _SlideData(
      icon: Icons.fitness_center_rounded,
      title: 'Train Smarter',
      subtitle:
          'Connect directly with your personal trainer for real-time guidance and support.',
      color: AppColors.guruPrimary,
    ),
    _SlideData(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background that shifts with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        _slides[_page].color.withOpacity(0.28),
                        AppColors.darkBg,
                      ]
                    : [
                        _slides[_page].color.withOpacity(0.08),
                        AppColors.white,
                      ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _SlidePage(data: _slides[i]),
                  ),
                ),
                _PageIndicator(
                  current: _page,
                  total: _slides.length,
                  activeColor: _slides[_page].color,
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: CtaButton(
                    label:
                        _page == _slides.length - 1 ? 'Get Started' : 'Next',
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
        ],
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _SlidePage extends StatelessWidget {
  final _SlideData data;

  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(data.icon, size: 76, color: AppColors.white),
          )
              .animate()
              .scale(
                duration: 500.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.65, 0.65),
              )
              .fadeIn(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            data.title,
            style: AppTextStyles.h1.copyWith(fontSize: 36),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, delay: 200.ms),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.grey600,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int current;
  final int total;
  final Color activeColor;

  const _PageIndicator({
    required this.current,
    required this.total,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: i == current ? 32 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == current ? activeColor : AppColors.grey400,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}


