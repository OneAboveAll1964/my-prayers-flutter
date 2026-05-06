String toDbDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$m-$d';
}

DateTime timeStringToDateOn(DateTime base, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(
    base.year,
    base.month,
    base.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

DateTime addMinutes(DateTime date, int minutes) =>
    date.add(Duration(minutes: minutes));

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
int daysInMonth(int year, int month) =>
    DateTime(year, month + 1, 0).day;

bool isDst([DateTime? at]) {
  final date = at ?? DateTime.now();
  final jan = DateTime(date.year, 1, 15).timeZoneOffset;
  final jul = DateTime(date.year, 7, 15).timeZoneOffset;
  final standard = jan < jul ? jan : jul;
  return date.timeZoneOffset > standard;
}
