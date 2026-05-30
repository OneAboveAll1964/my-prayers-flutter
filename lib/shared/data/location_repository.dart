import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../models/location.dart';
import 'muslim_db.dart';

enum DetectError {
  serviceOff,
  denied,
  deniedForever,
  timeout,
  notFound,
  unknown,
}

void showLocationDetectError(BuildContext context, DetectError error) {
  final l10n = AppL10n.of(context);
  final palette = context.palette;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          l10n.t('location.error.${error.name}'),
          style: TextStyle(color: palette.accentOn),
        ),
        backgroundColor: palette.text,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
}

class DetectResult {
  const DetectResult.success(this.location) : error = null;
  const DetectResult.failure(this.error) : location = null;
  final AppLocation? location;
  final DetectError? error;
  bool get ok => location != null;
}

class LocationRepository {
  LocationRepository._();
  static final LocationRepository instance = LocationRepository._();

  Future<Database> get _db => MuslimDb.instance.open();

  Future<DetectResult> detectCurrentLocation({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const DetectResult.failure(DetectError.serviceOff);
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return const DetectResult.failure(DetectError.deniedForever);
      }
      if (perm == LocationPermission.denied) {
        return const DetectResult.failure(DetectError.denied);
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: timeout,
          ),
        ).timeout(timeout + const Duration(seconds: 2));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      pos ??= await Geolocator.getLastKnownPosition();
      if (pos == null) {
        return const DetectResult.failure(DetectError.timeout);
      }

      final found = await reverseGeocode(pos.latitude, pos.longitude);
      if (found == null) {
        return const DetectResult.failure(DetectError.notFound);
      }
      return DetectResult.success(found);
    } catch (_) {
      return const DetectResult.failure(DetectError.unknown);
    }
  }

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
