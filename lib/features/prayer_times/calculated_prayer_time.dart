import 'dart:math' as math;
import '../../core/utils/date_utils.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/models/location.dart';

const _invalidTime = '-----';
const _numIterations = 1;

class CalculatedPrayerTime {
  CalculatedPrayerTime(this.attribute);

  final PrayerAttribute attribute;
  late final Map<CalculationMethod, List<double>> _methodParams =
      _getMethodParams(attribute.customMethod);

  double _lat = 0;
  double _lng = 0;
  double _timeZone = 0;
  double _jDate = 0;

  static Map<CalculationMethod, List<double>> _getMethodParams(
      CustomMethod custom) {
    return {
      CalculationMethod.makkah: [18.5, 1.0, 0.0, 1.0, 90.0],
      CalculationMethod.mwl: [18.0, 1.0, 0.0, 0.0, 17.0],
      CalculationMethod.isna: [15.0, 1.0, 0.0, 0.0, 15.0],
      CalculationMethod.karachi: [18.0, 1.0, 0.0, 0.0, 18.0],
      CalculationMethod.egypt: [19.5, 1.0, 0.0, 0.0, 17.5],
      CalculationMethod.jafari: [16.0, 0.0, 4.0, 0.0, 14.0],
      CalculationMethod.tehran: [17.7, 0.0, 4.5, 0.0, 14.0],
      CalculationMethod.custom: [custom.fajrAngle, 1.0, 0.0, 0.0, custom.ishaAngle],
    };
  }

  double _fixAngle(double a) {
    a -= 360 * (a / 360).floor();
    return a < 0 ? a + 360 : a;
  }

  double _fixHour(double a) {
    a -= 24 * (a / 24).floor();
    return a < 0 ? a + 24 : a;
  }

  double _rad(double d) => d * math.pi / 180;
  double _deg(double r) => r * 180 / math.pi;
  double _dSin(double d) => math.sin(_rad(d));
  double _dCos(double d) => math.cos(_rad(d));
  double _dTan(double d) => math.tan(_rad(d));
  double _dArcSin(double x) => _deg(math.asin(x));
  double _dArcCos(double x) => _deg(math.acos(x));
  double _dArcTan2(double y, double x) => _deg(math.atan2(y, x));
  double _dArcCot(double x) => _deg(math.atan2(1, x));

