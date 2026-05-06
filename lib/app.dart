import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/app_l10n.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'shared/state/settings_provider.dart';

class MyPrayersApp extends ConsumerWidget {
  const MyPrayersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    final locale = lang == null ? null : _localeFor(lang);

    final mode = switch (settings.themeMode) {
      AppThemeMode.auto => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolved = mode == ThemeMode.system
        ? platformBrightness
        : (mode == ThemeMode.dark ? Brightness.dark : Brightness.light);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          resolved == Brightness.dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: resolved,
      systemNavigationBarColor:
          resolved == Brightness.dark ? AppTokens.bgDark : AppTokens.bgLight,
      systemNavigationBarIconBrightness:
          resolved == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp.router(
      title: 'My Prayers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      themeAnimationDuration: AppTokens.duration,
      themeAnimationCurve: AppTokens.ease,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppL10nDelegate(),
        ...GlobalLocalizationDelegates.delegates,
      ],
      routerConfig: appRouter,
    );
  }

  Locale _localeFor(String code) {
    if (code == 'ckb_Badini') {
      return const Locale.fromSubtags(languageCode: 'ckb', scriptCode: 'Badi');
    }
    return Locale(code);
  }
}

class GlobalLocalizationDelegates {
  static const delegates = <LocalizationsDelegate>[
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
    DefaultCupertinoLocalizations.delegate,
  ];
}
