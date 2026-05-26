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
      appBar: AppBar(title: const Text('Sessions')),
      body: Column(
        children: [
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
                  .trainerLogsStream(AppConstants.trainerAaravId),
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
                    subtitle: 'Completed sessions will appear here',
                    ctaLabel: 'Schedule your first call',
                    onCta: () => context.go('/requests'),
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

// ─── Detail modal ─────────────────────────────────────────────────────────────

void _showDetailModal(BuildContext context, SessionLogModel log,
    {required VoidCallback onEditNotes}) {
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
                  size: 20, color: AppColors.trainerPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text('Session Details', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Edit notes',
                color: AppColors.trainerPrimary,
                onPressed: () {
                  Navigator.of(context).pop();
                  onEditNotes();
                },
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Share',
                onPressed: () => Share.share(shareText,
                    subject: 'WTF Gym — Session Summary'),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _DetailRow(label: 'Member', value: log.memberName),
          _DetailRow(label: 'Date', value: log.startedAt.toFullLabel()),
          _DetailRow(
              label: 'Duration', value: log.durationSec.toSessionDuration()),
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
          Text('Member\'s note', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            log.memberNotes?.isNotEmpty == true
                ? log.memberNotes!
                : 'No note added by member',
            style: AppTextStyles.body.copyWith(
              color: log.memberNotes?.isNotEmpty == true
                  ? AppColors.grey800
                  : AppColors.grey400,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Your notes', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            log.trainerNotes?.isNotEmpty == true
                ? log.trainerNotes!
                : 'No notes added yet',
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
    ..writeln('Member: ${log.memberName}')
    ..writeln('Date: ${log.startedAt.toFullLabel()}')
    ..writeln('Duration: ${log.durationSec.toSessionDuration()}');
  if (log.rating != null && log.rating! > 0) {
    buf.writeln('Rating: ${'★' * log.rating!}${'☆' * (5 - log.rating!)}');
  }
  if (log.memberNotes?.isNotEmpty == true) {
    buf.writeln('Member notes: ${log.memberNotes}');
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
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.grey600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  final SessionLogModel log;
  const _SessionCard({required this.log});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _editingNotes = false;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.log.trainerNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    try {
      await SessionLogService.instance
          .updateTrainerNotes(widget.log.id, _notesController.text.trim());
      if (mounted) setState(() => _editingNotes = false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _editingNotes
            ? null
            : () => _showDetailModal(context, log,
                onEditNotes: () => setState(() => _editingNotes = true)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.trainerPrimary.withOpacity(0.1),
                    child: Text(
                      log.memberName.isNotEmpty
                          ? log.memberName[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                          color: AppColors.trainerPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.memberName, style: AppTextStyles.label),
                        Text(log.startedAt.toFullLabel(),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey600)),
                      ],
                    ),
                  ),
                  Text(log.durationSec.toSessionDuration(),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey600)),
                  const SizedBox(width: AppSpacing.xs),
                  if (!_editingNotes)
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.grey400),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_editingNotes)
                Column(
                  children: [
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add trainer notes…',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _editingNotes = false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveNotes,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.trainerNotes?.isNotEmpty == true
                            ? log.trainerNotes!
                            : 'No notes yet',
                        style: AppTextStyles.body.copyWith(
                            color: log.trainerNotes?.isNotEmpty == true
                                ? AppColors.grey800
                                : AppColors.grey400),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 20),
                      onPressed: () => setState(() => _editingNotes = true),
                      color: AppColors.trainerPrimary,
                    ),
                  ],
                ),
              if (log.rating != null && log.rating! > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < log.rating! ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
