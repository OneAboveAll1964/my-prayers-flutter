class AppLocation {
  AppLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.hasFixedPrayerTime,
    this.prayerDependentId,
    required this.countryCode,
    required this.countryName,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool hasFixedPrayerTime;
  final int? prayerDependentId;
  final String countryCode;
  final String countryName;

  factory AppLocation.fromMap(Map<String, dynamic> m) => AppLocation(
        id: m['id'] as int,
        name: (m['name'] ?? '') as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        hasFixedPrayerTime: (m['has_fixed_prayer_time'] ?? 0) == 1 ||
            (m['has_fixed_prayer_time'] == true),
        prayerDependentId: m['prayer_dependent_id'] as int?,
        countryCode: (m['country_code'] ?? '') as String,
        countryName: (m['country_name'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'has_fixed_prayer_time': hasFixedPrayerTime,
        'prayer_dependent_id': prayerDependentId,
        'country_code': countryCode,
        'country_name': countryName,
      };

  factory AppLocation.fromJson(Map<String, dynamic> j) => AppLocation(
        id: j['id'] as int,
        name: j['name'] as String,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        hasFixedPrayerTime: j['has_fixed_prayer_time'] as bool,
        prayerDependentId: j['prayer_dependent_id'] as int?,
        countryCode: j['country_code'] as String,
        countryName: j['country_name'] as String,
      );
}
