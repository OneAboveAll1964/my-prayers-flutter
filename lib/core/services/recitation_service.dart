import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/data/reciter_catalog.dart';

const _maxConcurrentDownloads = 8;
const _storageFolder = 'recitations';
const _totalAyahs = 6236;

class RecitationProgress {
  const RecitationProgress({
    required this.filesDone,
    required this.totalFiles,
    this.failed = false,
    this.errorMessage,
  });

  final int filesDone;
  final int totalFiles;
  final bool failed;
  final String? errorMessage;

  double get fraction =>
      totalFiles == 0 ? 0 : filesDone / totalFiles;

  bool get isComplete =>
      !failed && totalFiles > 0 && filesDone >= totalFiles;
}

class RecitationService {
  RecitationService._();
  static final RecitationService instance = RecitationService._();

  Directory? _root;
  final Map<int, StreamController<RecitationProgress>> _active = {};
  final Set<int> _cancelRequests = {};
  final Map<int, String> _sampleUrlCache = {};
  final Map<int, bool> _installedCache = {};

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    final dir = await getApplicationSupportDirectory();
    final root = Directory(p.join(dir.path, _storageFolder));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    _root = root;
    return root;
  }

  Future<Directory> reciterDir(int reciterId) async {
    final root = await _ensureRoot();
    final dir = Directory(p.join(root.path, '$reciterId'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _verseKey(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '$s$a';
  }

  Future<File> _ayahFile(int reciterId, int surah, int ayah) async {
    final dir = await reciterDir(reciterId);
    return File(p.join(dir.path, '${_verseKey(surah, ayah)}.mp3'));
  }

  Future<File?> cachedFile(int reciterId, int surah, int ayah) async {
    final f = await _ayahFile(reciterId, surah, ayah);
    if (await f.exists() && await f.length() > 0) return f;
    return null;
  }

  Future<bool> isInstalled(int reciterId) async {
    if (_installedCache[reciterId] != null) {
      return _installedCache[reciterId]!;
    }
    final dir = await reciterDir(reciterId);
    final sentinel = File(p.join(dir.path, '.complete'));
    final ok = await sentinel.exists();
    _installedCache[reciterId] = ok;
    return ok;
  }

  Future<int> installedAyahCount(int reciterId) async {
    final dir = await reciterDir(reciterId);
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.mp3')) count++;
    }
    return count;
  }

  Future<int> diskUsageBytes(int reciterId) async {
    final dir = await reciterDir(reciterId);
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<String> sampleUrl(int reciterId) async {
    if (_sampleUrlCache[reciterId] != null) {
      return _sampleUrlCache[reciterId]!;
    }
    final res = await http
        .get(
          Uri.parse(
              'https://api.quran.com/api/v4/quran/recitations/$reciterId?chapter_number=1'),
          headers: const {'User-Agent': 'MyPrayers/1.0'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('sample ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final files = (body['audio_files'] as List).cast<Map<String, dynamic>>();
    final first = files.firstWhere((f) => f['verse_key'] == '1:1',
        orElse: () => files.first);
    final url = resolveAudioUrl(first['url'] as String);
    _sampleUrlCache[reciterId] = url;
    return url;
  }

  Future<List<_AyahFile>> _fetchAllUrls(int reciterId) async {
    final res = await http
        .get(
          Uri.parse(
              'https://api.quran.com/api/v4/quran/recitations/$reciterId'),
          headers: const {'User-Agent': 'MyPrayers/1.0'},
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('catalog ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final files = (body['audio_files'] as List).cast<Map<String, dynamic>>();
    return files.map((f) {
      final key = f['verse_key'] as String;
      final parts = key.split(':');
      return _AyahFile(
        surah: int.parse(parts[0]),
        ayah: int.parse(parts[1]),
        url: resolveAudioUrl(f['url'] as String),
      );
    }).toList();
  }

  Stream<RecitationProgress> install(int reciterId) {
    final existing = _active[reciterId];
    if (existing != null) return existing.stream;
    final controller = StreamController<RecitationProgress>.broadcast();
    _active[reciterId] = controller;
    _cancelRequests.remove(reciterId);
    _runInstall(reciterId, controller);
    return controller.stream;
  }

  bool isInstalling(int reciterId) => _active.containsKey(reciterId);

  Future<void> cancelInstall(int reciterId) async {
    _cancelRequests.add(reciterId);
  }

  Future<void> _runInstall(
      int reciterId, StreamController<RecitationProgress> controller) async {
    final client = http.Client();
    var done = 0;
    var total = _totalAyahs;
    var emitted = false;

    void emit({bool failed = false, String? error}) {
      if (controller.isClosed) return;
      controller.add(RecitationProgress(
        filesDone: done,
        totalFiles: total,
        failed: failed,
        errorMessage: error,
      ));
      emitted = true;
    }

    try {
      emit();
      final dir = await reciterDir(reciterId);
      final allFiles = await _fetchAllUrls(reciterId);
      total = allFiles.length;

      final pending = <_AyahFile>[];
      for (final f in allFiles) {
        final local = File(p.join(dir.path, '${_verseKey(f.surah, f.ayah)}.mp3'));
        if (await local.exists() && await local.length() > 0) {
          done++;
        } else {
          pending.add(f);
        }
      }
      emit();

      await _runConcurrent(
        items: pending,
        maxConcurrent: _maxConcurrentDownloads,
        task: (item) async {
          if (_cancelRequests.contains(reciterId)) return;
          final file = File(p.join(dir.path, '${_verseKey(item.surah, item.ayah)}.mp3'));
          await _downloadOne(client, item.url, file);
          done++;
          emit();
        },
      );

      if (_cancelRequests.contains(reciterId)) {
        emit(failed: true, error: 'Cancelled');
        return;
      }

      final sentinel = File(p.join(dir.path, '.complete'));
      await sentinel.writeAsString('ok');
      _installedCache[reciterId] = true;
      done = total;
      emit();
    } catch (e) {
      emit(failed: true, error: e.toString());
    } finally {
      client.close();
      _active.remove(reciterId);
      _cancelRequests.remove(reciterId);
      if (!emitted) emit();
      if (!controller.isClosed) await controller.close();
    }
  }

  Future<File> downloadSingleAyah(int reciterId, int surah, int ayah) async {
    final cached = await cachedFile(reciterId, surah, ayah);
    if (cached != null) return cached;
    final res = await http
        .get(
          Uri.parse(
              'https://api.quran.com/api/v4/quran/recitations/$reciterId?chapter_number=$surah'),
          headers: const {'User-Agent': 'MyPrayers/1.0'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('ayah ${res.statusCode}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final files = (body['audio_files'] as List).cast<Map<String, dynamic>>();
    final key = '$surah:$ayah';
    final entry = files.firstWhere((f) => f['verse_key'] == key,
        orElse: () => throw Exception('ayah not found'));
    final url = resolveAudioUrl(entry['url'] as String);
    final file = await _ayahFile(reciterId, surah, ayah);
    final client = http.Client();
    try {
      await _downloadOne(client, url, file);
    } finally {
      client.close();
    }
    return file;
  }

  Future<void> uninstall(int reciterId) async {
    final dir = await reciterDir(reciterId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _installedCache[reciterId] = false;
  }

  Future<void> _downloadOne(http.Client client, String url, File dest) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await client
            .get(Uri.parse(url),
                headers: const {'User-Agent': 'MyPrayers/1.0'})
            .timeout(const Duration(seconds: 30));
        if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
          throw Exception('${res.statusCode}');
        }
        await dest.writeAsBytes(res.bodyBytes, flush: true);
        return;
      } catch (e) {
        if (attempt == 2) rethrow;
        await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
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

class _AyahFile {
  const _AyahFile({required this.surah, required this.ayah, required this.url});
  final int surah;
  final int ayah;
  final String url;
}
