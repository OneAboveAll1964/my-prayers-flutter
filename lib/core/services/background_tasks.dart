import 'package:workmanager/workmanager.dart';

import '../../shared/data/muslim_db.dart';
import '../../shared/state/settings_provider.dart';
import 'notification_service.dart';

const rescheduleTaskName = 'com.shkomaghdid.sakina.reschedule';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final s = await SettingsNotifier.load();
      if (s.location == null || !s.notificationsEnabled) return true;
      await MuslimDb.instance.open();
      await NotificationService.instance.init();
      await NotificationService.instance.reschedule(
        location: s.location,
        attribute: s.toAttribute(),
        useFixed: s.useFixedTimes,
        enabled: s.notificationsEnabled,
        perPrayer: s.perPrayerNotifications,
      );
      return true;
    } catch (_) {
      // Returning false lets the OS retry with backoff.
      return false;
    }
  });
}

Future<void> registerBackgroundReschedule() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    rescheduleTaskName,
    rescheduleTaskName,
    frequency: const Duration(hours: 12),
    initialDelay: const Duration(hours: 6),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
