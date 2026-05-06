import '../../core/utils/date_utils.dart';
import '../models/location.dart';
import '../models/prayer_time.dart';
import '../../features/prayer_times/calculated_prayer_time.dart';
import 'muslim_db.dart';

class PrayerTimeRepository {
  PrayerTimeRepository._();
  static final PrayerTimeRepository instance = PrayerTimeRepository._();

  Future<PrayerTime?> getPrayerTimes({
    required AppLocation location,
    required DateTime date,
    required PrayerAttribute attribute,
    bool useFixedPrayer = true,
  }) async {
    PrayerTime? prayer;

    if (location.hasFixedPrayerTime && useFixedPrayer) {
      prayer = await _fetchFixed(location, date);
    }

    prayer ??= CalculatedPrayerTime(attribute).getPrayerTimes(location, date);
    if (prayer == null) return null;
    return _applyOffsets(prayer, attribute.offsets);
  }

  Future<List<MapEntry<DateTime, PrayerTime?>>> getMonthPrayerTimes({
    required AppLocation location,
    required int year,
    required int month,
    required PrayerAttribute attribute,
    bool useFixedPrayer = true,
  }) async {
    final dayCount = daysInMonth(year, month);
    final dates = List.generate(
      dayCount,
      (i) => DateTime(year, month, i + 1),
    );
    final useFixed = location.hasFixedPrayerTime && useFixedPrayer;

    if (!useFixed) {
      final calc = CalculatedPrayerTime(attribute);
      return dates.map((d) {
        final raw = calc.getPrayerTimes(location, d);
        return MapEntry(
          d,
          raw == null ? null : _applyOffsets(raw, attribute.offsets),
        );
      }).toList();
    }

    final db = await MuslimDb.instance.open();
    final id = location.prayerDependentId ?? location.id;
    final dbDates = dates.map(toDbDate).toList();
    final placeholders = dbDates.map((_) => '?').join(',');
    final rows = await db.rawQuery(
      'SELECT date, fajr, sunrise, dhuhr, asr, maghrib, isha '
      'FROM prayer_time WHERE location_id = ? AND date IN ($placeholders)',
      [id, ...dbDates],
    );
    final byDate = {for (final r in rows) r['date'] as String: r};
    final calc = CalculatedPrayerTime(attribute);

    return dates.map((d) {
      final row = byDate[toDbDate(d)];
      PrayerTime? prayer;
      if (row != null) {
        prayer = _adjustDst(_rowToPrayer(row, d));
      } else {
        prayer = calc.getPrayerTimes(location, d);
      }
      return MapEntry(
        d,
        prayer == null ? null : _applyOffsets(prayer, attribute.offsets),
      );
    }).toList();
  }

  Future<PrayerTime?> _fetchFixed(AppLocation location, DateTime date) async {
    final db = await MuslimDb.instance.open();
    final id = location.prayerDependentId ?? location.id;
    final rows = await db.rawQuery(
      'SELECT fajr, sunrise, dhuhr, asr, maghrib, isha FROM prayer_time '
      'WHERE location_id = ? AND date = ? LIMIT 1',
      [id, toDbDate(date)],
    );
    if (rows.isEmpty) return null;
    return _adjustDst(_rowToPrayer(rows.first, date));
  }

  PrayerTime _rowToPrayer(Map<String, Object?> r, DateTime date) {
    return PrayerTime(
      fajr: timeStringToDateOn(date, r['fajr'] as String),
      sunrise: timeStringToDateOn(date, r['sunrise'] as String),
      dhuhr: timeStringToDateOn(date, r['dhuhr'] as String),
      asr: timeStringToDateOn(date, r['asr'] as String),
      maghrib: timeStringToDateOn(date, r['maghrib'] as String),
      isha: timeStringToDateOn(date, r['isha'] as String),
    );
  }

  PrayerTime _adjustDst(PrayerTime p) {
    if (!isDst()) return p;
    return p.copyWith(
      fajr: addMinutes(p.fajr, 60),
      sunrise: addMinutes(p.sunrise, 60),
      dhuhr: addMinutes(p.dhuhr, 60),
      asr: addMinutes(p.asr, 60),
      maghrib: addMinutes(p.maghrib, 60),
      isha: addMinutes(p.isha, 60),
    );
  }

  PrayerTime _applyOffsets(PrayerTime p, List<int> offsets) {
    return PrayerTime(
      fajr: addMinutes(p.fajr, offsets[0]),
      sunrise: addMinutes(p.sunrise, offsets[1]),
      dhuhr: addMinutes(p.dhuhr, offsets[2]),
      asr: addMinutes(p.asr, offsets[3]),
      maghrib: addMinutes(p.maghrib, offsets[4]),
      isha: addMinutes(p.isha, offsets[5]),
    );
  }
}
