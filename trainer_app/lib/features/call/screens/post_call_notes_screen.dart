import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class PostCallNotesScreen extends StatefulWidget {
  final String sessionLogId;
  const PostCallNotesScreen({super.key, required this.sessionLogId});

  @override
  State<PostCallNotesScreen> createState() => _PostCallNotesScreenState();
}

class _PostCallNotesScreenState extends State<PostCallNotesScreen> {
  final _notesController = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final notes = _notesController.text.trim();
      if (notes.isNotEmpty) {
        await SessionLogService.instance
            .updateTrainerNotes(widget.sessionLogId, notes);
      }
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Notes')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text('Session Ended', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.xs),
            Text("Add notes for this member's session",
                style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppSpacing.xl),
            const Text('Trainer Notes', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'e.g. Great progress on squats. Focus on form.',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            CtaButton(
              label: 'Save & Finish',
              onPressed: _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSpacing.sm),
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
