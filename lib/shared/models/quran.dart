class SurahMeta {
  SurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahCount,
  });

  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int ayahCount;

  factory SurahMeta.fromJson(Map<String, dynamic> j) => SurahMeta(
        number: j['number'] as int,
        name: j['name'] as String,
        englishName: j['englishName'] as String,
        englishNameTranslation: j['englishNameTranslation'] as String,
        revelationType: j['revelationType'] as String,
        ayahCount: j['ayahCount'] as int,
      );
}

class Ayah {
  Ayah({
    required this.number,
    required this.numberInSurah,
    required this.arabic,
    required this.translation,
    required this.juz,
    required this.page,
    required this.sajda,
  });

  final int number;
  final int numberInSurah;
  final String arabic;
  final String translation;
  final int juz;
  final int page;
  final bool sajda;

  factory Ayah.fromJson(Map<String, dynamic> j, String langCode) {
    final translations = (j['translations'] as Map<String, dynamic>? ?? {});
    final pickKey = (langCode == 'ckb' || langCode == 'ckb_Badini') ? 'ku' : langCode;
    final translation = (translations[pickKey] ??
            translations['en'] ??
            '') as String;
    return Ayah(
      number: j['number'] as int,
      numberInSurah: j['numberInSurah'] as int,
      arabic: j['arabic'] as String,
      translation: translation,
      juz: j['juz'] as int,
      page: j['page'] as int,
      sajda: j['sajda'] as bool? ?? false,
    );
  }
}

class Surah {
  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahs,
  });

  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final List<Ayah> ayahs;

  factory Surah.fromJson(Map<String, dynamic> j, String langCode) {
    final list = (j['ayahs'] as List).cast<Map<String, dynamic>>();
    return Surah(
      number: j['number'] as int,
      name: j['name'] as String,
      englishName: j['englishName'] as String,
      englishNameTranslation: j['englishNameTranslation'] as String,
      revelationType: j['revelationType'] as String,
      ayahs: list.map((a) => Ayah.fromJson(a, langCode)).toList(),
    );
  }
}

/// Lightweight bounds for the mushaf — just meta + ayah↔page mapping, no
/// Quran text. Loaded on entry so mushaf can render without pulling the
/// full surah body.
class SurahPageMap {
  const SurahPageMap({
    required this.meta,
    required this.firstPage,
    required this.lastPage,
    required this.ayahToPage,
    required this.firstAyahByPage,
  });

  final SurahMeta meta;
  final int firstPage;
  final int lastPage;
  final Map<int, int> ayahToPage; // numberInSurah → page
  final Map<int, int> firstAyahByPage; // page → first numberInSurah on it
}
