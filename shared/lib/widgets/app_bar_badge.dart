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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(height: 2),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              roleLabel.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [roleColor, roleColor.withOpacity(0.3)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 3);
}
