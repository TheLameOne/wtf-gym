class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final String status; // 'sending' | 'sent' | 'read'
  final bool isSystemMessage;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.status = 'sending',
    this.isSystemMessage = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'status': status,
        'isSystemMessage': isSystemMessage,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as String? ?? '',
        chatId: map['chatId'] as String? ?? '',
        senderId: map['senderId'] as String? ?? '',
        receiverId: map['receiverId'] as String? ?? '',
        text: map['text'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
            : DateTime.now(),
        status: map['status'] as String? ?? 'sent',
        isSystemMessage: map['isSystemMessage'] as bool? ?? false,
      );

  MessageModel copyWith({String? status}) => MessageModel(
        id: id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        createdAt: createdAt,
        status: status ?? this.status,
        isSystemMessage: isSystemMessage,
      );
}

class ChatMeta {
  final String chatId;
  final String memberId;
  final String trainerId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCountMember;
  final int unreadCountTrainer;
  final String memberName;
  final String trainerName;

  const ChatMeta({
    required this.chatId,
    required this.memberId,
    required this.trainerId,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCountMember = 0,
    this.unreadCountTrainer = 0,
    this.memberName = '',
    this.trainerName = '',
  });

  int unreadFor(String userId) {
    if (userId == memberId) return unreadCountMember;
    if (userId == trainerId) return unreadCountTrainer;
    return 0;
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'memberId': memberId,
        'trainerId': trainerId,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
        'unreadCountMember': unreadCountMember,
        'unreadCountTrainer': unreadCountTrainer,
        'memberName': memberName,
        'trainerName': trainerName,
      };

  factory ChatMeta.fromMap(Map<String, dynamic> map) => ChatMeta(
        chatId: map['chatId'] as String? ?? '',
        memberId: map['memberId'] as String? ?? '',
        trainerId: map['trainerId'] as String? ?? '',
        lastMessage: map['lastMessage'] as String? ?? '',
        lastMessageAt: map['lastMessageAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'] as int)
            : DateTime.now(),
        unreadCountMember: map['unreadCountMember'] as int? ?? 0,
        unreadCountTrainer: map['unreadCountTrainer'] as int? ?? 0,
        memberName: map['memberName'] as String? ?? '',
        trainerName: map['trainerName'] as String? ?? '',
      );
}