  double _julianDate(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  List<double> _sunPosition(double jd) {
    final d1 = jd - 2451545;
    final g = _fixAngle(357.529 + 0.98560028 * d1);
    final q = _fixAngle(280.459 + 0.98564736 * d1);
    final l = _fixAngle(q + 1.915 * _dSin(g) + 0.02 * _dSin(2 * g));
    final e = 23.439 - 0.00000036 * d1;
    final d2 = _dArcSin(_dSin(e) * _dSin(l));
    var ra = _dArcTan2(_dCos(e) * _dSin(l), _dCos(l)) / 15;
    ra = _fixHour(ra);
    return [d2, q / 15 - ra];
  }

  double _equationOfTime(double jd) => _sunPosition(jd)[1];
  double _sunDeclination(double jd) => _sunPosition(jd)[0];

  double _computeMidDay(double t) {
    final eqt = _equationOfTime(_jDate + t);
    return _fixHour(12 - eqt);
  }

  double _computeTime(double g, double t) {
    final d = _sunDeclination(_jDate + t);
    final z = _computeMidDay(t);
    final beg = -_dSin(g) - _dSin(d) * _dSin(_lat);
    final mid = _dCos(d) * _dCos(_lat);
    final v = _dArcCos(beg / mid) / 15;
    return z + (g > 90 ? -v : v);
  }

  double _computeAsr(double step, double t) {
    final d = _sunDeclination(_jDate + t);
    final g = -_dArcCot(step + _dTan((_lat - d).abs()));
    return _computeTime(g, t);
  }

  double _timeDiff(double t1, double t2) => _fixHour(t2 - t1);

  PrayerTime? getPrayerTimes(AppLocation location, DateTime date,
      {double? timezoneHours}) {
    _timeZone = timezoneHours ??
        date.timeZoneOffset.inMinutes / 60.0;
    _lat = location.latitude;
    _lng = location.longitude;
    _jDate = _julianDate(date.year, date.month, date.day);
    _jDate -= location.longitude / (15 * 24);
    try {
      final c = _computeDayTimes();
      return PrayerTime(
        fajr: timeStringToDateOn(date, c[0]),
        sunrise: timeStringToDateOn(date, c[1]),
        dhuhr: timeStringToDateOn(date, c[2]),
        asr: timeStringToDateOn(date, c[3]),
        maghrib: timeStringToDateOn(date, c[4]),
        isha: timeStringToDateOn(date, c[5]),
      );
    } catch (_) {
      return null;
    }
  }

  String _floatToTime24(double time) {
    if (time.isNaN || time.isInfinite) return _invalidTime;
    final fixed = _fixHour(time + 0.5 / 60);
    final h = fixed.floor();
    final m = ((fixed - h) * 60).floor();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  List<double> _computeTimes(List<double> times) {
    final t = times.map((x) => x / 24).toList();
    final params = _methodParams[attribute.calculationMethod]!;
    final fajr = _computeTime(180 - params[0], t[0]);
    final sunrise = _computeTime(180 - 0.833, t[1]);
    final dhuhr = _computeMidDay(t[2]);
    final asr = _computeAsr(1.0 + attribute.asrMethod.index, t[3]);
    final sunset = _computeTime(0.833, t[4]);
    final maghrib = _computeTime(params[2], t[5]);
    final isha = _computeTime(params[4], t[6]);
    return [fajr, sunrise, dhuhr, asr, sunset, maghrib, isha];
  }

  List<String> _computeDayTimes() {
    var times = <double>[5, 6, 12, 13, 18, 18, 18];
    for (var i = 0; i < _numIterations; i++) {
      times = _computeTimes(times);
    }
    times = _adjustTimes(times);
    return _adjustTimesFormat(times);
  }

  List<double> _adjustTimes(List<double> times) {
    final params = _methodParams[attribute.calculationMethod]!;
    for (var i = 0; i < times.length; i++) {
      times[i] += _timeZone - _lng / 15;
    }
    if (params[1] == 1) times[5] = times[4] + params[2] / 60;
    if (params[3] == 1) times[6] = times[5] + params[4] / 60;
    if (attribute.higherLatitudeMethod != HigherLatitudeMethod.none) {
      times = _adjustHighLatTimes(times);
    }
    return times;
  }

  List<String> _adjustTimesFormat(List<double> times) {
    final result = times.map(_floatToTime24).toList();
    result.removeAt(4);
    return result;
  }

  List<double> _adjustHighLatTimes(List<double> times) {
    final params = _methodParams[attribute.calculationMethod]!;
    final nightTime = _timeDiff(times[4], times[1]);

    final fajrDiff = _nightPortion(params[0]) * nightTime;
    if (times[0].isNaN || _timeDiff(times[0], times[1]) > fajrDiff) {
      times[0] = times[1] - fajrDiff;
    }

    final ishaAngle = params[3] == 0 ? params[4] : 18;
    final ishaDiff = _nightPortion(ishaAngle.toDouble()) * nightTime;
    if (times[6].isNaN || _timeDiff(times[4], times[6]) > ishaDiff) {
      times[6] = times[4] + ishaDiff;
    }

    final maghribAngle = params[1] == 0 ? params[2] : 4;
    final maghribDiff = _nightPortion(maghribAngle.toDouble()) * nightTime;
    if (times[5].isNaN || _timeDiff(times[4], times[5]) > maghribDiff) {
      times[5] = times[4] + maghribDiff;
    }

    return times;
  }

  double _nightPortion(double angle) {
    switch (attribute.higherLatitudeMethod) {
      case HigherLatitudeMethod.angleBased:
        return angle / 60;
      case HigherLatitudeMethod.midNight:
        return 0.5;
      case HigherLatitudeMethod.oneSeven:
        return 0.14286;
      case HigherLatitudeMethod.none:
        return 0.14286;
    }
  }
}
