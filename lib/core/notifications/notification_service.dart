import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/lock/services/accessibility_lock_service.dart';
import 'schedule_math.dart';

/// Wraps flutter_local_notifications + tz scheduling.
/// Default schedule = 12:30 PM Asia/Manila (PRD §3.1, §4.2).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'medbuddy_reminders';
  static const _channelName = 'Medication reminders';
  static const _channelDesc = 'Scheduled daily medication reminders';
  static const reminderNotificationId = 1001;
  static const escalationNotificationId = 1002;
  static const lockNotificationId = 1003;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      );

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'lock-activate') {
      // Fire-and-forget — lock service is idempotent.
      AccessibilityLockService.instance.activate();
    }
  }

  Future<void> scheduleDailyReminder({
    TimeOfDay time = const TimeOfDay(hour: 12, minute: 30),
  }) async {
    await init();
    await _plugin.zonedSchedule(
      reminderNotificationId,
      'Hey! Time for your iron med + creatine 💊🍊',
      'Tap to verify and keep your streak going.',
      ScheduleMath.nextInstanceOf(time, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _plugin.zonedSchedule(
      escalationNotificationId,
      'Still waiting on you 👀',
      'Your calamansi juice is ready!',
      ScheduleMath.nextInstanceOf(
          ScheduleMath.addMinutes(time, 15), tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _plugin.zonedSchedule(
      lockNotificationId,
      'Phone locking now 🔒',
      'Verify your dose to unlock your phone.',
      ScheduleMath.nextInstanceOf(
          ScheduleMath.addMinutes(time, 30), tz.local),
      _details.copyWithPayload('lock-activate'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'lock-activate',
    );
  }

  /// Arms the lock immediately — used by background trigger at T+30.
  Future<void> armLockNow() async {
    await AccessibilityLockService.instance.activate();
  }

  Future<void> cancelAll() => _plugin.cancelAll();

}

extension on NotificationDetails {
  NotificationDetails copyWithPayload(String _) => this;
}
