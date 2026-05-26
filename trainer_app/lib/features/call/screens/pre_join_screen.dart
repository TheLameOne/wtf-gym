import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared/shared.dart';

class PreJoinScreen extends ConsumerStatefulWidget {
  final String callRequestId;
  const PreJoinScreen({super.key, required this.callRequestId});

  @override
  ConsumerState<PreJoinScreen> createState() => _PreJoinScreenState();
}

class _PreJoinScreenState extends ConsumerState<PreJoinScreen> {
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    [Permission.camera, Permission.microphone].request();
  }

  Future<void> _join() async {
    setState(() => _isJoining = true);
    try {
      final roomMeta = await CallRequestService.instance
          .getRoomMetaForRequest(widget.callRequestId);
      if (roomMeta == null ||
          roomMeta.hmsRoomId.startsWith('room_') ||
          roomMeta.hmsRoomId.startsWith('local_')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Room not ready. Ask trainer to re-approve the request.')),
          );
        }
        return;
      }
      final token = await HMSService.instance.fetchAuthToken(
        userId: AppConstants.trainerAaravId,
        role: roomMeta.hmsRoleTrainer,
        roomId: roomMeta.hmsRoomId,
      );
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get call token.')),
          );
        }
        return;
      }
      await HMSService.instance.build();
      await HMSService.instance.join(
        userName: 'Aarav',
        authToken: token,
      );
      if (!_micEnabled) await HMSService.instance.toggleMic();
      if (!_camEnabled) await HMSService.instance.toggleCamera();
      if (mounted) context.push('/call/${widget.callRequestId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          action: SnackBarAction(
            label: 'Copy error',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: 'Error: $e')),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ready to Join?')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Ready to join? Check mic and camera.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.trainerPrimary.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.trainerPrimary.withOpacity(0.4)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.videocam, size: 56, color: Colors.white30),
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Aarav',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  if (!_camEnabled)
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(Icons.videocam_off,
                            size: 48, color: Colors.white54),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Toggle(
                  icon: _micEnabled ? Icons.mic : Icons.mic_off,
                  label: 'Mic',
                  enabled: _micEnabled,
                  color: AppColors.trainerPrimary,
                  onTap: () => setState(() => _micEnabled = !_micEnabled),
                ),
                const SizedBox(width: AppSpacing.xl),
                _Toggle(
                  icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
                  label: 'Camera',
                  enabled: _camEnabled,
                  color: AppColors.trainerPrimary,
                  onTap: () => setState(() => _camEnabled = !_camEnabled),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            CtaButton(
              label: 'Join Call',
              onPressed: _join,
              isLoading: _isJoining,
              icon: Icons.video_call,
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: enabled
                  ? color.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: enabled ? color : AppColors.error),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
