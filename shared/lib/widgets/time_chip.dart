import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDisabled;

  const TimeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : isDisabled
                  ? AppColors.grey200
                  : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : AppColors.grey200,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected
                ? AppColors.white
                : isDisabled
                    ? AppColors.grey400
                    : AppColors.grey800,
          ),
        ),
      ),
    );
  }
}
