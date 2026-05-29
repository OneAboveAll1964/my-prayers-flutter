import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

    try {
      final ianaName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(ianaName));
    } catch (_) {
      try {
        final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        final candidate = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == offsetMs,
          orElse: () => tz.UTC,
        );
        tz.setLocalLocation(candidate);
      } catch (_) {}
    }

    const androidInit = AndroidInitializationSettings('@drawable/ic_notify');
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
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final canExact = await android.canScheduleExactNotifications() ?? false;
        if (!canExact) {
          await android.requestExactAlarmsPermission();
        }
      }
      return status.isGranted;
    }
    return true;
  }

  Future<bool> _canScheduleExactAndroid() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return (await android.canScheduleExactNotifications()) ?? false;
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

    final canExact = await _canScheduleExactAndroid();
    final scheduleMode = canExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final now = DateTime.now();
    final repo = PrayerTimeRepository.instance;
    final enabledCount = perPrayer.where((e) => e).length;
    final daysAhead = (Platform.isIOS && enabledCount > 0)
        ? (60 ~/ enabledCount).clamp(1, 30)
        : 30;
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
          mode: scheduleMode,
        );
      }
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required AndroidScheduleMode mode,
  }) async {
    try {
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
            largeIcon: DrawableResourceAndroidBitmap('ic_notify_large'),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'adhan.caf',
            presentSound: true,
            presentBanner: true,
            presentList: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: mode,
      );
    } catch (_) {
      try {
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
              largeIcon: DrawableResourceAndroidBitmap('ic_notify_large'),
            ),
            iOS: DarwinNotificationDetails(
              sound: 'adhan.caf',
              presentSound: true,
              presentAlert: true,
              presentBanner: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }
}
