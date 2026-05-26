import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import '../utils/app_logger.dart';
import 'chat_service.dart';

/// Persists unsent chat messages in a local Hive box and retries them
/// when connectivity is restored.
///
/// Lifecycle:
///   init()          — open the box (call once per app launch)
///   enqueue(…)      — save a failed message
///   flush()         — attempt to send all queued messages
///   startAutoFlush()— start a 30-second periodic flush timer
///   stopAutoFlush() — cancel the timer (call from dispose)
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _boxName = 'offline_chat_queue';
  Box<String>? _box;
  Timer? _flushTimer;
  bool _isFlushing = false;
  final _uuid = const Uuid();

  /// Called after every successful flush or queue mutation so that
  /// conversation screens can rebuild via [onQueueChanged].
  VoidCallback? onQueueChanged;

  // ------------------------------------------------------------------
  // Initialisation
  // ------------------------------------------------------------------

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<String>(_boxName);
    } else {
      _box = await Hive.openBox<String>(_boxName);
    }
  }

  // ------------------------------------------------------------------
  // Queue operations
  // ------------------------------------------------------------------

  /// Number of messages currently in the queue.
  int get queueLength => _box?.length ?? 0;

  /// Persist [text] to the queue so it survives app restarts.
  ///
  /// Pass the same [id] you intended to write to Firestore so that
  /// once [flush] succeeds the Firestore stream deduplicates automatically.
  Future<void> enqueue({
    required String id,
    required String senderId,
    required String receiverId,
    required String text,
    required DateTime createdAt,
  }) async {
    final cId = ChatService.chatId(senderId, receiverId);
    final entry = jsonEncode({
      'id': id,
      'chatId': cId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    });
    await _box?.put(id, entry);
    AppLogger.chat('[Queue] Enqueued $id (total: ${_box?.length ?? 0})');
    onQueueChanged?.call();
  }

  /// All queued messages for [chatId] as [MessageModel] with status 'queued'.
  List<MessageModel> pendingFor(String chatId) {
    if (_box == null) return [];
    final result = _box!.values.map((v) {
      final map = jsonDecode(v) as Map<String, dynamic>;
      return MessageModel.fromMap({...map, 'status': 'queued'});
    }).where((m) => m.chatId == chatId).toList();
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  // ------------------------------------------------------------------
  // Flush
  // ------------------------------------------------------------------

  /// Attempt to send every queued message in order.
  ///
  /// Stops at the first failure (still offline) to preserve ordering.
  Future<void> flush() async {
    if (_isFlushing || (_box?.isEmpty ?? true)) return;
    _isFlushing = true;
    AppLogger.chat('[Queue] Flushing ${_box!.length} queued message(s)…');

    final keys = List<String>.from(_box!.keys.cast<String>());
    for (final key in keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      try {
        await ChatService.instance.sendMessage(
          id: map['id'] as String,
          senderId: map['senderId'] as String,
          receiverId: map['receiverId'] as String,
          text: map['text'] as String,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        );
        await _box!.delete(key);
        AppLogger.chat('[Queue] Sent queued message $key ✓');
        onQueueChanged?.call();
      } catch (e) {
        AppLogger.chat('[Queue] Still offline — stopping flush: $e');
        break; // Maintain ordering; retry next cycle
      }
    }
    _isFlushing = false;
  }

  // ------------------------------------------------------------------
  // Auto-flush timer
  // ------------------------------------------------------------------

  /// Start a 30-second periodic timer that calls [flush].
  void startAutoFlush() {
    _flushTimer?.cancel();
    _flushTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  /// Stop the auto-flush timer. Call this from screen [dispose].
  void stopAutoFlush() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Drop every pending message from the local queue (used by DevPanel reset).
  Future<void> clearAll() async {
    await _box?.clear();
    onQueueChanged?.call();
    AppLogger.chat('[Queue] Cleared all queued messages');
  }
}

// Typedef so we don't need an import of flutter/foundation in this file.
typedef VoidCallback = void Function();
