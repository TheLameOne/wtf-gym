import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local notification service for scheduling session reminders.
///
/// Call [init] once in main() before [runApp].
/// Call [scheduleSessionReminder] after a session is confirmed.
/// Call [cancelReminder] if the session is cancelled/declined.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'wtf_gym_reminders';
  static const _channelName = 'Session Reminders';
  static const _channelDesc = 'Reminders for upcoming training sessions';

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  /// Schedules a local notification [minutesBefore] minutes before
  /// [scheduledFor]. If the reminder time is already in the past, this is
  /// a no-op.
  Future<void> scheduleSessionReminder({
    required String requestId,
    required DateTime scheduledFor,
    required String title,
    required String body,
    int minutesBefore = 10,
  }) async {
    final reminderTime =
        scheduledFor.subtract(Duration(minutes: minutesBefore));
    if (!reminderTime.isAfter(DateTime.now())) return;

    final notifId = requestId.hashCode.abs() & 0x7FFFFFFF;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.UTC, reminderTime.millisecondsSinceEpoch),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: requestId,
    );
  }

  /// Cancels a previously scheduled reminder for [requestId].
  Future<void> cancelReminder(String requestId) async {
    final notifId = requestId.hashCode.abs() & 0x7FFFFFFF;
    await _plugin.cancel(notifId);
  }
}
