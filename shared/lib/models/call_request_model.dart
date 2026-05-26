class CallRequestModel {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String? note;
  final String status; // 'pending' | 'approved' | 'declined' | 'cancelled'
  final String? declineReason;
  final String memberName;
  final String trainerName;

  const CallRequestModel({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    this.note,
    this.status = 'pending',
    this.declineReason,
    this.memberName = '',
    this.trainerName = '',
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  /// True when approved AND within the 10-minute join window (or past it).
  bool get isJoinable =>
      isApproved &&
      DateTime.now()
          .isAfter(scheduledFor.subtract(const Duration(minutes: 10)));

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'requestedAt': requestedAt.millisecondsSinceEpoch,
        'scheduledFor': scheduledFor.millisecondsSinceEpoch,
        'note': note,
        'status': status,
        'declineReason': declineReason,
        'memberName': memberName,
        'trainerName': trainerName,
      };

  factory CallRequestModel.fromMap(Map<String, dynamic> map) =>
      CallRequestModel(
        id: map['id'] as String? ?? '',
        memberId: map['memberId'] as String? ?? '',
        trainerId: map['trainerId'] as String? ?? '',
        requestedAt: map['requestedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['requestedAt'] as int)
            : DateTime.now(),
        scheduledFor: map['scheduledFor'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['scheduledFor'] as int)
            : DateTime.now(),
        note: map['note'] as String?,
        status: map['status'] as String? ?? 'pending',
        declineReason: map['declineReason'] as String?,
        memberName: map['memberName'] as String? ?? '',
        trainerName: map['trainerName'] as String? ?? '',
      );

  CallRequestModel copyWith({String? status, String? declineReason}) =>
      CallRequestModel(
        id: id,
        memberId: memberId,
        trainerId: trainerId,
        requestedAt: requestedAt,
        scheduledFor: scheduledFor,
        note: note,
        status: status ?? this.status,
        declineReason: declineReason ?? this.declineReason,
        memberName: memberName,
        trainerName: trainerName,
      );
}
