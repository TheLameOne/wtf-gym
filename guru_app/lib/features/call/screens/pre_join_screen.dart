import 'package:flutter/material.dart';
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

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _join() async {
    setState(() => _isJoining = true);
    try {
      final roomMeta = await CallRequestService.instance
          .getRoomMetaForRequest(widget.callRequestId);
      if (roomMeta == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room not ready yet. Please wait.')),
          );
        }
        return;
      }
      final token = await HMSService.instance.fetchAuthToken(
        userId: AppConstants.memberDkId,
        role: roomMeta.hmsRoleMember,
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
        userName: 'DK',
        authToken: token,
      );
      if (!_micEnabled) await HMSService.instance.toggleMic();
      if (!_camEnabled) await HMSService.instance.toggleCamera();
      if (mounted) context.push('/call/${widget.callRequestId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(24),
              ),
              child:
                  const Icon(Icons.person, size: 80, color: AppColors.grey400),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Toggle(
                  icon: _micEnabled ? Icons.mic : Icons.mic_off,
                  label: 'Mic',
                  enabled: _micEnabled,
                  onTap: () => setState(() => _micEnabled = !_micEnabled),
                ),
                const SizedBox(width: AppSpacing.xl),
                _Toggle(
                  icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
                  label: 'Camera',
                  enabled: _camEnabled,
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
  final VoidCallback onTap;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.enabled,
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
                  ? AppColors.guruPrimary.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: enabled ? AppColors.guruPrimary : AppColors.error),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
