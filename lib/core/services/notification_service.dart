import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../shared/models/location.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/data/prayer_time_repository.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'prayer_times';
  static const _channelName = 'Prayer times';
  static const _adhanResource = 'adhan';

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    final localTzName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (_) {
      try {
        final offset = DateTime.now().timeZoneOffset.inHours;
        final candidate = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == offset * 3600 * 1000,
          orElse: () => tz.UTC,
        );
        tz.setLocalLocation(candidate);
      } catch (_) {}
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Plays adhan at scheduled prayer times',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_adhanResource),
        enableVibration: true,
      ));
    }
    _initialised = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> reschedule({
    required AppLocation? location,
    required PrayerAttribute attribute,
    required bool useFixed,
    required bool enabled,
    required List<bool> perPrayer,
  }) async {
    await cancelAll();
    if (!enabled || location == null) return;

    final now = DateTime.now();
    final repo = PrayerTimeRepository.instance;
    final daysAhead = 30;
    var idCounter = 1;
    final labels = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    for (var d = 0; d < daysAhead; d++) {
      final date = DateTime(now.year, now.month, now.day + d);
      final prayer = await repo.getPrayerTimes(
        location: location,
        date: date,
        attribute: attribute,
        useFixedPrayer: useFixed,
      );
      if (prayer == null) continue;

      final times = [
        prayer.fajr,
        prayer.sunrise,
        prayer.dhuhr,
        prayer.asr,
        prayer.maghrib,
        prayer.isha,
      ];

      for (var i = 0; i < times.length; i++) {
        if (!perPrayer[i]) continue;
        final t = times[i];
        if (t.isBefore(now)) continue;
        await _scheduleOne(
          id: idCounter++,
          when: tz.TZDateTime.from(t, tz.local),
          title: labels[i],
          body: 'It is time for ${labels[i]} prayer',
        );
      }
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Plays adhan at scheduled prayer times',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(_adhanResource),
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'adhan.caf',
          presentSound: true,
          presentAlert: true,
          presentBanner: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
