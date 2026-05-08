import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _fontUrl =
    'https://static-cdn.tarteel.ai/qul/fonts/surah-names/v2/surah-name-v2.ttf';
const _fontFileName = 'surah-name-v2.ttf';
const _fontFamily = 'SurahNameV2';

class SurahNameFontService {
  SurahNameFontService._();
  static final SurahNameFontService instance = SurahNameFontService._();

  bool _loadedIntoSkia = false;
  Future<void>? _loading;
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  String get fontFamily => _fontFamily;

  String surahGlyph(int surahNumber) =>
      'surah${surahNumber.toString().padLeft(3, '0')}';

  Future<File> _file() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'fonts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(p.join(dir.path, _fontFileName));
  }

  Future<bool> isInstalled() async {
    final f = await _file();
    return await f.exists() && await f.length() > 0;
  }

  Future<void> install() async {
    final f = await _file();
    if (!await f.exists() || await f.length() == 0) {
      final res = await http
          .get(Uri.parse(_fontUrl),
              headers: const {'User-Agent': 'MyPrayers/1.0'})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        throw Exception('font ${res.statusCode}');
      }
      await f.writeAsBytes(res.bodyBytes, flush: true);
    }
    _loadedIntoSkia = false;
    await _ensureLoaded();
    ready.value = true;
  }

  Future<void> uninstall() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
    _loadedIntoSkia = false;
    ready.value = false;
  }

  Future<bool> loadIfInstalled() async {
    if (_loadedIntoSkia) {
      ready.value = true;
      return true;
    }
    if (await isInstalled()) {
      await _ensureLoaded();
      ready.value = true;
      return true;
    }
    ready.value = false;
    return false;
  }

  Future<void> _ensureLoaded() {
    return _loading ??= _doLoad();
  }

  Future<void> _doLoad() async {
    try {
      final f = await _file();
      if (!await f.exists() || await f.length() == 0) return;
      final loader = FontLoader(_fontFamily);
      loader.addFont(_readBytes(f));
      await loader.load();
      _loadedIntoSkia = true;
    } finally {
      _loading = null;
    }
  }

  Future<ByteData> _readBytes(File f) async {
    final bytes = await f.readAsBytes();
    return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }
}
