import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppBarBadge extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String roleLabel;
  final Color roleColor;
  final List<Widget>? actions;

  const AppBarBadge({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.roleColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              roleLabel,
              style: AppTextStyles.caption
                  .copyWith(color: roleColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
