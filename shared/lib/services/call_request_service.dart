import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/call_request_model.dart';
import '../models/room_meta_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';
import 'chat_service.dart';

class CallRequestService {
  CallRequestService._();
  static final CallRequestService instance = CallRequestService._();

  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> createRequest(CallRequestModel request) async {
    await _db
        .collection(AppConstants.colCallRequests)
        .doc(request.id)
        .set(request.toMap());
    AppLogger.schedule(
        'Call request created: ${request.id} by ${request.memberName}');
  }

  Stream<List<CallRequestModel>> memberRequestsStream(String memberId) {
    return _db
        .collection(AppConstants.colCallRequests)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => CallRequestModel.fromMap(d.data())).toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  Stream<List<CallRequestModel>> trainerRequestsStream(String trainerId) {
    return _db
        .collection(AppConstants.colCallRequests)
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => CallRequestModel.fromMap(d.data())).toList();
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  /// Approve: create 100ms room via token server, store RoomMeta, send system message.
  Future<void> approveRequest(CallRequestModel request) async {
    try {
      // 0. Clean up any stale room_metas for this request
      final stale = await _db
          .collection(AppConstants.colRoomMetas)
          .where('callRequestId', isEqualTo: request.id)
          .get();
      for (final doc in stale.docs) {
        await doc.reference.delete();
      }

      // 1. Create 100ms room via token server
      final roomId = await _createHmsRoom(request.id);

      // 2. Store RoomMeta
      final meta = RoomMetaModel(
        id: _uuid.v4(),
        callRequestId: request.id,
        hmsRoomId: roomId,
        hmsRoleMember: AppConstants.hmsMemberRole,
        hmsRoleTrainer: AppConstants.hmsTrainerRole,
      );
      await _db
          .collection(AppConstants.colRoomMetas)
          .doc(meta.id)
          .set(meta.toMap());

      // 3. Update request status
      await _db
          .collection(AppConstants.colCallRequests)
          .doc(request.id)
          .update({'status': 'approved'});

      // 4. Send system message in chat
      final formattedTime = _formatTime(request.scheduledFor);
      await ChatService.instance.sendMessage(
        senderId: request.trainerId,
        receiverId: request.memberId,
        text: 'Call approved for $formattedTime.',
        isSystemMessage: true,
      );

      AppLogger.schedule('Request ${request.id} approved. Room: $roomId');
    } catch (e) {
      AppLogger.error('SCHEDULE', 'Failed to approve request', e);
      rethrow;
    }
  }

  Future<void> declineRequest(String requestId, String reason) async {
    await _db.collection(AppConstants.colCallRequests).doc(requestId).update({
      'status': 'declined',
      'declineReason': reason,
    });
    AppLogger.schedule('Request $requestId declined');
  }

  Future<RoomMetaModel?> getRoomMetaForRequest(String requestId) async {
    final snap = await _db
        .collection(AppConstants.colRoomMetas)
        .where('callRequestId', isEqualTo: requestId)
        .get();
    if (snap.docs.isEmpty) return null;
    final metas =
        snap.docs.map((d) => RoomMetaModel.fromMap(d.data())).toList();
    // Prefer real 100ms room IDs over fallback IDs
    return metas.firstWhere(
      (m) =>
          !m.hmsRoomId.startsWith('room_') && !m.hmsRoomId.startsWith('local_'),
      orElse: () => metas.last,
    );
  }

  /// Check if a time slot is already taken for a trainer.
  Future<bool> isSlotTaken(String trainerId, DateTime scheduledFor) async {
    final windowStart = scheduledFor.subtract(const Duration(minutes: 29));
    final windowEnd = scheduledFor.add(const Duration(minutes: 29));
    final snap = await _db
        .collection(AppConstants.colCallRequests)
        .where('trainerId', isEqualTo: trainerId)
        .where('status', isEqualTo: 'approved')
        .get();
    for (final doc in snap.docs) {
      final req = CallRequestModel.fromMap(doc.data());
      if (req.scheduledFor.isAfter(windowStart) &&
          req.scheduledFor.isBefore(windowEnd)) {
        return true;
      }
    }
    return false;
  }

  Future<String> _createHmsRoom(String requestId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.tokenServerUrl}/room'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': 'room_$requestId'}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'] as String? ?? data['roomId'] as String? ?? requestId;
      }
    } catch (e) {
      AppLogger.error(
          'SCHEDULE', 'Token server unreachable, using fallback room id', e);
    }
    // Fallback: use requestId as room identifier
    return 'room_$requestId';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} at $hour:$min $period';
  }
}
