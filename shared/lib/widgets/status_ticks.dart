import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusTicks extends StatelessWidget {
  final String status;
  const StatusTicks({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'read':
        return Icon(Icons.done_all, size: 14, color: AppColors.guruPrimary);
      case 'sent':
        return Icon(Icons.done_all, size: 14, color: AppColors.grey600);
      default:
        return Icon(Icons.check, size: 14, color: AppColors.grey400);
    }
  }
}
