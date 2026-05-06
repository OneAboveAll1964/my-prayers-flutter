import '../models/azkar.dart';
import '../../core/i18n/app_l10n.dart';
import 'muslim_db.dart';

class HisnulMuslimRepository {
  HisnulMuslimRepository._();
  static final HisnulMuslimRepository instance = HisnulMuslimRepository._();

  Future<List<AzkarCategory>> getCategories(String langCode) async {
    final lang = resolveDbLanguage(langCode);
    final db = await MuslimDb.instance.open();
    final rows = await db.rawQuery('''
      SELECT category_id, category_name
      FROM azkar_category_translation
      WHERE language = ?
      ORDER BY category_id
    ''', [lang]);
    return rows
        .map((r) => AzkarCategory(
              id: r['category_id'] as int,
              name: (r['category_name'] ?? '') as String,
            ))
        .toList();
  }

  Future<List<AzkarChapter>> getChapters({
    required String langCode,
    int? categoryId,
  }) async {
    final lang = resolveDbLanguage(langCode);
    final db = await MuslimDb.instance.open();
    final args = <Object?>[lang];
    var sql = '''
      SELECT t.chapter_id AS id,
             t.chapter_name AS name,
             c.category_id AS category_id,
             ct.category_name AS category_name
      FROM azkar_chapter_translation t
      JOIN azkar_chapter c ON c._id = t.chapter_id
      LEFT JOIN azkar_category_translation ct
        ON ct.category_id = c.category_id AND ct.language = t.language
      WHERE t.language = ?
    ''';
    if (categoryId != null && categoryId != 1) {
      sql += ' AND c.category_id = ?';
      args.add(categoryId);
    }
    sql += ' ORDER BY t.chapter_id';
    final rows = await db.rawQuery(sql, args);
    return rows
        .map((r) => AzkarChapter(
              id: r['id'] as int,
              categoryId: r['category_id'] as int,
              categoryName: (r['category_name'] ?? '') as String,
              name: (r['name'] ?? '') as String,
            ))
        .toList();
  }

  Future<List<AzkarChapter>> searchChapters({
    required String langCode,
    required String query,
  }) async {
    final lang = resolveDbLanguage(langCode);
    final q = query.trim();
    if (q.isEmpty) return [];
    final db = await MuslimDb.instance.open();
    final rows = await db.rawQuery('''
      SELECT t.chapter_id AS id, t.chapter_name AS name, c.category_id AS category_id
      FROM azkar_chapter_translation t
      JOIN azkar_chapter c ON c._id = t.chapter_id
      WHERE t.language = ? AND t.chapter_name LIKE ?
      ORDER BY t.chapter_id
      LIMIT 50
    ''', [lang, '%$q%']);
    return rows
        .map((r) => AzkarChapter(
              id: r['id'] as int,
              categoryId: r['category_id'] as int,
              categoryName: '',
              name: (r['name'] ?? '') as String,
            ))
        .toList();
  }

  Future<List<AzkarItem>> getItems({
    required String langCode,
    required int chapterId,
  }) async {
    final lang = resolveDbLanguage(langCode);
    final db = await MuslimDb.instance.open();
    final rows = await db.rawQuery('''
      SELECT i._id AS id, i.chapter_id AS chapter_id,
             i.item AS item, i.transliteration AS transliteration,
             i.count AS count,
             t.top_note AS top_note, t.item_translation AS item_translation,
             t.bottom_note AS bottom_note, t.reference AS reference
      FROM azkar_item i
      LEFT JOIN azkar_item_translation t
        ON t.item_id = i._id AND t.language = ?
      WHERE i.chapter_id = ?
      ORDER BY i._id
    ''', [lang, chapterId]);
    return rows
        .map((r) => AzkarItem(
              id: r['id'] as int,
              chapterId: r['chapter_id'] as int,
              item: r['item'] as String?,
              transliteration: r['transliteration'] as String?,
              count: r['count'] as int?,
              topNote: r['top_note'] as String?,
              translation: r['item_translation'] as String?,
              bottomNote: r['bottom_note'] as String?,
              reference: (r['reference'] ?? '') as String,
            ))
        .toList();
  }
}
