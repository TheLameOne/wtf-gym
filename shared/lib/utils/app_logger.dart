import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static final List<String> _recentLogs = [];
  static const int _maxLogs = 20;

  static List<String> get recentLogs => List.unmodifiable(_recentLogs);

  static void _addToRecent(String tag, String message) {
    final entry =
        '[${DateTime.now().toIso8601String().substring(11, 19)}] $tag $message';
    if (_recentLogs.length >= _maxLogs) _recentLogs.removeAt(0);
    _recentLogs.add(entry);
  }

  static void auth(String message) {
    _logger.i('[AUTH] $message');
    _addToRecent('[AUTH]', message);
  }

  static void chat(String message) {
    _logger.d('[CHAT] $message');
    _addToRecent('[CHAT]', message);
  }

  static void rtc(String message) {
    _logger.d('[RTC] $message');
    _addToRecent('[RTC]', message);
  }

  static void schedule(String message) {
    _logger.d('[SCHEDULE] $message');
    _addToRecent('[SCHEDULE]', message);
  }

  static void error(String tag, String message, [Object? error]) {
    _logger.e('[$tag] $message', error: error);
    _addToRecent('[$tag][ERROR]', message);
  }

  static void info(String message) {
    _logger.i(message);
    _addToRecent('[INFO]', message);
  }
}
