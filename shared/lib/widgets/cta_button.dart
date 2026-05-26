import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CtaStyle style;
  final IconData? icon;

  const CtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.style = CtaStyle.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    switch (style) {
      case CtaStyle.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _child(AppColors.white),
        )
            .animate(target: isLoading ? 1 : 0)
            .scaleXY(begin: 1, end: 0.97, duration: 100.ms);
      case CtaStyle.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primary),
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _child(primary),
        );
      case CtaStyle.tertiary:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _child(primary),
        );
    }
  }

  Widget _child(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}

enum CtaStyle { primary, secondary, tertiary }
