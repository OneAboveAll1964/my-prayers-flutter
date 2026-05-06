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
import '../../features/settings/settings_page.dart';
import '../../features/settings/settings_language_page.dart';
import '../../features/settings/settings_location_page.dart';
import '../../features/settings/settings_method_page.dart';
import '../../features/tasbih/tasbih_page.dart';
import '../../features/shell/app_shell.dart';
import '../theme/tokens.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/azkars', builder: (_, __) => const AzkarsPage()),
        GoRoute(path: '/qibla', builder: (_, __) => const QiblaPage()),
        GoRoute(path: '/quran', builder: (_, __) => const QuranPage()),
      ],
    ),
    _fade(GoRoute(
      path: '/azkars/category/:categoryId',
      builder: (context, state) => AzkarChaptersPage(
        categoryId: int.parse(state.pathParameters['categoryId']!),
      ),
    )),
    _fade(GoRoute(
      path: '/azkars/chapter/:chapterId',
      builder: (context, state) => AzkarItemsPage(
        chapterId: int.parse(state.pathParameters['chapterId']!),
        categoryName: state.uri.queryParameters['cat'] ?? '',
        chapterName: state.uri.queryParameters['name'] ?? '',
      ),
    )),
    _fade(GoRoute(
      path: '/quran/:number',
      builder: (context, state) => SurahPage(
        number: int.parse(state.pathParameters['number']!),
        initialAyah: int.tryParse(state.uri.queryParameters['ayah'] ?? ''),
      ),
    )),
    _fade(GoRoute(path: '/calendar', builder: (_, __) => const CalendarPage())),
    _fade(GoRoute(path: '/names', builder: (_, __) => const NamesPage())),
    _fade(GoRoute(path: '/tasbih', builder: (_, __) => const TasbihPage())),
    _fade(GoRoute(path: '/settings', builder: (_, __) => const SettingsPage())),
    _fade(GoRoute(
        path: '/settings/language',
        builder: (_, __) => const SettingsLanguagePage())),
    _fade(GoRoute(
        path: '/settings/location',
        builder: (_, __) => const SettingsLocationPage())),
    _fade(GoRoute(
        path: '/settings/method',
        builder: (_, __) => const SettingsMethodPage())),
  ],
);

GoRoute _fade(GoRoute base) {
  return GoRoute(
    path: base.path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: base.builder!(context, state),
      transitionsBuilder: (context, animation, secondary, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppTokens.ease)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    ),
  );
}
