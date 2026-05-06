import 'dart:math' as math;

const _kaabaLat = 21.4225;
const _kaabaLng = 39.8262;

double _toRad(double d) => d * math.pi / 180;
double _toDeg(double r) => r * 180 / math.pi;

double qiblaBearing(double lat, double lng) {
  final phi1 = _toRad(lat);
  final phi2 = _toRad(_kaabaLat);
  final dLng = _toRad(_kaabaLng - lng);
  final y = math.sin(dLng) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
  return (_toDeg(math.atan2(y, x)) + 360) % 360;
}

int distanceToKaabaKm(double lat, double lng) {
  const r = 6371;
  final dLat = _toRad(_kaabaLat - lat);
  final dLng = _toRad(_kaabaLng - lng);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_toRad(lat)) *
          math.cos(_toRad(_kaabaLat)) *
          math.pow(math.sin(dLng / 2), 2);
  return (r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))).round();
}
