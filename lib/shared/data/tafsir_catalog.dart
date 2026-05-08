import 'dart:convert';

import 'package:http/http.dart' as http;

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
  static List<Tafsir>? _cached;
  static Future<List<Tafsir>>? _inflight;

  static Future<List<Tafsir>> all() {
    if (_cached != null) return Future.value(_cached);
    return _inflight ??= _fetch();
  }

  static List<Tafsir>? cachedAll() => _cached;

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
      final list = raw.map(Tafsir.fromJson).toList()
        ..sort((a, b) {
          final byLang = a.languageName.compareTo(b.languageName);
          if (byLang != 0) return byLang;
          return a.name.compareTo(b.name);
        });
      _cached = list;
      _inflight = null;
      return list;
    } catch (e) {
      _inflight = null;
      rethrow;
    }
  }
}
