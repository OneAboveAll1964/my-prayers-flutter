import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SurahInfo {
  const SurahInfo({
    required this.surahNumber,
    required this.languageName,
    required this.shortText,
    required this.text,
    required this.source,
  });

  final int surahNumber;
  final String languageName;
  final String shortText;
  final String text;
  final String source;

  Map<String, dynamic> toJson() => {
        'surah': surahNumber,
        'language': languageName,
        'short_text': shortText,
        'text': text,
        'source': source,
      };

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
        surahNumber: (j['surah'] as num).toInt(),
        languageName: (j['language'] ?? '').toString(),
        shortText: (j['short_text'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        source: (j['source'] ?? '').toString(),
      );

  factory SurahInfo.fromApi(int surah, String lang, Map<String, dynamic> j) {
    final info = (j['chapter_info'] ?? const {}) as Map<String, dynamic>;
    return SurahInfo(
      surahNumber: surah,
      languageName:
          (info['language_name'] ?? lang).toString(),
      shortText: (info['short_text'] ?? '').toString(),
      text: (info['text'] ?? '').toString(),
      source: (info['source'] ?? '').toString(),
    );
  }
}

class SurahInfoProgress {
  const SurahInfoProgress({
    required this.filesDone,
    required this.totalFiles,
    this.failed = false,
    this.errorMessage,
  });
  final int filesDone;
  final int totalFiles;
  final bool failed;
  final String? errorMessage;

  double get fraction => totalFiles == 0 ? 0 : filesDone / totalFiles;
  bool get isComplete =>
      !failed && totalFiles > 0 && filesDone >= totalFiles;
}

const _maxConcurrent = 6;

const _languageApiCodes = <String, String>{
  'english': 'en',
  'arabic': 'ar',
  'urdu': 'ur',
  'bengali': 'bn',
  'indonesian': 'id',
  'russian': 'ru',
  'turkish': 'tr',
  'persian': 'fa',
  'french': 'fr',
  'german': 'de',
  'spanish': 'es',
  'portuguese': 'pt',
  'chinese': 'zh',
  'malay': 'ms',
};

String _apiCode(String langName) => _languageApiCodes[langName] ?? 'en';

class SurahInfoService {
  SurahInfoService._();
  static final SurahInfoService instance = SurahInfoService._();

  final Map<String, SurahInfo> _memCache = {};
  final Map<String, StreamController<SurahInfoProgress>> _active = {};
  final Set<String> _cancels = {};

  Future<Directory> _langDir(String lang) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'surah_info', lang));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(int surah, String lang) async {
    final dir = await _langDir(lang);
    return File(p.join(dir.path, '$surah.json'));
  }

  String _key(int s, String l) => '$l:$s';

  Future<SurahInfo?> cached(int surah, String lang) async {
    final mem = _memCache[_key(surah, lang)];
    if (mem != null) return mem;
    final f = await _file(surah, lang);
    if (await f.exists() && await f.length() > 0) {
      try {
        final info = SurahInfo.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>);
        _memCache[_key(surah, lang)] = info;
        return info;
      } catch (_) {}
    }
    return null;
  }

  Future<SurahInfo> fetch(int surah, String lang) async {
    final c = await cached(surah, lang);
    if (c != null) return c;
    return _fetchAndStore(surah, lang);
  }

  Future<SurahInfo> _fetchAndStore(int surah, String lang) async {
    final url =
        'https://api.quran.com/api/v4/chapters/$surah/info?language=${_apiCode(lang)}';
    final res = await http
        .get(Uri.parse(url),
            headers: const {'User-Agent': 'MyPrayers/1.0'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('surah info ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final info = SurahInfo.fromApi(surah, lang, body);
    final f = await _file(surah, lang);
    await f.writeAsString(jsonEncode(info.toJson()), flush: true);
    _memCache[_key(surah, lang)] = info;
    return info;
  }

  Future<bool> isInstalled(String lang) async {
    final dir = await _langDir(lang);
    final sentinel = File(p.join(dir.path, '.complete'));
    return await sentinel.exists();
  }

  Future<void> uninstall(String lang) async {
    final dir = await _langDir(lang);
    if (await dir.exists()) await dir.delete(recursive: true);
    _memCache.removeWhere((k, _) => k.startsWith('$lang:'));
  }

  Stream<SurahInfoProgress> install(String lang) {
    final existing = _active[lang];
    if (existing != null) return existing.stream;
    final controller = StreamController<SurahInfoProgress>.broadcast();
    _active[lang] = controller;
    _cancels.remove(lang);
    _runInstall(lang, controller);
    return controller.stream;
  }

  Future<void> cancelInstall(String lang) async {
    _cancels.add(lang);
  }

  Future<void> _runInstall(
      String lang, StreamController<SurahInfoProgress> controller) async {
    final client = http.Client();
    var done = 0;
    const total = 114;

    void emit({bool failed = false, String? error}) {
      if (controller.isClosed) return;
      controller.add(SurahInfoProgress(
        filesDone: done,
        totalFiles: total,
        failed: failed,
        errorMessage: error,
      ));
    }

    try {
      final dir = await _langDir(lang);
      final pending = <int>[];
      for (var s = 1; s <= 114; s++) {
        final f = File(p.join(dir.path, '$s.json'));
        if (await f.exists() && await f.length() > 0) {
          done++;
        } else {
          pending.add(s);
        }
      }
      emit();

      var index = 0;
      final inFlight = <Future<void>>[];
      Object? firstError;
      StackTrace? firstTrace;
      while (index < pending.length) {
        while (inFlight.length < _maxConcurrent && index < pending.length) {
          final s = pending[index++];
          final fut = () async {
            if (_cancels.contains(lang)) return;
            final url =
                'https://api.quran.com/api/v4/chapters/$s/info?language=${_apiCode(lang)}';
            final res = await client
                .get(Uri.parse(url),
                    headers: const {'User-Agent': 'MyPrayers/1.0'})
                .timeout(const Duration(seconds: 20));
            if (res.statusCode != 200) {
              throw Exception('${res.statusCode}');
            }
            final body = jsonDecode(utf8.decode(res.bodyBytes))
                as Map<String, dynamic>;
            final info = SurahInfo.fromApi(s, lang, body);
            final f = File(p.join(dir.path, '$s.json'));
            await f.writeAsString(jsonEncode(info.toJson()), flush: true);
            done++;
            emit();
          }()
              .catchError((Object e, StackTrace s) {
            firstError ??= e;
            firstTrace ??= s;
          });
          inFlight.add(fut);
          unawaited(fut.whenComplete(() => inFlight.remove(fut)));
        }
        if (inFlight.isNotEmpty) await Future.any(inFlight);
        if (firstError != null) break;
      }
      await Future.wait(inFlight);
      if (firstError != null) {
        Error.throwWithStackTrace(
            firstError!, firstTrace ?? StackTrace.current);
      }
      if (_cancels.contains(lang)) {
        emit(failed: true, error: 'Cancelled');
        return;
      }
      final sentinel = File(p.join(dir.path, '.complete'));
      await sentinel.writeAsString('ok');
      done = total;
      emit();
    } catch (e) {
      emit(failed: true, error: e.toString());
    } finally {
      client.close();
      _active.remove(lang);
      _cancels.remove(lang);
      if (!controller.isClosed) await controller.close();
    }
  }
}

String stripSurahInfoHtml(String html) {
  var t = html;
  t = t.replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n');
  t = t.replaceAll(RegExp(r'</h[1-6]\s*>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
  t = t.replaceAll(RegExp(r'<[^>]+>'), '');
  t = t
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return t;
}
