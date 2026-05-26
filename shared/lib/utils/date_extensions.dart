import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String toTimeLabel() => DateFormat('h:mm a').format(this);

  String toDateLabel() => DateFormat('EEE, MMM d').format(this);

  String toFullLabel() => DateFormat('EEE, MMM d • h:mm a').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isToday() => isSameDay(DateTime.now());
  bool isTomorrow() => isSameDay(DateTime.now().add(const Duration(days: 1)));
}

extension DurationX on int {
  String toSessionDuration() {
    final minutes = this ~/ 60;
    final seconds = this % 60;
    if (minutes == 0) return '${seconds}s';
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }
}
