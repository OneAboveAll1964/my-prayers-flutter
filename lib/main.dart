import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/background_tasks.dart';
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

  const launchIcon = AssetImage('assets/widget/launch_icon.png');
  final iconReady = _precacheLaunchIcon(launchIcon);

  final settings = await SettingsNotifier.create();
  final favorites = await FavoritesNotifier.create();
  await MuslimDb.instance.open();
  await NotificationService.instance.init();

  await iconReady;

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
    final s = settings.current;
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
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
    final granted = await NotificationService.instance.requestPermissions();
    if (granted) await tryReschedule();
    try {
      await registerBackgroundReschedule();
    } catch (_) {}
  });

  WidgetsBinding.instance.addObserver(_LifecycleHook(tryReschedule));
}

Future<void> _precacheLaunchIcon(AssetImage provider) {
  final completer = Completer<void>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void done() {
    stream.removeListener(listener);
    if (!completer.isCompleted) completer.complete();
  }

  listener = ImageStreamListener(
    (_, _) => done(),
    onError: (_, _) => done(),
  );
  stream.addListener(listener);
  return completer.future.timeout(
    const Duration(milliseconds: 600),
    onTimeout: () {},
  );
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
