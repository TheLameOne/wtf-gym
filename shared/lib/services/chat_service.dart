import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Generates a stable chatId from two user IDs (order-independent).
  static String chatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return sorted.join('_');
  }

  /// Stream of messages ordered by time.
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection(AppConstants.colMessages)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => MessageModel.fromMap(d.data())).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Stream of all chat metas involving a user.
  Stream<List<ChatMeta>> chatListStream(String userId) {
    return _db
        .collection(AppConstants.colChats)
        .where(Filter.or(
          Filter('memberId', isEqualTo: userId),
          Filter('trainerId', isEqualTo: userId),
        ))
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ChatMeta.fromMap(d.data())).toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    bool isSystemMessage = false,
  }) async {
    final cId = chatId(senderId, receiverId);
    final msgId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      id: msgId,
      chatId: cId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: now,
      status: 'sent',
      isSystemMessage: isSystemMessage,
    );

    final batch = _db.batch();

    // Write message
    batch.set(
      _db
          .collection(AppConstants.colChats)
          .doc(cId)
          .collection(AppConstants.colMessages)
          .doc(msgId),
      message.toMap(),
    );

    // Update chat meta
    final chatRef = _db.collection(AppConstants.colChats).doc(cId);
    batch.set(
      chatRef,
      {
        'chatId': cId,
        'lastMessage': text,
        'lastMessageAt': now.millisecondsSinceEpoch,
        // increment unread for receiver
        _unreadKey(receiverId, senderId): FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    AppLogger.chat('Message sent: $senderId → $receiverId');
  }

  /// Mark all messages as read and reset unread count for [userId].
  Future<void> markAsRead(String cId, String userId, String otherId) async {
    final unreadKey = _unreadKey(userId, otherId);
    await _db.collection(AppConstants.colChats).doc(cId).set(
      {unreadKey: 0},
      SetOptions(merge: true),
    );

    // Update last ~50 messages from other user to 'read'
    final snap = await _db
        .collection(AppConstants.colChats)
        .doc(cId)
        .collection(AppConstants.colMessages)
        .where('senderId', isEqualTo: otherId)
        .where('status', isEqualTo: 'sent')
        .limit(50)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
    AppLogger.chat('Messages marked as read in $cId');
  }

  /// Set or clear typing indicator.
  Future<void> setTyping(String cId, String userId, bool isTyping) async {
    await _db.collection(AppConstants.colTyping).doc(cId).set(
      {userId: isTyping ? DateTime.now().millisecondsSinceEpoch : null},
      SetOptions(merge: true),
    );
  }

  /// Stream of whether [otherUserId] is typing in [cId].
  Stream<bool> typingStream(String cId, String otherUserId) {
    return _db
        .collection(AppConstants.colTyping)
        .doc(cId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return false;
      final ts = snap.data()?[otherUserId] as int?;
      if (ts == null) return false;
      // Consider stale after 5 seconds
      return DateTime.now().millisecondsSinceEpoch - ts < 5000;
    });
  }

  /// Ensure a chat meta document exists (called when starting a new chat).
  Future<void> ensureChatMeta({
    required String memberId,
    required String trainerId,
    required String memberName,
    required String trainerName,
  }) async {
    final cId = chatId(memberId, trainerId);
    final ref = _db.collection(AppConstants.colChats).doc(cId);
    await ref.set({
      'chatId': cId,
      'memberId': memberId,
      'trainerId': trainerId,
      'memberName': memberName,
      'trainerName': trainerName,
      'lastMessage': '',
      'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
      'unreadCountMember': 0,
      'unreadCountTrainer': 0,
    }, SetOptions(merge: true));
  }

  String _unreadKey(String userId, String senderId) {
    // The recipient's unread counter key
    if (userId == AppConstants.memberDkId) return 'unreadCountMember';
    return 'unreadCountTrainer';
  }
}
