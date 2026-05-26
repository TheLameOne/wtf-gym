class RoomMetaModel {
  final String id;
  final String callRequestId;
  final String hmsRoomId;
  final String hmsRoleMember;
  final String hmsRoleTrainer;

  const RoomMetaModel({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    this.hmsRoleMember = 'guest',
    this.hmsRoleTrainer = 'host',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'callRequestId': callRequestId,
        'hmsRoomId': hmsRoomId,
        'hmsRoleMember': hmsRoleMember,
        'hmsRoleTrainer': hmsRoleTrainer,
      };

  factory RoomMetaModel.fromMap(Map<String, dynamic> map) => RoomMetaModel(
        id: map['id'] as String? ?? '',
        callRequestId: map['callRequestId'] as String? ?? '',
        hmsRoomId: map['hmsRoomId'] as String? ?? '',
        hmsRoleMember: map['hmsRoleMember'] as String? ?? 'guest',
        hmsRoleTrainer: map['hmsRoleTrainer'] as String? ?? 'host',
      );
}
