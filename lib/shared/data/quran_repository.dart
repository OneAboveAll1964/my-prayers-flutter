import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/i18n/app_l10n.dart';
import '../models/quran.dart';

class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<SurahMeta>? _list;
  final Map<int, Surah> _surahCacheEn = {};
  final Map<int, Surah> _surahCacheAr = {};
  final Map<int, Surah> _surahCacheKu = {};

  Future<List<SurahMeta>> getSurahList() async {
    if (_list != null) return _list!;
    final str = await rootBundle.loadString('assets/quran/list.json');
    final raw = (jsonDecode(str) as List).cast<Map<String, dynamic>>();
    _list = raw.map(SurahMeta.fromJson).toList();
    return _list!;
  }

  Future<Surah?> getSurah(int number, String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final cache = _cacheFor(lang);
    if (cache.containsKey(number)) return cache[number];
    try {
      final str = await rootBundle.loadString('assets/quran/$number.json');
      final j = jsonDecode(str) as Map<String, dynamic>;
      final surah = Surah.fromJson(j, lang);
      cache[number] = surah;
      return surah;
    } catch (_) {
      return null;
    }
  }

  Map<int, Surah> _cacheFor(String langCode) {
    if (langCode == 'ar') return _surahCacheAr;
    if (langCode == 'ckb' || langCode == 'ckb_Badini') return _surahCacheKu;
    return _surahCacheEn;
  }
}
