import '../models/name_of_allah.dart';
import '../../core/i18n/app_l10n.dart';
import 'muslim_db.dart';

class NameOfAllahRepository {
  NameOfAllahRepository._();
  static final NameOfAllahRepository instance = NameOfAllahRepository._();

  Future<List<NameOfAllah>> getNames(String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final db = await MuslimDb.instance.open();
    final rows = await db.rawQuery('''
      SELECT n._id AS id, n.name AS name,
             t.translation AS translation,
             t.transliteration AS transliteration
      FROM name n
      LEFT JOIN name_translation t
        ON t.name_id = n._id AND t.language = ?
      ORDER BY n._id
    ''', [lang]);
    return rows
        .map((r) => NameOfAllah(
              id: r['id'] as int,
              name: (r['name'] ?? '') as String,
              translation: (r['translation'] ?? '') as String,
              transliteration: (r['transliteration'] ?? '') as String,
            ))
        .toList();
  }
}
