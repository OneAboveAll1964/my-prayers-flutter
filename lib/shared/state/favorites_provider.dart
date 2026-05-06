import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';

class LastReadEntry {
  LastReadEntry({
    required this.number,
    required this.englishName,
    required this.name,
    required this.ayahCount,
    required this.lastAyah,
  });
  final int number;
  final String englishName;
  final String name;
  final int ayahCount;
  final int lastAyah;

  Map<String, dynamic> toJson() => {
        'number': number,
        'englishName': englishName,
        'name': name,
        'ayahCount': ayahCount,
        'lastAyah': lastAyah,
      };

  factory LastReadEntry.fromJson(Map<String, dynamic> j) => LastReadEntry(
        number: j['number'] as int,
        englishName: (j['englishName'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        ayahCount: (j['ayahCount'] ?? 0) as int,
        lastAyah: (j['lastAyah'] ?? 1) as int,
      );
}

class AyahBookmarkEntry {
  AyahBookmarkEntry({
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.arabicName,
    required this.preview,
    required this.addedAt,
  });
  final int surah;
  final int ayah;
  final String surahName;
  final String arabicName;
  final String preview;
  final int addedAt;

  String get key => '$surah:$ayah';

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'surahName': surahName,
        'arabicName': arabicName,
        'preview': preview,
        'addedAt': addedAt,
      };

  factory AyahBookmarkEntry.fromJson(Map<String, dynamic> j) =>
      AyahBookmarkEntry(
        surah: j['surah'] as int,
        ayah: j['ayah'] as int,
        surahName: (j['surahName'] ?? '') as String,
        arabicName: (j['arabicName'] ?? '') as String,
        preview: (j['preview'] ?? '') as String,
        addedAt: (j['addedAt'] ?? 0) as int,
      );
}

class TasbihState {
  TasbihState({this.count = 0, this.total = 0, this.target = 33});
  final int count;
  final int total;
  final int target;
  TasbihState copyWith({int? count, int? total, int? target}) =>
      TasbihState(
        count: count ?? this.count,
        total: total ?? this.total,
        target: target ?? this.target,
      );
  Map<String, dynamic> toJson() =>
      {'count': count, 'total': total, 'target': target};
  factory TasbihState.fromJson(Map<String, dynamic> j) => TasbihState(
        count: (j['count'] ?? 0) as int,
        total: (j['total'] ?? 0) as int,
        target: (j['target'] ?? 33) as int,
      );
}

class FavoritesState {
  FavoritesState({
    this.chapters = const [],
    this.surahs = const [],
    this.ayahs = const [],
    this.lastSurah,
    this.dhikr = const {},
    this.recentLocations = const [],
    this.tasbih = const TasbihState(count: 0, total: 0, target: 33),
  });

  final List<int> chapters;
  final List<int> surahs;
  final List<AyahBookmarkEntry> ayahs;
  final LastReadEntry? lastSurah;
  final Map<int, int> dhikr;
  final List<AppLocation> recentLocations;
  final TasbihState tasbih;

