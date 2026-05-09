import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class QuranDb {
  QuranDb._();
  static final QuranDb instance = QuranDb._();

  Database? _db;
  Future<Database>? _opening;

  static const _assetPath = 'assets/db/quran.db';
  static const _fileName = 'quran.db';

  Future<Database> open() async {
    if (_db != null) return _db!;
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, _fileName);
    final file = File(dbPath);
    final bundled = await rootBundle.load(_assetPath);
    final bundledBytes = bundled.buffer
        .asUint8List(bundled.offsetInBytes, bundled.lengthInBytes);
    if (!await file.exists() || await file.length() != bundledBytes.length) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bundledBytes, flush: true);
    }
    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }
}
