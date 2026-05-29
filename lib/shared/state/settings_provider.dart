import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../models/prayer_time.dart';

enum AppThemeMode { auto, light, dark }

class AppSettings {
  AppSettings({
    this.themeMode = AppThemeMode.auto,
    this.language,
    this.arabicFont = 'scheherazade',
    this.location,
    this.calculationMethod = CalculationMethod.makkah,
    this.asrMethod = AsrMethod.shafii,
    this.higherLatitudeMethod = HigherLatitudeMethod.angleBased,
    this.fajrAngle = 18.0,
    this.ishaAngle = 17.0,
    this.offsets = const [0, 0, 0, 0, 0, 0],
    this.useFixedTimes = true,
    this.notificationsEnabled = true,
    this.perPrayerNotifications = const [true, false, true, true, true, true],
    this.timeFormat = '12h',
    this.arabicFontScale = 1.0,
    this.translationFontScale = 1.0,
    this.quranBold = false,
    this.translationBold = false,
    this.quranReadMode = 'scroll',
    this.onboardingComplete = false,
    this.selectedReciterId,
    this.selectedTafsirId,
    this.selectedSurahInfoLanguage,
  });

  final AppThemeMode themeMode;
  final String? language;
  final String arabicFont;
  final AppLocation? location;
  final CalculationMethod calculationMethod;
  final AsrMethod asrMethod;
  final HigherLatitudeMethod higherLatitudeMethod;
  final double fajrAngle;
  final double ishaAngle;
  final List<int> offsets;
  final bool useFixedTimes;
  final bool notificationsEnabled;
  final List<bool> perPrayerNotifications;
  final String timeFormat;
  final double arabicFontScale;
  final double translationFontScale;
  final bool quranBold;
  final bool translationBold;
  final String quranReadMode;
  final bool onboardingComplete;
  final int? selectedReciterId;
  final int? selectedTafsirId;
  final String? selectedSurahInfoLanguage;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    Object? language = _sentinel,
    String? arabicFont,
    Object? location = _sentinel,
    CalculationMethod? calculationMethod,
    AsrMethod? asrMethod,
    HigherLatitudeMethod? higherLatitudeMethod,
    double? fajrAngle,
    double? ishaAngle,
    List<int>? offsets,
    bool? useFixedTimes,
    bool? notificationsEnabled,
    List<bool>? perPrayerNotifications,
    String? timeFormat,
    double? arabicFontScale,
    double? translationFontScale,
    bool? quranBold,
    bool? translationBold,
    String? quranReadMode,
    bool? onboardingComplete,
    Object? selectedReciterId = _sentinel,
    Object? selectedTafsirId = _sentinel,
    Object? selectedSurahInfoLanguage = _sentinel,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language == _sentinel ? this.language : language as String?,
      arabicFont: arabicFont ?? this.arabicFont,
      location: location == _sentinel ? this.location : location as AppLocation?,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      higherLatitudeMethod: higherLatitudeMethod ?? this.higherLatitudeMethod,
      fajrAngle: fajrAngle ?? this.fajrAngle,
      ishaAngle: ishaAngle ?? this.ishaAngle,
      offsets: offsets ?? this.offsets,
      useFixedTimes: useFixedTimes ?? this.useFixedTimes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      perPrayerNotifications: perPrayerNotifications ?? this.perPrayerNotifications,
      timeFormat: timeFormat ?? this.timeFormat,
      arabicFontScale: arabicFontScale ?? this.arabicFontScale,
      translationFontScale:
          translationFontScale ?? this.translationFontScale,
      quranBold: quranBold ?? this.quranBold,
      translationBold: translationBold ?? this.translationBold,
      quranReadMode: quranReadMode ?? this.quranReadMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      selectedReciterId: selectedReciterId == _sentinel
          ? this.selectedReciterId
          : selectedReciterId as int?,
      selectedTafsirId: selectedTafsirId == _sentinel
          ? this.selectedTafsirId
          : selectedTafsirId as int?,
      selectedSurahInfoLanguage: selectedSurahInfoLanguage == _sentinel
          ? this.selectedSurahInfoLanguage
          : selectedSurahInfoLanguage as String?,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'language': language,
        'arabicFont': arabicFont,
        'location': location?.toJson(),
        'calculationMethod': calculationMethod.name,
        'asrMethod': asrMethod.name,
        'higherLatitudeMethod': higherLatitudeMethod.name,
        'fajrAngle': fajrAngle,
        'ishaAngle': ishaAngle,
        'offsets': offsets,
        'useFixedTimes': useFixedTimes,
        'notificationsEnabled': notificationsEnabled,
        'perPrayerNotifications': perPrayerNotifications,
        'timeFormat': timeFormat,
        'arabicFontScale': arabicFontScale,
        'translationFontScale': translationFontScale,
        'quranBold': quranBold,
        'translationBold': translationBold,
        'quranReadMode': quranReadMode,
        'onboardingComplete': onboardingComplete,
        'selectedReciterId': selectedReciterId,
        'selectedTafsirId': selectedTafsirId,
        'selectedSurahInfoLanguage': selectedSurahInfoLanguage,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: AppThemeMode.values.firstWhere(
          (e) => e.name == j['themeMode'],
          orElse: () => AppThemeMode.auto,
        ),
        language: j['language'] as String?,
        arabicFont: (j['arabicFont'] ?? 'scheherazade') as String,
        location: j['location'] != null
            ? AppLocation.fromJson(j['location'] as Map<String, dynamic>)
            : null,
        calculationMethod: CalculationMethod.values.firstWhere(
          (e) => e.name == j['calculationMethod'],
          orElse: () => CalculationMethod.makkah,
        ),
        asrMethod: AsrMethod.values.firstWhere(
          (e) => e.name == j['asrMethod'],
          orElse: () => AsrMethod.shafii,
        ),
        higherLatitudeMethod: HigherLatitudeMethod.values.firstWhere(
          (e) => e.name == j['higherLatitudeMethod'],
          orElse: () => HigherLatitudeMethod.angleBased,
        ),
        fajrAngle: (j['fajrAngle'] as num?)?.toDouble() ?? 18.0,
        ishaAngle: (j['ishaAngle'] as num?)?.toDouble() ?? 17.0,
        offsets: (j['offsets'] as List?)?.map((e) => (e as num).toInt()).toList() ??
            const [0, 0, 0, 0, 0, 0],
        useFixedTimes: (j['useFixedTimes'] ?? true) as bool,
        notificationsEnabled: (j['notificationsEnabled'] ?? true) as bool,
        perPrayerNotifications: (j['perPrayerNotifications'] as List?)
                ?.map((e) => e as bool)
                .toList() ??
            const [true, false, true, true, true, true],
        timeFormat: (j['timeFormat'] ?? '12h') as String,
        arabicFontScale: (j['arabicFontScale'] as num?)?.toDouble() ?? 1.0,
        translationFontScale:
            (j['translationFontScale'] as num?)?.toDouble() ?? 1.0,
        quranBold: (j['quranBold'] ?? false) as bool,
        translationBold: (j['translationBold'] ?? false) as bool,
        quranReadMode: (j['quranReadMode'] ?? 'scroll') as String,
        onboardingComplete: (j['onboardingComplete'] ?? false) as bool,
        selectedReciterId: (j['selectedReciterId'] as num?)?.toInt(),
        selectedTafsirId: (j['selectedTafsirId'] as num?)?.toInt(),
        selectedSurahInfoLanguage:
            j['selectedSurahInfoLanguage'] as String?,
      );

  PrayerAttribute toAttribute() => PrayerAttribute(
        calculationMethod: calculationMethod,
        customMethod: CustomMethod(fajrAngle: fajrAngle, ishaAngle: ishaAngle),
        asrMethod: asrMethod,
        higherLatitudeMethod: higherLatitudeMethod,
        offsets: offsets,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs, AppSettings initial) : super(initial);

  static const _key = 'mp.settings.v1';
  final SharedPreferences _prefs;

  static Future<SettingsNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return SettingsNotifier(prefs, AppSettings());
    try {
      return SettingsNotifier(
        prefs,
        AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      return SettingsNotifier(prefs, AppSettings());
    }
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }
  AppSettings get current => state;

  void update(AppSettings Function(AppSettings) fn) {
    state = fn(state);
    _save();
  }

  void _save() {
    _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void setTheme(AppThemeMode mode) => update((s) => s.copyWith(themeMode: mode));
  void setLanguage(String? code) => update((s) => s.copyWith(language: code));
  void setArabicFont(String id) => update((s) => s.copyWith(arabicFont: id));
  void setLocation(AppLocation? loc) => update((s) => s.copyWith(location: loc));
  void setCalculationMethod(CalculationMethod m) =>
      update((s) => s.copyWith(calculationMethod: m));
  void setAsrMethod(AsrMethod m) => update((s) => s.copyWith(asrMethod: m));
  void setHigherLatitudeMethod(HigherLatitudeMethod m) =>
      update((s) => s.copyWith(higherLatitudeMethod: m));
  void setOffsets(List<int> offsets) => update((s) => s.copyWith(offsets: offsets));
  void setQuranBold(bool v) => update((s) => s.copyWith(quranBold: v));
  void setTranslationBold(bool v) =>
      update((s) => s.copyWith(translationBold: v));
  void setUseFixedTimes(bool v) => update((s) => s.copyWith(useFixedTimes: v));
  void setFajrAngle(double v) => update((s) => s.copyWith(fajrAngle: v));
  void setIshaAngle(double v) => update((s) => s.copyWith(ishaAngle: v));
  void setNotificationsEnabled(bool v) =>
      update((s) => s.copyWith(notificationsEnabled: v));
  void setPerPrayerNotifications(List<bool> list) =>
      update((s) => s.copyWith(perPrayerNotifications: list));
  void setTimeFormat(String v) => update((s) => s.copyWith(timeFormat: v));
  void setArabicFontScale(double v) =>
      update((s) => s.copyWith(arabicFontScale: v.clamp(0.7, 1.6)));
  void setTranslationFontScale(double v) =>
      update((s) => s.copyWith(translationFontScale: v.clamp(0.7, 1.6)));
  void setQuranReadMode(String v) =>
      update((s) => s.copyWith(quranReadMode: v));
  void setOnboardingComplete(bool v) =>
      update((s) => s.copyWith(onboardingComplete: v));
  void setSelectedReciter(int? id) =>
      update((s) => s.copyWith(selectedReciterId: id));
  void setSelectedTafsir(int? id) =>
      update((s) => s.copyWith(selectedTafsirId: id));
  void setSelectedSurahInfoLanguage(String? lang) =>
      update((s) => s.copyWith(selectedSurahInfoLanguage: lang));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  throw UnimplementedError('Override settingsProvider in main()');
});
