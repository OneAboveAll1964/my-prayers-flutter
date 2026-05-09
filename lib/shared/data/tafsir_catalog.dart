import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Tafsir {
  const Tafsir({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
    required this.slug,
  });

  final int id;
  final String name;
  final String authorName;
  final String languageName;
  final String slug;

  String get languageLabel {
    if (languageName.isEmpty) return '';
    return languageName[0].toUpperCase() + languageName.substring(1);
  }

  String get displaySubtitle {
    final parts = <String>[];
    if (languageLabel.isNotEmpty) parts.add(languageLabel);
    if (authorName.isNotEmpty) parts.add(authorName);
    return parts.join(' · ');
  }

  factory Tafsir.fromJson(Map<String, dynamic> j) => Tafsir(
        id: j['id'] as int,
        name: (j['name'] ?? '').toString(),
        authorName: (j['author_name'] ?? '').toString(),
        languageName: (j['language_name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
      );
}

class TafsirCatalog {
  TafsirCatalog._();
  static const _prefsKey = 'mp.tafsirs.cache.v1';
  static List<Tafsir>? _cached;
  static Future<List<Tafsir>>? _inflight;

  static Future<List<Tafsir>> all() {
    if (_cached != null) return Future.value(_cached);
    return _inflight ??= _fetch();
  }

  static List<Tafsir>? cachedAll() => _cached;

  static Future<List<Map<String, dynamic>>?> _readPersistedRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistRaw(List<Map<String, dynamic>> raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(raw));
    } catch (_) {}
  }

  static List<Tafsir> _buildList(List<Map<String, dynamic>> raw) {
    return raw.map(Tafsir.fromJson).toList()
      ..sort((a, b) {
        final byLang = a.languageName.compareTo(b.languageName);
        if (byLang != 0) return byLang;
        return a.name.compareTo(b.name);
      });
  }

  static Future<List<Tafsir>> _fetch() async {
    try {
      final res = await http
          .get(
            Uri.parse('https://api.quran.com/api/v4/resources/tafsirs'),
            headers: const {'User-Agent': 'MyPrayers/1.0'},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw Exception('catalog ${res.statusCode}');
      }
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final raw = (body['tafsirs'] as List).cast<Map<String, dynamic>>();
      await _persistRaw(raw);
      final list = _buildList(raw);
      _cached = list;
      _inflight = null;
      return list;
    } catch (e) {
      final persisted = await _readPersistedRaw();
      if (persisted != null && persisted.isNotEmpty) {
        final list = _buildList(persisted);
        _cached = list;
        _inflight = null;
        return list;
      }
      _inflight = null;
      rethrow;
    }
  }
}
