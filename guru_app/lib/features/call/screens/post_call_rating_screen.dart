import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class PostCallRatingScreen extends StatefulWidget {
  final String sessionLogId;
  const PostCallRatingScreen({super.key, required this.sessionLogId});

  @override
  State<PostCallRatingScreen> createState() => _PostCallRatingScreenState();
}

class _PostCallRatingScreenState extends State<PostCallRatingScreen> {
  int _stars = 0;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved to your logs.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await SessionLogService.instance.updateRating(
        widget.sessionLogId,
        _stars,
        _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for the feedback!')),
        );
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Session')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Icon(Icons.check_circle, size: 80, color: AppColors.success)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text('Session Complete!', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.xs),
            Text('How was your session with Aarav?',
                style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _stars = i + 1),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Icon(
                      i < _stars ? Icons.star : Icons.star_border,
                      size: 44,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Optional note (e.g. loved the session!)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            CtaButton(
              label: 'Done',
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Skip'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
