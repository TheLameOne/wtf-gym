import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
