import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/azkars/azkar_chapters_page.dart';
import '../../features/azkars/azkar_items_page.dart';
import '../../features/azkars/azkars_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../features/home/home_page.dart';
import '../../features/names/names_page.dart';
import '../../features/qibla/qibla_page.dart';
import '../../features/quran/quran_page.dart';
import '../../features/quran/surah_page.dart';
import '../../features/settings/settings_appearance_page.dart';
import '../../features/settings/settings_language_page.dart';
import '../../features/settings/settings_location_page.dart';
import '../../features/settings/settings_method_page.dart';
import '../../features/settings/settings_notifications_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/settings_prayer_times_page.dart';
import '../../features/settings/settings_resources_page.dart';
import '../../features/settings/resources/reciters_page.dart';
import '../../features/tasbih/tasbih_page.dart';
import '../../features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

NoTransitionPage<void> _instant(BuildContext context, GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              _instant(context, state, const HomePage()),
        ),
        GoRoute(
          path: '/azkars',
          pageBuilder: (context, state) =>
              _instant(context, state, const AzkarsPage()),
        ),
        GoRoute(
          path: '/qibla',
          pageBuilder: (context, state) =>
              _instant(context, state, const QiblaPage()),
        ),
        GoRoute(
          path: '/quran',
          pageBuilder: (context, state) =>
              _instant(context, state, const QuranPage()),
        ),
      ],
    ),
    GoRoute(
      path: '/azkars/category/:categoryId',
      builder: (context, state) => AzkarChaptersPage(
        categoryId: int.parse(state.pathParameters['categoryId']!),
      ),
    ),
    GoRoute(
      path: '/azkars/chapter/:chapterId',
      builder: (context, state) => AzkarItemsPage(
        chapterId: int.parse(state.pathParameters['chapterId']!),
        categoryName: state.uri.queryParameters['cat'] ?? '',
        chapterName: state.uri.queryParameters['name'] ?? '',
      ),
    ),
    GoRoute(
      path: '/quran/:number',
      builder: (context, state) => SurahPage(
        number: int.parse(state.pathParameters['number']!),
        initialAyah: int.tryParse(state.uri.queryParameters['ayah'] ?? ''),
        englishName: state.uri.queryParameters['name'],
        arabicName: state.uri.queryParameters['ar'],
        ayahCount: int.tryParse(state.uri.queryParameters['n'] ?? ''),
      ),
    ),
    GoRoute(path: '/calendar', builder: (context, state) => const CalendarPage()),
    GoRoute(path: '/names', builder: (context, state) => const NamesPage()),
    GoRoute(path: '/tasbih', builder: (context, state) => const TasbihPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const SettingsLanguagePage(),
    ),
    GoRoute(
      path: '/settings/location',
      builder: (context, state) => const SettingsLocationPage(),
    ),
    GoRoute(
      path: '/settings/method',
      builder: (context, state) => const SettingsMethodPage(),
    ),
    GoRoute(
      path: '/settings/appearance',
      builder: (context, state) => const SettingsAppearancePage(),
    ),
    GoRoute(
      path: '/settings/prayer-times',
      builder: (context, state) => const SettingsPrayerTimesPage(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const SettingsNotificationsPage(),
    ),
    GoRoute(
      path: '/settings/resources',
      builder: (context, state) => const SettingsResourcesPage(),
    ),
    GoRoute(
      path: '/settings/resources/reciters',
      builder: (context, state) => const RecitersPage(),
    ),
  ],
);
