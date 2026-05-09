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

  static String _translationColumn(String langCode) {
    if (langCode == 'ar') return 'translation_ar';
    if (langCode == 'ckb' || langCode == 'ckb_Badini') return 'translation_ku';
    return 'translation_en';
  }
}
