import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/offline_queue_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';
import '../utils/app_theme.dart';

class DevPanel extends StatefulWidget {
  final String appName;
  const DevPanel({super.key, this.appName = 'WTF Gym'});

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  bool _isOpen = false;

  String _maskUrl(String url) {
    // Replace port digits with ****
    return url.replaceAll(RegExp(r':\d+$'), ':****');
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
            'Deletes all chats, messages, call requests, room metas, '
            'session logs, and the local offline queue.\n\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final db = FirebaseFirestore.instance;

      // Delete chats + subcollections first
      final chats = await db.collection('chats').get();
      for (final chat in chats.docs) {
        final messages = await chat.reference.collection('messages').get();
        for (final m in messages.docs) {
          await m.reference.delete();
        }
        final typing = await chat.reference.collection('typing').get();
        for (final t in typing.docs) {
          await t.reference.delete();
        }
        await chat.reference.delete();
      }

      // Top-level collections
      for (final col in ['call_requests', 'room_metas', 'session_logs']) {
        final snap = await db.collection(col).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }

      // Local Hive queue
      await OfflineQueueService.instance.clearAll();

      AppLogger.info('DevPanel');
      if (mounted) {
        setState(() => _isOpen = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared.')),
        );
      }
    } catch (e) {
      AppLogger.error('DevPanel', 'Reset failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isOpen) _buildPanel(),
        Positioned(
          right: 8,
          bottom: 80,
          child: GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.grey900.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.more_vert, color: AppColors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    final logs = AppLogger.recentLogs;
    final maskedServer = _maskUrl(AppConstants.tokenServerUrl);
    return Positioned(
      right: 8,
      bottom: 128,
      child: Container(
        width: 300,
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.grey900.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DevPanel',
                      style:
                          AppTextStyles.label.copyWith(color: AppColors.white)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: logs.join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied')),
                      );
                    },
                    child: const Icon(Icons.copy,
                        color: AppColors.grey400, size: 16),
                  ),
                ],
              ),
            ),
            // Build info
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              child: Text(
                'App: ${widget.appName} v1.0.0',
                style: const TextStyle(
                    color: AppColors.grey400,
                    fontSize: 10,
                    fontFamily: 'monospace'),
              ),
            ),
            // Env vars (masked)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              child: Text(
                'token_server: $maskedServer',
                style: const TextStyle(
                    color: AppColors.grey400,
                    fontSize: 10,
                    fontFamily: 'monospace'),
              ),
            ),
            const Divider(color: AppColors.grey600, height: 8),
            // Reset button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                height: 28,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Colors.redAccent)),
                  ),
                  onPressed: _resetData,
                  child: const Text('Reset all data',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
            ),
            const Divider(color: AppColors.grey600, height: 8),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Text('No logs yet',
                          style: TextStyle(color: AppColors.grey400)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: logs.length,
                      reverse: true,
                      itemBuilder: (_, i) => Text(
                        logs[logs.length - 1 - i],
                        style: const TextStyle(
                            color: AppColors.grey200,
                            fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