  FavoritesState copyWith({
    List<int>? chapters,
    List<int>? surahs,
    List<AyahBookmarkEntry>? ayahs,
    Object? lastSurah = _sentinel,
    Map<int, int>? dhikr,
    List<AppLocation>? recentLocations,
    TasbihState? tasbih,
  }) {
    return FavoritesState(
      chapters: chapters ?? this.chapters,
      surahs: surahs ?? this.surahs,
      ayahs: ayahs ?? this.ayahs,
      lastSurah: lastSurah == _sentinel
          ? this.lastSurah
          : lastSurah as LastReadEntry?,
      dhikr: dhikr ?? this.dhikr,
      recentLocations: recentLocations ?? this.recentLocations,
      tasbih: tasbih ?? this.tasbih,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'chapters': chapters,
        'surahs': surahs,
        'ayahs': ayahs.map((e) => e.toJson()).toList(),
        'lastSurah': lastSurah?.toJson(),
        'dhikr': dhikr.map((k, v) => MapEntry(k.toString(), v)),
        'recentLocations': recentLocations.map((e) => e.toJson()).toList(),
        'tasbih': tasbih.toJson(),
      };

  factory FavoritesState.fromJson(Map<String, dynamic> j) {
    final dhikrRaw = (j['dhikr'] as Map?)?.cast<String, dynamic>() ?? {};
    return FavoritesState(
      chapters: ((j['chapters'] as List?) ?? []).map((e) => e as int).toList(),
      surahs: ((j['surahs'] as List?) ?? []).map((e) => e as int).toList(),
      ayahs: ((j['ayahs'] as List?) ?? [])
          .map((e) => AyahBookmarkEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastSurah: j['lastSurah'] != null
          ? LastReadEntry.fromJson(j['lastSurah'] as Map<String, dynamic>)
          : null,
      dhikr: {
        for (final e in dhikrRaw.entries) int.parse(e.key): e.value as int,
      },
      recentLocations: ((j['recentLocations'] as List?) ?? [])
          .map((e) => AppLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      tasbih: j['tasbih'] != null
          ? TasbihState.fromJson(j['tasbih'] as Map<String, dynamic>)
          : const TasbihState(count: 0, total: 0, target: 33),
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._prefs, FavoritesState initial) : super(initial);
  static const _key = 'mp.favorites.v1';
  final SharedPreferences _prefs;

  static Future<FavoritesNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return FavoritesNotifier(prefs, FavoritesState());
    try {
      return FavoritesNotifier(
        prefs,
        FavoritesState.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      return FavoritesNotifier(prefs, FavoritesState());
    }
  }

  void _save() => _prefs.setString(_key, jsonEncode(state.toJson()));

  void toggleChapter(int id) {
    final list = [...state.chapters];
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    state = state.copyWith(chapters: list);
    _save();
  }

  bool isChapterStarred(int id) => state.chapters.contains(id);

  void toggleBookmarkSurah(int number) {
    final list = [...state.surahs];
    if (list.contains(number)) {
      list.remove(number);
    } else {
      list.add(number);
    }
    state = state.copyWith(surahs: list);
    _save();
  }

  bool isSurahBookmarked(int number) => state.surahs.contains(number);

  void toggleBookmarkAyah(
    int surah,
    int ayah, {
    String surahName = '',
    String arabicName = '',
    String preview = '',
  }) {
    final key = '$surah:$ayah';
    final existing = state.ayahs.where((a) => a.key == key).isNotEmpty;
    final list = existing
        ? state.ayahs.where((a) => a.key != key).toList()
        : [
            AyahBookmarkEntry(
              surah: surah,
              ayah: ayah,
              surahName: surahName,
              arabicName: arabicName,
              preview: preview,
              addedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            ...state.ayahs,
          ].take(200).toList();
    state = state.copyWith(ayahs: list);
    _save();
  }

  bool isAyahBookmarked(int surah, int ayah) =>
      state.ayahs.any((a) => a.surah == surah && a.ayah == ayah);

  void setLastSurah(LastReadEntry entry) {
    state = state.copyWith(lastSurah: entry);
    _save();
  }

  void setDhikr(int itemId, int count) {
    final map = {...state.dhikr};
    map[itemId] = count;
    state = state.copyWith(dhikr: map);
    _save();
  }

  int dhikrFor(int itemId) => state.dhikr[itemId] ?? 0;

  void pushRecentLocation(AppLocation loc) {
    final filtered = state.recentLocations.where((l) => l.id != loc.id).toList();
    final next = [loc, ...filtered].take(6).toList();
    state = state.copyWith(recentLocations: next);
    _save();
  }

  void setTasbih(TasbihState patch) {
    state = state.copyWith(tasbih: patch);
    _save();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  throw UnimplementedError('Override favoritesProvider in main()');
});
