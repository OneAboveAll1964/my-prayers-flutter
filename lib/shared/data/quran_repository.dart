import '../../core/i18n/app_l10n.dart';
import '../models/quran.dart';
import 'quran_db.dart';

class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<SurahMeta>? _list;
  final Map<int, Surah> _surahCacheEn = {};
  final Map<int, Surah> _surahCacheAr = {};
  final Map<int, Surah> _surahCacheKu = {};
  final Map<int, SurahPageMap> _pageMapCache = {};
  final Map<int, Map<String, Ayah>> _pageAyahCacheEn = {};
  final Map<int, Map<String, Ayah>> _pageAyahCacheAr = {};
  final Map<int, Map<String, Ayah>> _pageAyahCacheKu = {};

  Future<List<SurahMeta>> getSurahList() async {
    if (_list != null) return _list!;
    final db = await QuranDb.instance.open();
    final rows = await db.rawQuery(
      'SELECT number, name, english_name, english_name_translation, '
          'revelation_type, ayah_count FROM surahs ORDER BY number ASC',
    );
    _list = [
      for (final r in rows)
        SurahMeta(
          number: r['number'] as int,
          name: r['name'] as String,
          englishName: r['english_name'] as String,
          englishNameTranslation: r['english_name_translation'] as String,
          revelationType: r['revelation_type'] as String,
          ayahCount: r['ayah_count'] as int,
        ),
    ];
    return _list!;
  }

  Future<Surah?> getSurah(int number, String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final cache = _cacheFor(lang);
    if (cache.containsKey(number)) return cache[number];

    final db = await QuranDb.instance.open();
    final translationCol = _translationColumn(lang);
    final headerRows = await db.rawQuery(
      'SELECT name, english_name, english_name_translation, revelation_type '
          'FROM surahs WHERE number = ? LIMIT 1',
      [number],
    );
    if (headerRows.isEmpty) return null;
    final header = headerRows.first;

    final ayahRows = await db.rawQuery(
      'SELECT number_in_surah, number_global, arabic, $translationCol AS '
          'translation, juz, page, sajda FROM ayahs WHERE surah = ? '
          'ORDER BY number_in_surah ASC',
      [number],
    );

    final surah = Surah(
      number: number,
      name: header['name'] as String,
      englishName: header['english_name'] as String,
      englishNameTranslation: header['english_name_translation'] as String,
      revelationType: header['revelation_type'] as String,
      ayahs: [
        for (final r in ayahRows)
          Ayah(
            number: r['number_global'] as int,
            numberInSurah: r['number_in_surah'] as int,
            arabic: r['arabic'] as String,
            translation: (r['translation'] as String?) ?? '',
            juz: r['juz'] as int,
            page: r['page'] as int,
            sajda: (r['sajda'] as int) == 1,
          ),
      ],
    );

    cache[number] = surah;
    return surah;
  }

  Future<Ayah?> getAyah(int surah, int numberInSurah, String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final db = await QuranDb.instance.open();
    final translationCol = _translationColumn(lang);
    final rows = await db.rawQuery(
      'SELECT number_in_surah, number_global, arabic, $translationCol AS '
          'translation, juz, page, sajda FROM ayahs WHERE surah = ? AND '
          'number_in_surah = ? LIMIT 1',
      [surah, numberInSurah],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Ayah(
      number: r['number_global'] as int,
      numberInSurah: r['number_in_surah'] as int,
      arabic: r['arabic'] as String,
      translation: (r['translation'] as String?) ?? '',
      juz: r['juz'] as int,
      page: r['page'] as int,
      sajda: (r['sajda'] as int) == 1,
    );
  }

  /// Light: surah meta + ayah↔page maps. No Arabic / translation text.
  /// Used by mushaf so it doesn't need the full surah body.
  Future<SurahPageMap?> getSurahPageMap(int number) async {
    final cached = _pageMapCache[number];
    if (cached != null) return cached;
    final db = await QuranDb.instance.open();
    final headerRows = await db.rawQuery(
      'SELECT number, name, english_name, english_name_translation, '
          'revelation_type, ayah_count FROM surahs WHERE number = ? LIMIT 1',
      [number],
    );
    if (headerRows.isEmpty) return null;
    final h = headerRows.first;
    final ayahRows = await db.rawQuery(
      'SELECT number_in_surah, page FROM ayahs WHERE surah = ? '
          'ORDER BY number_in_surah ASC',
      [number],
    );
    final ayahToPage = <int, int>{};
    final firstAyahByPage = <int, int>{};
    var firstPage = 1 << 30;
    var lastPage = 0;
    for (final r in ayahRows) {
      final n = r['number_in_surah'] as int;
      final p = r['page'] as int;
      ayahToPage[n] = p;
      firstAyahByPage.putIfAbsent(p, () => n);
      if (p < firstPage) firstPage = p;
      if (p > lastPage) lastPage = p;
    }
    final map = SurahPageMap(
      meta: SurahMeta(
        number: h['number'] as int,
        name: h['name'] as String,
        englishName: h['english_name'] as String,
        englishNameTranslation: h['english_name_translation'] as String,
        revelationType: h['revelation_type'] as String,
        ayahCount: h['ayah_count'] as int,
      ),
      firstPage: firstPage,
      lastPage: lastPage,
      ayahToPage: ayahToPage,
      firstAyahByPage: firstAyahByPage,
    );
    _pageMapCache[number] = map;
    return map;
  }

  /// Synchronous accessor for already-cached page ayah maps. Returns null
  /// when the data isn't in memory yet.
  Map<String, Ayah>? cachedAyahsByKeyForPage(int page, String langCode) {
    final lang = resolveDbLanguage(langCode);
    return _pageAyahCacheFor(lang)[page];
  }

  /// Returns every ayah on a mushaf page (across surahs at edges), keyed
  /// by `surah:numberInSurah`.
  Future<Map<String, Ayah>> getAyahsByKeyForPage(
      int page, String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final cache = _pageAyahCacheFor(lang);
    final cached = cache[page];
    if (cached != null) return cached;
    final db = await QuranDb.instance.open();
    final translationCol = _translationColumn(lang);
    final rows = await db.rawQuery(
      'SELECT surah, number_in_surah, number_global, arabic, $translationCol '
          'AS translation, juz, page, sajda FROM ayahs WHERE page = ? '
          'ORDER BY surah ASC, number_in_surah ASC',
      [page],
    );
    final result = <String, Ayah>{
      for (final r in rows)
        '${r['surah']}:${r['number_in_surah']}': Ayah(
          number: r['number_global'] as int,
          numberInSurah: r['number_in_surah'] as int,
          arabic: r['arabic'] as String,
          translation: (r['translation'] as String?) ?? '',
          juz: r['juz'] as int,
          page: r['page'] as int,
          sajda: (r['sajda'] as int) == 1,
        ),
    };
    cache[page] = result;
    return result;
  }

  Future<List<Ayah>> getAyahsForPage(int page, String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final db = await QuranDb.instance.open();
    final translationCol = _translationColumn(lang);
    final rows = await db.rawQuery(
      'SELECT number_in_surah, number_global, arabic, $translationCol AS '
          'translation, juz, page, sajda FROM ayahs WHERE page = ? '
          'ORDER BY surah ASC, number_in_surah ASC',
      [page],
    );
    return [
      for (final r in rows)
        Ayah(
          number: r['number_global'] as int,
          numberInSurah: r['number_in_surah'] as int,
          arabic: r['arabic'] as String,
          translation: (r['translation'] as String?) ?? '',
          juz: r['juz'] as int,
          page: r['page'] as int,
          sajda: (r['sajda'] as int) == 1,
        ),
    ];
  }

  Map<int, Surah> _cacheFor(String langCode) {
    if (langCode == 'ar') return _surahCacheAr;
    if (langCode == 'ckb' || langCode == 'ckb_Badini') return _surahCacheKu;
    return _surahCacheEn;
  }

  Map<int, Map<String, Ayah>> _pageAyahCacheFor(String langCode) {
    if (langCode == 'ar') return _pageAyahCacheAr;
    if (langCode == 'ckb' || langCode == 'ckb_Badini') return _pageAyahCacheKu;
    return _pageAyahCacheEn;
  }

  static String _translationColumn(String langCode) {
    if (langCode == 'ar') return 'translation_ar';
    if (langCode == 'ckb' || langCode == 'ckb_Badini') return 'translation_ku';
    return 'translation_en';
  }
}
