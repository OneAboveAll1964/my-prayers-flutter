import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _storageFolder = 'tafsirs';
const _totalAyahs = 6236;
const _maxConcurrent = 6;

class TafsirProgress {
  const TafsirProgress({
    required this.filesDone,
    required this.totalFiles,
    this.bytesDone = 0,
    this.failed = false,
    this.errorMessage,
  });

  final int filesDone;
  final int totalFiles;
  final int bytesDone;
  final bool failed;
  final String? errorMessage;

  double get fraction =>
      totalFiles == 0 ? 0 : filesDone / totalFiles;

  bool get isComplete =>
      !failed && totalFiles > 0 && filesDone >= totalFiles;
}

class TafsirService {
  TafsirService._();
  static final TafsirService instance = TafsirService._();

  Directory? _root;
  final Map<int, StreamController<TafsirProgress>> _active = {};
  final Set<int> _cancelRequests = {};
  final Map<int, bool> _installedCache = {};
  final Map<String, String> _memCache = {};

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    final dir = await getApplicationSupportDirectory();
    final root = Directory(p.join(dir.path, _storageFolder));
    if (!await root.exists()) await root.create(recursive: true);
    _root = root;
    return root;
  }

  Future<Directory> tafsirDir(int tafsirId) async {
    final root = await _ensureRoot();
    final dir = Directory(p.join(root.path, '$tafsirId'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _verseFileName(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '$s$a.txt';
  }

  Future<File> _ayahFile(int tafsirId, int surah, int ayah) async {
    final dir = await tafsirDir(tafsirId);
    return File(p.join(dir.path, _verseFileName(surah, ayah)));
  }

  Future<bool> isInstalled(int tafsirId) async {
    if (_installedCache[tafsirId] != null) return _installedCache[tafsirId]!;
    final dir = await tafsirDir(tafsirId);
    final sentinel = File(p.join(dir.path, '.complete'));
    final ok = await sentinel.exists();
    _installedCache[tafsirId] = ok;
    return ok;
  }

  Future<String?> cachedText(int tafsirId, int surah, int ayah) async {
    final memKey = '$tafsirId:$surah:$ayah';
    if (_memCache.containsKey(memKey)) return _memCache[memKey];
    final f = await _ayahFile(tafsirId, surah, ayah);
    if (await f.exists() && await f.length() > 0) {
      final text = await f.readAsString();
      _memCache[memKey] = text;
      return text;
    }
    return null;
  }

  Future<String> fetchAyahText(int tafsirId, int surah, int ayah) async {
    final cached = await cachedText(tafsirId, surah, ayah);
    if (cached != null) return cached;
    final url =
        'https://api.qurancdn.com/api/qdc/tafsirs/$tafsirId/by_ayah/$surah:$ayah';
    final res = await http
        .get(Uri.parse(url),
            headers: const {'User-Agent': 'MyPrayers/1.0'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('tafsir ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final tafsir = body['tafsir'] as Map<String, dynamic>?;
    final text = (tafsir?['text'] ?? '').toString();
    final file = await _ayahFile(tafsirId, surah, ayah);
    await file.writeAsString(text, flush: true);
    _memCache['$tafsirId:$surah:$ayah'] = text;
    return text;
  }

  Stream<TafsirProgress> install(int tafsirId) {
    final existing = _active[tafsirId];
    if (existing != null) return existing.stream;
    final controller = StreamController<TafsirProgress>.broadcast();
    _active[tafsirId] = controller;
    _cancelRequests.remove(tafsirId);
    _runInstall(tafsirId, controller);
    return controller.stream;
  }

  bool isInstalling(int tafsirId) => _active.containsKey(tafsirId);

  Future<void> cancelInstall(int tafsirId) async {
    _cancelRequests.add(tafsirId);
  }

  Future<void> _runInstall(
      int tafsirId, StreamController<TafsirProgress> controller) async {
    final client = http.Client();
    var done = 0;
    final total = _totalAyahs;
    var bytesDone = 0;

    void emit({bool failed = false, String? error}) {
      if (controller.isClosed) return;
      controller.add(TafsirProgress(
        filesDone: done,
        totalFiles: total,
        bytesDone: bytesDone,
        failed: failed,
        errorMessage: error,
      ));
    }

    DateTime lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
    void maybeEmit({bool force = false}) {
      final now = DateTime.now();
      if (!force && now.difference(lastEmit).inMilliseconds < 200) return;
      lastEmit = now;
      emit();
    }

    try {
      emit();
      final dir = await tafsirDir(tafsirId);
      final pending = <(int, int)>[];
      for (var s = 1; s <= 114; s++) {
        final ayahCount = _ayahCounts[s - 1];
        for (var a = 1; a <= ayahCount; a++) {
          final f = File(p.join(dir.path, _verseFileName(s, a)));
          if (await f.exists() && await f.length() > 0) {
            done++;
            bytesDone += await f.length();
          } else {
            pending.add((s, a));
          }
        }
      }
      emit();

      await _runConcurrent(
        items: pending,
        maxConcurrent: _maxConcurrent,
        task: (tuple) async {
          if (_cancelRequests.contains(tafsirId)) return;
          final (s, a) = tuple;
          final url =
              'https://api.qurancdn.com/api/qdc/tafsirs/$tafsirId/by_ayah/$s:$a';
          final res = await client
              .get(Uri.parse(url),
                  headers: const {'User-Agent': 'MyPrayers/1.0'})
              .timeout(const Duration(seconds: 20));
          if (res.statusCode != 200) {
            throw Exception('${res.statusCode}');
          }
          final body =
              jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final tafsir = body['tafsir'] as Map<String, dynamic>?;
          final text = (tafsir?['text'] ?? '').toString();
          final f = File(p.join(dir.path, _verseFileName(s, a)));
          await f.writeAsString(text, flush: true);
          done++;
          bytesDone += text.length;
          maybeEmit();
        },
      );
      maybeEmit(force: true);

      if (_cancelRequests.contains(tafsirId)) {
        emit(failed: true, error: 'Cancelled');
        return;
      }

      final sentinel = File(p.join(dir.path, '.complete'));
      await sentinel.writeAsString('ok');
      _installedCache[tafsirId] = true;
      done = total;
      emit();
    } catch (e) {
      emit(failed: true, error: e.toString());
    } finally {
      client.close();
      _active.remove(tafsirId);
      _cancelRequests.remove(tafsirId);
      if (!controller.isClosed) await controller.close();
    }
  }

  Future<void> uninstall(int tafsirId) async {
    final dir = await tafsirDir(tafsirId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _installedCache[tafsirId] = false;
    _memCache.removeWhere((k, _) => k.startsWith('$tafsirId:'));
  }

  Future<void> _runConcurrent<T>({
    required List<T> items,
    required int maxConcurrent,
    required Future<void> Function(T) task,
  }) async {
    var index = 0;
    final inFlight = <Future<void>>[];
    Object? firstError;
    StackTrace? firstTrace;
    while (index < items.length) {
      while (inFlight.length < maxConcurrent && index < items.length) {
        final item = items[index++];
        final fut = task(item).catchError((Object e, StackTrace s) {
          firstError ??= e;
          firstTrace ??= s;
        });
        inFlight.add(fut);
        unawaited(fut.whenComplete(() => inFlight.remove(fut)));
      }
      if (inFlight.isNotEmpty) {
        await Future.any(inFlight);
      }
      if (firstError != null) break;
    }
    await Future.wait(inFlight);
    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstTrace ?? StackTrace.current);
    }
  }
}

const _ayahCounts = <int>[
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
  111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
  54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
  49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
  44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
  26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
  6, 3, 5, 4, 5, 6,
];

String stripTafsirHtml(String html) {
  var text = html;
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return text;
}
