import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'shared/data/muslim_db.dart';
import 'shared/state/favorites_provider.dart';
import 'shared/state/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
  );

  final settings = await SettingsNotifier.create();
  final favorites = await FavoritesNotifier.create();
  await MuslimDb.instance.open();
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        favoritesProvider.overrideWith((ref) => favorites),
      ],
      child: const MyPrayersApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final granted = await NotificationService.instance.requestPermissions();
    final s = settings.debugState;
    if (granted && s.location != null && s.notificationsEnabled) {
      await NotificationService.instance.reschedule(
        location: s.location,
        attribute: s.toAttribute(),
        useFixed: s.useFixedTimes,
        enabled: s.notificationsEnabled,
        perPrayer: s.perPrayerNotifications,
      );
    }
  });
}
