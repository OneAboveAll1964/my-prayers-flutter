import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _totalPages = 604;
const _fontUrlPattern =
    'https://static.qurancdn.com/fonts/quran/hafs/v2/ttf/p{n}.ttf';
const _pageDataUrlPattern =
    'https://api.qurancdn.com/api/qdc/verses/by_page/{n}'
    '?words=true&word_fields=line_number,code_v2,char_type_name'
    '&fields=verse_key';
const _maxConcurrentDownloads = 8;
const _storageFolder = 'mushaf_v2';
const _fontFamilyPrefix = 'QCFv2_p';
const _codeField = 'code_v2';

class MushafInstallProgress {
  const MushafInstallProgress({
    required this.fontsDone,
    required this.dataDone,
    required this.totalFonts,
    required this.totalData,
    this.failed = false,
    this.errorMessage,
  });

  final int fontsDone;
  final int dataDone;
  final int totalFonts;
  final int totalData;
  final bool failed;
  final String? errorMessage;

  double get fraction {
    final total = totalFonts + totalData;
    if (total == 0) return 0;
    return (fontsDone + dataDone) / total;
  }

  bool get isComplete =>
      !failed && fontsDone == totalFonts && dataDone == totalData;
}

class MushafLineWord {
  MushafLineWord({
    required this.code,
    required this.verseKey,
    required this.isAyahEnd,
  });

  final String code;
  final String verseKey;
  final bool isAyahEnd;

