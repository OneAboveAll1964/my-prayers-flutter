enum CalculationMethod {
  makkah,
  mwl,
  isna,
  karachi,
  egypt,
  jafari,
  tehran,
  custom,
}

enum AsrMethod { shafii, hanafi }

enum HigherLatitudeMethod { angleBased, midNight, oneSeven, none }

class CustomMethod {
  const CustomMethod({this.fajrAngle = 18.0, this.ishaAngle = 17.0});
  final double fajrAngle;
  final double ishaAngle;
}

class PrayerAttribute {
  PrayerAttribute({
    this.calculationMethod = CalculationMethod.makkah,
    this.customMethod = const CustomMethod(),
    this.asrMethod = AsrMethod.shafii,
    this.higherLatitudeMethod = HigherLatitudeMethod.angleBased,
    this.offsets = const [0, 0, 0, 0, 0, 0],
  });

  final CalculationMethod calculationMethod;
  final CustomMethod customMethod;
  final AsrMethod asrMethod;
  final HigherLatitudeMethod higherLatitudeMethod;
  final List<int> offsets;
}

class PrayerTime {
  const PrayerTime({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  PrayerTime copyWith({
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
  }) =>
      PrayerTime(
        fajr: fajr ?? this.fajr,
        sunrise: sunrise ?? this.sunrise,
        dhuhr: dhuhr ?? this.dhuhr,
        asr: asr ?? this.asr,
        maghrib: maghrib ?? this.maghrib,
        isha: isha ?? this.isha,
      );

  List<DateTime> get all => [fajr, sunrise, dhuhr, asr, maghrib, isha];
}

const prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
