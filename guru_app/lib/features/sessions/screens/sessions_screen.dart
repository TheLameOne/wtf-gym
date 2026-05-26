import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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
                  return EmptyStateWidget(
                    icon: Icons.history_toggle_off,
                    title: 'No sessions yet',
                    subtitle: 'Your completed sessions will appear here',
                    ctaLabel: 'Schedule your first call',
                    onCta: () => context.go('/schedule'),
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

// ─── Detail modal ────────────────────────────────────────────────────────────

void _showDetailModal(BuildContext context, SessionLogModel log) {
  final shareText = _buildShareText(log);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.fitness_center,
                  size: 20, color: AppColors.guruPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text('Session Details', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Share',
                onPressed: () => Share.share(shareText,
                    subject: 'WTF Gym — Session Summary'),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _DetailRow(
              label: 'Date', value: log.startedAt.toFullLabel()),
          _DetailRow(
              label: 'Duration',
              value: log.durationSec.toSessionDuration()),
          if ((log.rating ?? 0) > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('Rating',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey600)),
                ),
                ...List.generate(
                    5,
                    (i) => Icon(
                          i < log.rating! ? Icons.star : Icons.star_border,
                          size: 18,
                          color: AppColors.warning,
                        )),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Your note', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            log.memberNotes?.isNotEmpty == true
                ? log.memberNotes!
                : 'No note added',
            style: AppTextStyles.body.copyWith(
              color: log.memberNotes?.isNotEmpty == true
                  ? AppColors.grey800
                  : AppColors.grey400,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Trainer\'s notes', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            log.trainerNotes?.isNotEmpty == true
                ? log.trainerNotes!
                : 'No notes from trainer yet',
            style: AppTextStyles.body.copyWith(
              color: log.trainerNotes?.isNotEmpty == true
                  ? AppColors.grey800
                  : AppColors.grey400,
            ),
          ),
        ],
      ),
    ),
  );
}

String _buildShareText(SessionLogModel log) {
  final buf = StringBuffer()
    ..writeln('WTF Gym — Session Summary')
    ..writeln('Date: ${log.startedAt.toFullLabel()}')
    ..writeln('Duration: ${log.durationSec.toSessionDuration()}');
  if (log.rating != null && log.rating! > 0) {
    buf.writeln(
        'Rating: ${'★' * log.rating!}${'☆' * (5 - log.rating!)}');
  }
  if (log.memberNotes?.isNotEmpty == true) {
    buf.writeln('My notes: ${log.memberNotes}');
  }
  if (log.trainerNotes?.isNotEmpty == true) {
    buf.writeln('Trainer notes: ${log.trainerNotes}');
  }
  return buf.toString().trim();
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.grey600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final SessionLogModel log;
  const _SessionCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final stars = log.rating ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailModal(context, log),
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
                  Expanded(
                    child: Text(log.startedAt.toFullLabel(),
                        style: AppTextStyles.label),
                  ),
                  Text(log.durationSec.toSessionDuration(),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey600)),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.grey400),
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
              if (log.trainerNotes != null &&
                  log.trainerNotes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Trainer: ${log.trainerNotes}',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
