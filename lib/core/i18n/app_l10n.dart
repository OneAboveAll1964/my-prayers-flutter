import 'package:flutter/widgets.dart';
import 'en.dart';
import 'ar.dart';
import 'ckb.dart';
import 'ckb_badini.dart';

const supportedLocales = <Locale>[
  Locale('en'),
  Locale('ar'),
  Locale('ckb'),
  Locale.fromSubtags(languageCode: 'ckb', scriptCode: 'Badi'),
];

const _bundles = <String, Map<String, String>>{
  'en': enBundle,
  'ar': arBundle,
  'ckb': ckbBundle,
  'ckb_Badini': ckbBadiniBundle,
};

const rtlLanguages = {'ar', 'ckb', 'ckb_Badini'};

bool isRtlLang(String code) => rtlLanguages.contains(code);

String langKey(Locale locale) {
  if (locale.languageCode == 'ckb' && locale.scriptCode == 'Badi') {
    return 'ckb_Badini';
  }
  return locale.languageCode;
}

String resolveDbLanguage(String code) {
  if (_bundles.containsKey(code)) return code;
  final base = code.split('-').first.split('_').first;
  for (final key in _bundles.keys) {
    if (key.split('_').first == base) return key;
  }
  return 'en';
}

class AppL10n {
  AppL10n(this.locale);

  final Locale locale;
  late final String _key = langKey(locale);
  late final Map<String, String> _bundle = _bundles[_key] ?? enBundle;

  String t(String path, [Map<String, String>? vars]) {
    var raw = _bundle[path] ?? enBundle[path] ?? path;
    if (vars != null) {
      vars.forEach((k, v) => raw = raw.replaceAll('{$k}', v));
    }
    return raw;
  }

  bool get isRtl => isRtlLang(_key);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }
}

class AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const AppL10nDelegate();

  @override
  bool isSupported(Locale locale) {
    final k = langKey(locale);
    return _bundles.containsKey(k);
  }

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(AppL10nDelegate old) => false;
}

const arabicFontLabels = {
  'uthmanic-hafs': 'Uthmani Hafs',
  'qpc-hafs': 'QPC Hafs',
  'qpc-tajweed': 'QPC v4 Tajweed',
  'nastaleeq': 'KFGQPC Nastaleeq',
  'scheherazade': 'Scheherazade',
};

const arabicFontFamilies = {
  'uthmanic-hafs': 'UthmanicHafs',
  'qpc-hafs': 'QpcHafs',
  'qpc-tajweed': 'QpcV4Tajweed',
  'nastaleeq': 'KfgqpcNastaleeq',
  'scheherazade': 'ScheherazadeNew',
};

const langDisplayNames = {
  'en': 'English',
  'ar': 'العربية',
  'ckb': 'کوردی (سۆرانی)',
  'ckb_Badini': 'کوردی (بادینی)',
};
