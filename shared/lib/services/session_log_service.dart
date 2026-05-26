import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/session_log_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

class SessionLogService {
  SessionLogService._();
  static final SessionLogService instance = SessionLogService._();

  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<String> createLog({
    required String memberId,
    required String trainerId,
    required DateTime startedAt,
    required DateTime endedAt,
    required String memberName,
    required String trainerName,
    String? callRequestId,
  }) async {
    final durationSec = SessionLogModel.calculateDuration(startedAt, endedAt);
    final log = SessionLogModel(
      id: _uuid.v4(),
      memberId: memberId,
      trainerId: trainerId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSec: durationSec,
      callRequestId: callRequestId,
      memberName: memberName,
      trainerName: trainerName,
    );
    await _db
        .collection(AppConstants.colSessionLogs)
        .doc(log.id)
        .set(log.toMap());
    AppLogger.rtc('Session log created: ${log.id}, duration: ${durationSec}s');
    return log.id;
  }

  Future<void> updateRating(
      String logId, int rating, String? memberNotes) async {
    await _db.collection(AppConstants.colSessionLogs).doc(logId).update({
      'rating': rating,
      if (memberNotes != null) 'memberNotes': memberNotes,
    });
  }

  Future<void> updateTrainerNotes(String logId, String notes) async {
    await _db.collection(AppConstants.colSessionLogs).doc(logId).update({
      'trainerNotes': notes,
    });
  }

  Stream<List<SessionLogModel>> memberLogsStream(String memberId) {
    return _db
        .collection(AppConstants.colSessionLogs)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => SessionLogModel.fromMap(d.data())).toList();
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return list;
    });
  }

  Stream<List<SessionLogModel>> trainerLogsStream(String trainerId) {
    return _db
        .collection(AppConstants.colSessionLogs)
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => SessionLogModel.fromMap(d.data())).toList();
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return list;
    });
  }
}
