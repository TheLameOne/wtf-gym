class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'trainer' | 'member'
  final String? avatarUrl;
  final String? assignedTrainerId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  bool get isTrainer => role == 'trainer';
  bool get isMember => role == 'member';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatarUrl': avatarUrl,
        'assignedTrainerId': assignedTrainerId,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        role: map['role'] as String? ?? 'member',
        avatarUrl: map['avatarUrl'] as String?,
        assignedTrainerId: map['assignedTrainerId'] as String?,
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    String? assignedTrainerId,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
      );
}
