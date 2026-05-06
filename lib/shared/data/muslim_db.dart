import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MuslimDb {
  MuslimDb._();
  static final MuslimDb instance = MuslimDb._();

  Database? _db;
  Future<Database>? _opening;

  static const _assetPath = 'assets/db/muslim_db_v3.0.0.db';
  static const _fileName = 'muslim_db_v3.0.0.db';

  Future<Database> open() async {
    if (_db != null) return _db!;
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, _fileName);
    final file = File(dbPath);
    if (!await file.exists()) {
      final bytes = await rootBundle.load(_assetPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _opening = null;
  }
}
