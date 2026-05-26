import 'dart:convert';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

enum HMSCallState { idle, connecting, connected, reconnecting, ended, error }

class HMSService implements HMSUpdateListener, HMSActionResultListener {
  HMSService._();
  static final HMSService instance = HMSService._();

  late HMSSDK _hmsSDK;
  bool _isBuilt = false;

  HMSCallState state = HMSCallState.idle;

  HMSPeer? localPeer;
  final List<HMSPeer> peers = [];
  HMSVideoTrack? localVideoTrack;
  final Map<String, HMSVideoTrack> remoteVideoTracks = {};

  bool isMicMuted = false;
  bool isCameraMuted = false;

  // Callbacks
  void Function(HMSCallState)? onStateChanged;
  void Function(List<HMSPeer>)? onPeersChanged;
  void Function(String)? onError;

  DateTime? _callStartTime;

  Future<void> build() async {
    if (_isBuilt) return;
    _hmsSDK = HMSSDK();
    await _hmsSDK.build();
    _hmsSDK.addUpdateListener(listener: this);
    _isBuilt = true;
    AppLogger.rtc('HMSSDK built');
  }

  Future<String?> fetchAuthToken({
    required String userId,
    required String role,
    required String roomId,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.tokenServerUrl).replace(
        path: '/token',
        queryParameters: {'userId': userId, 'role': role, 'roomId': roomId},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String?;
      }
      AppLogger.error('RTC', 'Token fetch failed: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('RTC', 'Token server unreachable', e);
    }
    return null;
  }

  Future<void> join({
    required String authToken,
    required String userName,
  }) async {
    if (!_isBuilt) await build();
    _updateState(HMSCallState.connecting);
    _callStartTime = DateTime.now();
    final config = HMSConfig(authToken: authToken, userName: userName);
    await _hmsSDK.join(config: config);
    AppLogger.rtc('Joining room as $userName');
  }

  Future<void> leave() async {
    await _hmsSDK.leave(hmsActionResultListener: this);
    AppLogger.rtc('Leaving room');
  }

  Future<void> toggleMic() async {
    await _hmsSDK.toggleMicMuteState();
    isMicMuted = !isMicMuted;
    AppLogger.rtc('Mic muted: $isMicMuted');
  }

  Future<void> toggleCamera() async {
    await _hmsSDK.toggleCameraMuteState();
    isCameraMuted = !isCameraMuted;
    AppLogger.rtc('Camera muted: $isCameraMuted');
  }

  Future<void> switchCamera() async {
    await _hmsSDK.switchCamera(hmsActionResultListener: this);
  }

  Future<void> endRoom({String reason = 'call ended'}) async {
    await _hmsSDK.endRoom(
        reason: reason, lock: false, hmsActionResultListener: this);
  }

  DateTime? get callStartTime => _callStartTime;

  void _updateState(HMSCallState s) {
    state = s;
    onStateChanged?.call(s);
  }

  void destroy() {
    if (_isBuilt) {
      _hmsSDK.removeUpdateListener(listener: this);
      _isBuilt = false;
      state = HMSCallState.idle;
      peers.clear();
      remoteVideoTracks.clear();
      localVideoTrack = null;
      localPeer = null;
    }
  }

  // ─── HMSUpdateListener ───────────────────────────────────────────────────

  @override
  void onJoin({required HMSRoom room}) {
    _updateState(HMSCallState.connected);
    AppLogger.rtc('Joined room: ${room.id}');
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    if (update == HMSPeerUpdate.peerJoined) {
      peers.add(peer);
      AppLogger.rtc('Peer joined: ${peer.name}');
    } else if (update == HMSPeerUpdate.peerLeft) {
      peers.removeWhere((p) => p.peerId == peer.peerId);
      AppLogger.rtc('Peer left: ${peer.name}');
    }
    if (peer.isLocal) localPeer = peer;
    onPeersChanged?.call(List.from(peers));
  }

  @override
  void onTrackUpdate(
      {required HMSTrack track,
      required HMSTrackUpdate trackUpdate,
      required HMSPeer peer}) {
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      final videoTrack = track as HMSVideoTrack;
      if (peer.isLocal) {
        localVideoTrack = videoTrack;
      } else {
        if (trackUpdate == HMSTrackUpdate.trackRemoved) {
          remoteVideoTracks.remove(peer.peerId);
        } else {
          remoteVideoTracks[peer.peerId] = videoTrack;
        }
      }
      onPeersChanged?.call(List.from(peers));
    }
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {
    AppLogger.rtc('Room update: $update');
  }

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}

  @override
  void onReconnecting() {
    _updateState(HMSCallState.reconnecting);
    AppLogger.rtc('Reconnecting...');
  }

  @override
  void onReconnected() {
    _updateState(HMSCallState.connected);
    AppLogger.rtc('Reconnected');
  }

  @override
  void onMessage({required HMSMessage message}) {}

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}

  @override
  void onChangeTrackStateRequest(
      {required HMSTrackChangeRequest hmsTrackChangeRequest}) {}

  @override
  void onRemovedFromRoom(
      {required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {
    _updateState(HMSCallState.ended);
  }

  @override
  void onAudioDeviceChanged(
      {HMSAudioDevice? currentAudioDevice,
      List<HMSAudioDevice>? availableAudioDevice}) {}

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}

  @override
  void onPeerListUpdate(
      {required List<HMSPeer> addedPeers,
      required List<HMSPeer> removedPeers}) {}

  @override
  void onHMSError({required HMSException error}) {
    final msg = error.message ?? error.description;
    AppLogger.error('RTC',
        'HMS Error [${error.code?.errorCode}]: $msg (terminal=${error.isTerminal})');
    if (error.isTerminal) {
      _updateState(HMSCallState.error);
    }
    onError?.call(msg);
  }

  // ─── HMSActionResultListener ─────────────────────────────────────────────

  @override
  void onSuccess(
      {HMSActionResultListenerMethod methodType =
          HMSActionResultListenerMethod.unknown,
      Map<String, dynamic>? arguments}) {
    AppLogger.rtc('HMS action success: $methodType');
    if (methodType == HMSActionResultListenerMethod.leave ||
        methodType == HMSActionResultListenerMethod.endRoom) {
      _updateState(HMSCallState.ended);
    }
  }

  @override
  void onException(
      {HMSActionResultListenerMethod methodType =
          HMSActionResultListenerMethod.unknown,
      Map<String, dynamic>? arguments,
      required HMSException hmsException}) {
    AppLogger.error('RTC', 'HMS action exception: ${hmsException.message}');
  }
}
