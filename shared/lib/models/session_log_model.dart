class SessionLogModel {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating;
  final String? trainerNotes;
  final String? memberNotes;
  final String? callRequestId;
  final String memberName;
  final String trainerName;

  const SessionLogModel({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
    this.callRequestId,
    this.memberName = '',
    this.trainerName = '',
  });

  static int calculateDuration(DateTime start, DateTime end) =>
      end.difference(start).inSeconds.clamp(0, 86400);

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'durationSec': durationSec,
        'rating': rating,
        'trainerNotes': trainerNotes,
        'memberNotes': memberNotes,
        'callRequestId': callRequestId,
        'memberName': memberName,
        'trainerName': trainerName,
      };

  factory SessionLogModel.fromMap(Map<String, dynamic> map) => SessionLogModel(
        id: map['id'] as String? ?? '',
        memberId: map['memberId'] as String? ?? '',
        trainerId: map['trainerId'] as String? ?? '',
        startedAt: map['startedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int)
            : DateTime.now(),
        endedAt: map['endedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['endedAt'] as int)
            : DateTime.now(),
        durationSec: map['durationSec'] as int? ?? 0,
        rating: map['rating'] as int?,
        trainerNotes: map['trainerNotes'] as String?,
        memberNotes: map['memberNotes'] as String?,
        callRequestId: map['callRequestId'] as String?,
        memberName: map['memberName'] as String? ?? '',
        trainerName: map['trainerName'] as String? ?? '',
      );

  SessionLogModel copyWith(
          {int? rating, String? trainerNotes, String? memberNotes}) =>
      SessionLogModel(
        id: id,
        memberId: memberId,
        trainerId: trainerId,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSec: durationSec,
        rating: rating ?? this.rating,
        trainerNotes: trainerNotes ?? this.trainerNotes,
        memberNotes: memberNotes ?? this.memberNotes,
        callRequestId: callRequestId,
        memberName: memberName,
        trainerName: trainerName,
      );
}
