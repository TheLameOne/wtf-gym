import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  int _filterIndex = 0;

  static const _filters = ['All', 'Last 7 Days', 'This Month'];

  bool _matchesFilter(SessionLogModel log) {
    final now = DateTime.now();
    switch (_filterIndex) {
      case 1:
        return log.startedAt.isAfter(now.subtract(const Duration(days: 7)));
      case 2:
        return log.startedAt.year == now.year &&
            log.startedAt.month == now.month;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Sessions')),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _filters.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(_filters[i]),
                      selected: _filterIndex == i,
                      onSelected: (_) => setState(() => _filterIndex = i),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SessionLogModel>>(
              stream: SessionLogService.instance
                  .memberLogsStream(AppConstants.memberDkId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorStateWidget(message: snapshot.error.toString());
                }
                final logs =
                    (snapshot.data ?? []).where(_matchesFilter).toList();
                if (logs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.history_toggle_off,
                    title: 'No sessions',
                    subtitle: 'Your completed sessions will appear here',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: logs.length,
                  itemBuilder: (_, i) => _SessionCard(log: logs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionLogModel log;
  const _SessionCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final stars = log.rating ?? 0;
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
                const Icon(Icons.fitness_center,
                    size: 18, color: AppColors.guruPrimary),
                const SizedBox(width: AppSpacing.xs),
                Text(log.startedAt.toFullLabel(), style: AppTextStyles.label),
                const Spacer(),
                Text(log.durationSec.toSessionDuration(),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey600)),
              ],
            ),
            if (stars > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
            if (log.trainerNotes != null && log.trainerNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Trainer: ${log.trainerNotes}',
                  style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
            ],
          ],
        ),
      ),
    );
  }
}
