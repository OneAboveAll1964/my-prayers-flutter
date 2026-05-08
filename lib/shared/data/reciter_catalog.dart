import 'dart:convert';

import 'package:http/http.dart' as http;

class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.style,
    required this.translatedName,
  });

  final int id;
  final String name;
  final String? style;
  final String translatedName;

  String get displayName => name;

  String get displaySubtitle {
    final parts = <String>[];
    if (style != null && style!.isNotEmpty) parts.add(style!);
    if (translatedName.isNotEmpty && translatedName != name) {
      parts.add(translatedName);
    }
    return parts.join(' · ');
  }

  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
        id: j['id'] as int,
        name: (j['reciter_name'] ?? j['name'] ?? '').toString(),
        style: j['style']?.toString(),
        translatedName:
            (j['translated_name'] is Map ? j['translated_name']['name'] : null)
                    ?.toString() ??
                '',
      );
}

class ReciterCatalog {
  ReciterCatalog._();
  static List<Reciter>? _cached;
  static Future<List<Reciter>>? _inflight;

  static Future<List<Reciter>> all() {
    if (_cached != null) return Future.value(_cached);
    return _inflight ??= _fetch();
  }

  static List<Reciter>? cachedAll() => _cached;

  static Future<List<Reciter>> _fetch() async {
    try {
      final res = await http
          .get(
            Uri.parse('https://api.quran.com/api/v4/resources/recitations'),
            headers: const {'User-Agent': 'MyPrayers/1.0'},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw Exception('catalog ${res.statusCode}');
      }
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final raw = (body['recitations'] as List).cast<Map<String, dynamic>>();
      final list = raw.map(Reciter.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _cached = list;
      _inflight = null;
      return list;
    } catch (e) {
      _inflight = null;
      rethrow;
    }
  }
}

String resolveAudioUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('/')) return 'https://verses.quran.com$url';
  return 'https://verses.quran.com/$url';
}
