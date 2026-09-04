import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/lock/services/accessibility_lock_service.dart';
import '../../shared/models/medication_model.dart';
import 'schedule_math.dart';

/// Wraps flutter_local_notifications + tz scheduling.
///
/// [scheduleAllReminders] is the only scheduling entry point — it is driven by
/// the `medicationsProvider` listener in `main.dart`, so the notification set
/// always mirrors the user's active medications. Daily repeats survive reboot
/// via the plugin's own boot receiver (`RECEIVE_BOOT_COMPLETED`); no background
/// worker is needed to re-arm them.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'medbuddy_reminders';
  static const _channelName = 'Medication reminders';
  static const _channelDesc = 'Scheduled daily medication reminders';

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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  /// Asks for POST_NOTIFICATIONS (Android 13+). iOS permission is requested
  /// by [init] via DarwinInitializationSettings. Call this at the moment the
  /// user has just asked for a reminder so the OS prompt has context — the
  /// system only offers it once.
  Future<bool> requestPermissions() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true; // iOS — granted at init.
    return await android.requestNotificationsPermission() ?? false;
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

  /// Cancels every reminder and re-schedules one set per active medication.
  /// Stable per-med IDs via `medication.id.hashCode` so re-runs replace rather
  /// than duplicate. Three notifications per med: reminder, T+15 escalation,
  /// T+30 lock. Also schedules a native AlarmManager exact-alarm so the lock
  /// auto-engages whether the app is foregrounded or killed.
  Future<void> scheduleAllReminders(List<MedicationModel> meds) async {
    await init();
    await _plugin.cancelAll();
    // Wipe any existing native lock alarms before re-scheduling. Ensures
    // deleted / deactivated meds stop locking the device.
    await AccessibilityLockService.instance.cancelAllLockAlarms();
    for (final med in meds.where((m) => m.active)) {
      final base = med.id.hashCode & 0x7FFFFFFF; // positive 31-bit
      final remindAt = ScheduleMath.nextInstanceOf(med.scheduleTime, tz.local);
      final escalateAt = ScheduleMath.nextInstanceOf(
        ScheduleMath.addMinutes(med.scheduleTime, 15),
        tz.local,
      );
      final lockAt = ScheduleMath.nextInstanceOf(
        ScheduleMath.addMinutes(med.scheduleTime, 30),
        tz.local,
      );

      await _plugin.zonedSchedule(
        base + 0,
        'Time for ${med.name} 💊',
        'Tap to verify and keep your streak going.',
        remindAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _plugin.zonedSchedule(
        base + 1,
        'Still waiting on you 👀',
        "Take ${med.name} when you're ready.",
        escalateAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _plugin.zonedSchedule(
        base + 2,
        'Phone locking now 🔒',
        'Verify your dose to unlock your phone.',
        lockAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'lock-activate',
      );

      // Native AlarmManager auto-arm — fires even when app is killed.
      await AccessibilityLockService.instance.scheduleLockAlarm(
        medId: med.id,
        medName: med.name,
        hour: med.scheduleTime.hour,
        minute: med.scheduleTime.minute,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
