import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/message_model.dart';
import '../utils/app_theme.dart';
import 'status_ticks.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isFromMe;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) return _buildSystemMessage(context);

    final bgColor = isFromMe ? AppColors.memberBubble : AppColors.trainerBubble;
    final textColor = AppColors.grey900;
    final align = isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isFromMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(color: bgColor, borderRadius: radius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message.text,
                    style: AppTextStyles.body.copyWith(color: textColor)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey600),
                    ),
                    if (isFromMe) ...[
                      const SizedBox(width: 3),
                      StatusTicks(status: message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: isFromMe ? 0.2 : -0.2,
          duration: 200.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 150.ms);
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
