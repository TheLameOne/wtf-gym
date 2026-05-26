import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('MessageModel serialization', () {
    test('toMap and fromMap are inverse operations', () {
      final msg = MessageModel(
        id: 'msg1',
        chatId: 'chat1',
        senderId: 'member_dk',
        receiverId: 'trainer_aarav',
        text: 'Hello!',
        createdAt: DateTime(2025, 1, 1, 10, 0),
        status: 'sent',
      );

      final map = msg.toMap();
      map['id'] = 'msg1';
      final restored = MessageModel.fromMap(map);

      expect(restored.id, msg.id);
      expect(restored.chatId, msg.chatId);
      expect(restored.senderId, msg.senderId);
      expect(restored.receiverId, msg.receiverId);
      expect(restored.text, msg.text);
      expect(restored.status, msg.status);
      expect(restored.isSystemMessage, false);
    });

    test('system message flag preserved via toMap/fromMap', () {
      final msg = MessageModel(
        id: 'sys1',
        chatId: 'chat1',
        senderId: 'system',
        receiverId: '',
        text: 'Call approved',
        createdAt: DateTime(2025, 1, 2),
        status: 'sent',
        isSystemMessage: true,
      );
      final map2 = msg.toMap();
      map2['id'] = 'sys1';
      final restored = MessageModel.fromMap(map2);
      expect(restored.isSystemMessage, true);
    });
  });

  group('Validators', () {
    test('isValidFutureSlot returns false for past dates', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      expect(Validators.isValidFutureSlot(past), false);
    });

    test('isValidFutureSlot returns true for 2-hour future slot', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      expect(Validators.isValidFutureSlot(future), true);
    });

    test('validateNote returns null for empty string', () {
      expect(Validators.validateNote(''), isNull);
    });

    test('validateNote returns error for note > 140 chars', () {
      final longNote = 'a' * 141;
      expect(Validators.validateNote(longNote), isNotNull);
    });
  });
}
