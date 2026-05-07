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

  Future<void> tryReschedule() async {
    final s = settings.debugState;
    if (s.location == null || !s.notificationsEnabled) return;
    await NotificationService.instance.reschedule(
      location: s.location,
      attribute: s.toAttribute(),
      useFixed: s.useFixedTimes,
      enabled: s.notificationsEnabled,
      perPrayer: s.perPrayerNotifications,
    );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final granted = await NotificationService.instance.requestPermissions();
    if (granted) await tryReschedule();
  });

  // Re-check permission + reschedule whenever the app returns to foreground.
  // Catches the case where the user grants notification permission via system
  // Settings, or comes back after Samsung put the app to sleep — without this,
  // an alarm scheduled days ago may have been canceled and never re-armed.
  WidgetsBinding.instance.addObserver(_LifecycleHook(tryReschedule));
}

class _LifecycleHook with WidgetsBindingObserver {
  _LifecycleHook(this._onResume);
  final Future<void> Function() _onResume;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }
}