  factory MushafLineWord.fromJson(Map<String, dynamic> j) {
    return MushafLineWord(
      code: j['c'] as String,
      verseKey: j['k'] as String,
      isAyahEnd: (j['e'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'c': code,
        'k': verseKey,
        'e': isAyahEnd ? 1 : 0,
      };
}

class MushafLine {
  MushafLine({required this.lineNumber, required this.words});
  final int lineNumber;
  final List<MushafLineWord> words;

  factory MushafLine.fromJson(Map<String, dynamic> j) {
    return MushafLine(
      lineNumber: j['n'] as int,
      words: (j['w'] as List)
          .map((e) => MushafLineWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'n': lineNumber,
        'w': words.map((w) => w.toJson()).toList(),
      };

  String get codes => words.map((w) => w.code).join(' ');
}

class MushafPageData {
  MushafPageData({required this.pageNumber, required this.lines});
  final int pageNumber;
  final List<MushafLine> lines;

  factory MushafPageData.fromJson(Map<String, dynamic> j) {
    return MushafPageData(
      pageNumber: j['p'] as int,
      lines: (j['l'] as List)
          .map((e) => MushafLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'p': pageNumber,
        'l': lines.map((l) => l.toJson()).toList(),
      };
}

class MushafAssetService {
  MushafAssetService._();
  static final MushafAssetService instance = MushafAssetService._();

  Directory? _root;
  bool? _installed;
  StreamController<MushafInstallProgress>? _activeController;
  bool _cancelled = false;
  final Map<int, Future<String>> _loadedFontFutures = {};
  final Map<int, String> _loadedFontFamilies = {};
  final Map<int, MushafPageData> _pageCache = {};

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    final dir = await getApplicationSupportDirectory();
    final root = Directory(p.join(dir.path, _storageFolder));
    await Directory(p.join(root.path, 'fonts')).create(recursive: true);
    await Directory(p.join(root.path, 'pages')).create(recursive: true);
    _root = root;
    return root;
  }

  Future<bool> isInstalled() async {
    if (_installed != null) return _installed!;
    final root = await _ensureRoot();
    final sentinel = File(p.join(root.path, '.complete'));
    _installed = await sentinel.exists();
    return _installed!;
  }

  Future<int> installedFontsCount() async {
    final root = await _ensureRoot();
    final fonts = Directory(p.join(root.path, 'fonts'));
    if (!await fonts.exists()) return 0;
    var count = 0;
    await for (final e in fonts.list()) {
      if (e is File && e.path.endsWith('.ttf')) count++;
    }
    return count;
  }

  Future<void> cancelInstall() async {
    _cancelled = true;
  }

  Stream<MushafInstallProgress> install() {
    if (_activeController != null) return _activeController!.stream;
    final controller = StreamController<MushafInstallProgress>.broadcast();
    _activeController = controller;
    _cancelled = false;
    _runInstall(controller);
    return controller.stream;
  }

  Future<void> _runInstall(
      StreamController<MushafInstallProgress> controller) async {
    try {
      final root = await _ensureRoot();
      final fontDir = Directory(p.join(root.path, 'fonts'));
      final pageDir = Directory(p.join(root.path, 'pages'));

      var fontsDone = 0;
      var dataDone = 0;

      void emit() {
        if (controller.isClosed) return;
        controller.add(MushafInstallProgress(
          fontsDone: fontsDone,
          dataDone: dataDone,
          totalFonts: _totalPages,
          totalData: _totalPages,
        ));
      }

      emit();

      final pendingFonts = <int>[];
      final pendingData = <int>[];
      for (var i = 1; i <= _totalPages; i++) {
        final fontFile = File(p.join(fontDir.path, 'p$i.ttf'));
        if (await fontFile.exists() && await fontFile.length() > 0) {
          fontsDone++;
        } else {
          pendingFonts.add(i);
        }
        final dataFile = File(p.join(pageDir.path, '$i.json'));
        if (await dataFile.exists() && await dataFile.length() > 0) {
          dataDone++;
        } else {
          pendingData.add(i);
        }
      }
      emit();

      final client = http.Client();
      try {
        await _runConcurrent(
          items: pendingFonts,
          maxConcurrent: _maxConcurrentDownloads,
          task: (page) async {
            if (_cancelled) return;
            await _downloadFont(client, page, fontDir);
            fontsDone++;
            emit();
          },
        );

        if (_cancelled) {
          if (!controller.isClosed) {
            controller.add(MushafInstallProgress(
              fontsDone: fontsDone,
              dataDone: dataDone,
              totalFonts: _totalPages,
              totalData: _totalPages,
              failed: true,
              errorMessage: 'Cancelled',
            ));
            await controller.close();
          }
          return;
        }

        await _runConcurrent(
          items: pendingData,
          maxConcurrent: _maxConcurrentDownloads,
          task: (page) async {
            if (_cancelled) return;
            await _downloadPageData(client, page, pageDir);
            dataDone++;
            emit();
          },
        );
      } finally {
        client.close();
      }

      if (_cancelled) {
        if (!controller.isClosed) {
          controller.add(MushafInstallProgress(
            fontsDone: fontsDone,
            dataDone: dataDone,
            totalFonts: _totalPages,
            totalData: _totalPages,
            failed: true,
            errorMessage: 'Cancelled',
          ));
          await controller.close();
        }
        return;
      }

      final sentinel = File(p.join(root.path, '.complete'));
      await sentinel.writeAsString('ok');
      _installed = true;
      emit();
    } catch (e) {
      if (!controller.isClosed) {
        controller.add(MushafInstallProgress(
          fontsDone: 0,
          dataDone: 0,
          totalFonts: _totalPages,
          totalData: _totalPages,
          failed: true,
          errorMessage: e.toString(),
        ));
      }
    } finally {
      _activeController = null;
      if (!controller.isClosed) await controller.close();
    }
  }

  Future<void> _runConcurrent({
    required List<int> items,
    required int maxConcurrent,
    required Future<void> Function(int) task,
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

  Future<T> _retry<T>(Future<T> Function() fn, {int attempts = 3}) async {
    Object? lastErr;
    for (var i = 0; i < attempts; i++) {
      try {
        return await fn();
      } catch (e) {
        lastErr = e;
        if (i < attempts - 1) {
          await Future.delayed(Duration(milliseconds: 250 * (i + 1)));
        }
      }
    }
    throw lastErr ?? Exception('failed');
  }

  Future<void> _downloadFont(
      http.Client client, int page, Directory fontDir) async {
    await _retry(() async {
      final url = _fontUrlPattern.replaceAll('{n}', '$page');
      final response = await client
          .get(
            Uri.parse(url),
            headers: const {'User-Agent': 'MyPrayers/1.0'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Font p$page (${response.statusCode})');
      }
      final file = File(p.join(fontDir.path, 'p$page.ttf'));
      await file.writeAsBytes(response.bodyBytes, flush: true);
    });
  }

  Future<void> _downloadPageData(
      http.Client client, int page, Directory pageDir) async {
    await _retry(() => _doDownloadPageData(client, page, pageDir));
  }

  Future<void> _doDownloadPageData(
      http.Client client, int page, Directory pageDir) async {
    final url = _pageDataUrlPattern.replaceAll('{n}', '$page');
    final response = await client
        .get(
          Uri.parse(url),
          headers: const {'User-Agent': 'MyPrayers/1.0'},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Page $page (${response.statusCode})');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final verses = body['verses'] as List;
    final linesByNumber = <int, List<MushafLineWord>>{};
    for (final verse in verses) {
      final v = verse as Map<String, dynamic>;
      final verseKey = v['verse_key'] as String;
      final words = v['words'] as List;
      for (final word in words) {
        final w = word as Map<String, dynamic>;
        final lineNumber = w['line_number'] as int;
        final code = (w[_codeField] ?? '') as String;
        if (code.isEmpty) continue;
        final type = w['char_type_name'] as String?;
        final isEnd = type == 'end';
        linesByNumber
            .putIfAbsent(lineNumber, () => <MushafLineWord>[])
            .add(MushafLineWord(
              code: code,
              verseKey: verseKey,
              isAyahEnd: isEnd,
            ));
      }
    }
    final sortedLines = linesByNumber.keys.toList()..sort();
    final pageData = MushafPageData(
      pageNumber: page,
      lines: [
        for (final ln in sortedLines)
          MushafLine(lineNumber: ln, words: linesByNumber[ln]!),
      ],
    );
    final file = File(p.join(pageDir.path, '$page.json'));
    await file.writeAsString(jsonEncode(pageData.toJson()), flush: true);
  }

  Future<String> loadFontForPage(int page) async {
    if (_loadedFontFamilies.containsKey(page)) {
      return _loadedFontFamilies[page]!;
    }
    if (_loadedFontFutures.containsKey(page)) {
      return _loadedFontFutures[page]!;
    }
    final future = _doLoadFont(page);
    _loadedFontFutures[page] = future;
    final family = await future;
    _loadedFontFamilies[page] = family;
    return family;
  }

  Future<String> _doLoadFont(int page) async {
    final root = await _ensureRoot();
    final fontDir = Directory(p.join(root.path, 'fonts'));
    final file = File(p.join(fontDir.path, 'p$page.ttf'));
    if (!await file.exists() || await file.length() == 0) {
      final client = http.Client();
      try {
        await _downloadFont(client, page, fontDir);
      } finally {
        client.close();
      }
    }
    final family = '$_fontFamilyPrefix$page';
    final loader = FontLoader(family);
    loader.addFont(_readFontBytes(file));
    await loader.load();
    return family;
  }

  Future<ByteData> _readFontBytes(File file) async {
    final bytes = await file.readAsBytes();
    return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }

  Future<MushafPageData> getPageData(int page) async {
    if (_pageCache.containsKey(page)) return _pageCache[page]!;
    final root = await _ensureRoot();
    final pageDir = Directory(p.join(root.path, 'pages'));
    final file = File(p.join(pageDir.path, '$page.json'));
    if (!await file.exists() || await file.length() == 0) {
      final client = http.Client();
      try {
        await _downloadPageData(client, page, pageDir);
      } finally {
        client.close();
      }
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final data = MushafPageData.fromJson(json);
    _pageCache[page] = data;
    return data;
  }

  Future<void> uninstall() async {
    final root = await _ensureRoot();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    _installed = false;
    _loadedFontFutures.clear();
    _loadedFontFamilies.clear();
    _pageCache.clear();
  }
}
