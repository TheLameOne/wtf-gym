import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Requests')),
      body: StreamBuilder<List<CallRequestModel>>(
        stream: CallRequestService.instance
            .trainerRequestsStream(AppConstants.trainerAaravId),
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
              icon: Icons.pending_actions,
              title: 'No requests',
              subtitle: 'Member call requests will appear here',
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

class _RequestCard extends StatefulWidget {
  final CallRequestModel request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isApproving = false;
  bool _isDeclining = false;

  Future<void> _approve() async {
    setState(() => _isApproving = true);
    try {
      await CallRequestService.instance.approveRequest(widget.request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _showDeclineDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Decline', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isDeclining = true);
      try {
        await CallRequestService.instance.declineRequest(
          widget.request.id,
          reasonController.text.trim().isEmpty
              ? 'No reason provided'
              : reasonController.text.trim(),
        );
      } finally {
        if (mounted) setState(() => _isDeclining = false);
      }
    }
  }

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
    final req = widget.request;
    final color = _statusColor(req.status);

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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.trainerPrimary.withOpacity(0.1),
                  child: Text(
                    req.memberName[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.trainerPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.memberName, style: AppTextStyles.label),
                      Text(req.scheduledFor.toFullLabel(),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.grey600)),
                    ],
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
                    req.status.toUpperCase(),
                    style: AppTextStyles.caption
                        .copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (req.note != null && req.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(req.note!,
                  style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
            ],
            if (req.isPending) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDeclining ? null : _showDeclineDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: _isDeclining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isApproving ? null : _approve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                      ),
                      child: _isApproving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.white))
                          : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (req.isJoinable) ...[
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () => context.push('/pre-join/${req.id}'),
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
