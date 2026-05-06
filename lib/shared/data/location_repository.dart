import 'package:sqflite/sqflite.dart';
import '../models/location.dart';
import 'muslim_db.dart';

class LocationRepository {
  LocationRepository._();
  static final LocationRepository instance = LocationRepository._();

  Future<Database> get _db => MuslimDb.instance.open();

  static const _select = '''
    SELECT l._id AS id, l.name AS name, l.latitude AS latitude,
           l.longitude AS longitude,
           l.has_fixed_prayer_time AS has_fixed_prayer_time,
           l.prayer_dependent_id AS prayer_dependent_id,
           c.code AS country_code, c.name AS country_name
    FROM location l
    JOIN country c ON c._id = l.country_id
  ''';

  Future<List<AppLocation>> search(String query, {int limit = 25}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final db = await _db;
    final rows = await db.rawQuery(
      '$_select WHERE l.name LIKE ? ORDER BY l.name LIMIT ?',
      ['$q%', limit],
    );
    return rows.map(AppLocation.fromMap).toList();
  }

  Future<AppLocation?> geocode(String countryCode, String locationName) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '$_select WHERE c.code = ? AND l.name LIKE ? LIMIT 1',
      [countryCode, locationName],
    );
    if (rows.isEmpty) return null;
    return AppLocation.fromMap(rows.first);
  }

  Future<AppLocation?> reverseGeocode(double lat, double lng) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '$_select ORDER BY ABS(l.latitude - ?) + ABS(l.longitude - ?) LIMIT 1',
      [lat, lng],
    );
    if (rows.isEmpty) return null;
    return AppLocation.fromMap(rows.first);
  }
}
