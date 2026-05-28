import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';

/// Re-arms reminders after reboot / when app is killed.
class BackgroundScheduler {
  BackgroundScheduler._();

  static const _reArmTask = 'medbuddy_reArmReminders';

  static Future<void> init() async {
    await Workmanager().initialize(_callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _reArmTask,
      _reArmTask,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    await NotificationService.instance.init();
    await NotificationService.instance.scheduleDailyReminder();
    return true;
  });
}
