import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/app_l10n.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'shared/state/settings_provider.dart';
import 'shared/widgets/splash_overlay.dart';

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
      title: 'Sakina',
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
        _CkbMaterialDelegate(),
        _CkbCupertinoDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (ctx, child) {
        final activeLocale = Localizations.localeOf(ctx);
        final isRtl = isRtlLang(langKey(activeLocale));
        final content = settings.onboardingComplete
            ? (child ?? const SizedBox())
            : const OnboardingFlow();
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: TextScaler.noScaling,
            boldText: false,
          ),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: SplashOverlay(child: content),
          ),
        );
      },
    );
  }

  Locale _localeFor(String code) {
    if (code == 'ckb_Badini') {
      return const Locale.fromSubtags(languageCode: 'ckb', scriptCode: 'Badi');
    }
    return Locale(code);
  }
}

class _CkbMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CkbMaterialDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));
  @override
  bool shouldReload(_CkbMaterialDelegate old) => false;
}

class _CkbCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CkbCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));
  @override
  bool shouldReload(_CkbCupertinoDelegate old) => false;
}
