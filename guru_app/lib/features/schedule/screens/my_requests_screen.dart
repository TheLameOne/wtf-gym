import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: StreamBuilder<List<CallRequestModel>>(
        stream: CallRequestService.instance
            .memberRequestsStream(AppConstants.memberDkId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(message: snapshot.error.toString());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.calendar_today,
              title: 'No requests yet',
              subtitle: 'Schedule a call from the home screen',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: requests.length,
            itemBuilder: (_, i) => _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CallRequestModel request;
  const _RequestCard({required this.request});

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      case 'cancelled':
        return AppColors.grey400;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(request.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.scheduledFor.toFullLabel(),
                    style: AppTextStyles.label,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: AppTextStyles.caption
                        .copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(request.note!,
                  style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
            ],
            if (request.declineReason != null &&
                request.declineReason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Reason: ${request.declineReason}',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.error)),
            ],
            if (request.isApproved) ...[
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () => context.push('/pre-join/${request.id}'),
                icon: const Icon(Icons.video_call, size: 18),
                label: const Text('Join Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
