class HijriDate {
  HijriDate({required this.year, required this.month, required this.day});
  final int year;
  final int month;
  final int day;
}

const _kMonthsAr = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
  'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
  'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

const _kMonthsEn = [
  'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
  'Jumada al-Ula', 'Jumada al-Thaniya', 'Rajab', 'Shaban',
  'Ramadan', 'Shawwal', 'Dhu al-Qadah', 'Dhu al-Hijjah',
];

HijriDate gregorianToHijri(DateTime date) {
  final jd = _gregorianToJulianDay(date.year, date.month, date.day);
  return _julianDayToHijri(jd);
}

int _gregorianToJulianDay(int y, int m, int d) {
  if (m < 3) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524;
}

HijriDate _julianDayToHijri(int jd) {
  jd = jd - 1;
  final l1 = jd - 1948440 + 10632;
  final n = ((l1 - 1) / 10631).floor();
  final l2 = l1 - 10631 * n + 354;
  final j = (((10985 - l2) / 5316).floor()) * ((50 * l2 / 17719).floor()) +
      ((l2 / 5670).floor()) * ((43 * l2 / 15238).floor());
  final l3 = l2 -
      ((30 - j) / 15).floor() * ((17719 * j / 50).floor()) -
      (j / 16).floor() * ((15238 * j / 43).floor()) +
      29;
  final m = ((24 * l3) / 709).floor();
  final d = l3 - ((709 * m) / 24).floor();
  final y = 30 * n + j - 30;
  return HijriDate(year: y, month: m, day: d);
}

String hijriMonthName(int month, String langCode) {
  final i = (month - 1).clamp(0, 11);
  if (langCode == 'ar' || langCode == 'ckb' || langCode == 'ckb_Badini') {
    return _kMonthsAr[i];
  }
  return _kMonthsEn[i];
}

String formatHijri(DateTime date, String langCode) {
  final h = gregorianToHijri(date);
  return '${h.day} ${hijriMonthName(h.month, langCode)} ${h.year}';
}

String formatHijriDayMonth(DateTime date, String langCode) {
  final h = gregorianToHijri(date);
  return '${h.day} ${hijriMonthName(h.month, langCode)}';
}
