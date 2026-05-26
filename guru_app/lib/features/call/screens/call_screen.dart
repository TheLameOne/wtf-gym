import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:shared/shared.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String callRequestId;
  const CallScreen({super.key, required this.callRequestId});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final _hms = HMSService.instance;

  @override
  void initState() {
    super.initState();
    _hms.onStateChanged = _onStateChanged;
    _hms.onPeersChanged = _onPeersChanged;
    _hms.onError = _onError;
    // Timeout: if still connecting after 20s, bail out
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _hms.state == HMSCallState.connecting) {
        _onError('Connection timed out. Check your network or re-join.');
        _hms.destroy();
        _navigatePostCall();
      }
    });
  }

  void _onStateChanged(HMSCallState state) {
    if (state == HMSCallState.ended || state == HMSCallState.error) {
      _navigatePostCall();
    } else {
      setState(() {});
    }
  }

  void _onPeersChanged(List<HMSPeer> peers) => setState(() {});
  void _onError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Call error: $msg')));
    }
  }

  Future<void> _navigatePostCall() async {
    // Create session log
    final logId = await SessionLogService.instance.createLog(
      memberId: AppConstants.memberDkId,
      trainerId: AppConstants.trainerAaravId,
      startedAt: _hms.callStartTime ?? DateTime.now(),
      endedAt: DateTime.now(),
      callRequestId: widget.callRequestId,
      memberName: 'DK',
      trainerName: 'Aarav',
    );
    if (mounted) context.go('/post-call/$logId');
  }

  @override
  void dispose() {
    _hms.onStateChanged = null;
    _hms.onPeersChanged = null;
    _hms.onError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _hms.state;

    if (state == HMSCallState.connecting ||
        state == HMSCallState.reconnecting) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: AppSpacing.md),
              Text(
                state == HMSCallState.reconnecting
                    ? 'Reconnecting…'
                    : 'Connecting…',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video
            if (_hms.remoteVideoTracks.isNotEmpty)
              ..._hms.remoteVideoTracks.values.map(
                (track) => HMSVideoView(
                  track: track,
                  setMirror: false,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 80, color: Colors.white54),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Waiting for trainer…',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            // Local video pip
            if (_hms.localVideoTrack != null)
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  width: 100,
                  height: 140,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: HMSVideoView(
                    track: _hms.localVideoTrack!,
                    setMirror: true,
                  ),
                ),
              ),
            // Controls
            Positioned(
              bottom: AppSpacing.xl,
              left: 0,
              right: 0,
              child: _CallControls(
                  hms: _hms,
                  onLeave: () async {
                    await _hms.leave();
                    await _navigatePostCall();
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControls extends StatefulWidget {
  final HMSService hms;
  final Future<void> Function() onLeave;

  const _CallControls({required this.hms, required this.onLeave});

  @override
  State<_CallControls> createState() => _CallControlsState();
}

class _CallControlsState extends State<_CallControls> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlBtn(
          icon: widget.hms.isMicMuted ? Icons.mic_off : Icons.mic,
          onTap: () async {
            await widget.hms.toggleMic();
            setState(() {});
          },
        ),
        const SizedBox(width: AppSpacing.md),
        _ControlBtn(
          icon: widget.hms.isCameraMuted ? Icons.videocam_off : Icons.videocam,
          onTap: () async {
            await widget.hms.toggleCamera();
            setState(() {});
          },
        ),
        const SizedBox(width: AppSpacing.md),
        _ControlBtn(
          icon: Icons.flip_camera_ios,
          onTap: () async {
            await widget.hms.switchCamera();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        _ControlBtn(
          icon: Icons.call_end,
          color: AppColors.error,
          onTap: widget.onLeave,
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;

  const _ControlBtn({
    required this.icon,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
