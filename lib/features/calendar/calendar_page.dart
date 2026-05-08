import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/hijri.dart';
import '../../shared/data/prayer_time_repository.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import 'package:ionicons/ionicons.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late int _year;
  late int _month;
  bool _loading = false;
  List<MapEntry<DateTime, PrayerTime?>> _entries = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsProvider);
    if (settings.location == null) {
      setState(() {
        _entries = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final list = await PrayerTimeRepository.instance.getMonthPrayerTimes(
      location: settings.location!,
      year: _year,
      month: _month,
      attribute: settings.toAttribute(),
      useFixedPrayer: settings.useFixedTimes,
    );
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider);
    final palette = context.palette;
    final intl = _intlLocale(l10n.locale.languageCode);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('calendar.title'), back: true),
            _MonthSwitcher(
              monthLabel:
                  DateFormat.yMMMM(intl).format(DateTime(_year, _month)),
              onPrev: () {
                setState(() {
                  if (_month == 1) {
                    _month = 12;
                    _year -= 1;
                  } else {
                    _month -= 1;
                  }
                });
                _load();
              },
              onNext: () {
                setState(() {
                  if (_month == 12) {
                    _month = 1;
                    _year += 1;
                  } else {
                    _month += 1;
                  }
                });
                _load();
              },
            ),
            Expanded(
              child: settings.location == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          l10n.t('home.noLocation'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textMuted),
                        ),
                      ),
                    )
                  : _loading
                      ? const PageLoader()
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(18, 4, 18, 28),
                          itemCount: _entries.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            final today = isSameDay(e.key, now);
                            return _DayCard(
                              date: e.key,
                              prayer: e.value,
                              today: today,
                              intl: intl,
                              timeFormat: settings.timeFormat,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _intlLocale(String code) {
    if (code == 'ckb' || code == 'ckb_Badini') return 'ar';
    return code;
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
  });

  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          AppIconButton(
            icon: Ionicons.chevron_back,
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                monthLabel,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          AppIconButton(
            icon: Ionicons.chevron_forward,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.prayer,
    required this.today,
    required this.intl,
    required this.timeFormat,
  });

  final DateTime date;
  final PrayerTime? prayer;
  final bool today;
  final String intl;
  final String timeFormat;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final fmt = timeFormat == '12h' ? DateFormat.jm(intl) : DateFormat.Hm(intl);

    return Container(
      decoration: BoxDecoration(
        color: today ? palette.accentSoft : palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: today ? palette.accent : palette.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat.d().format(date),
                style: TextStyle(
                  color: today ? palette.accentStrong : palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E(intl).format(date),
                    style: TextStyle(
                      color: today ? palette.accentStrong : palette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatHijriDayMonth(date, intl),
                    style: TextStyle(
                      color: today
                          ? palette.accentStrong.withValues(alpha: 0.7)
                          : palette.textSubtle,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              if (today) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'TODAY',
                    style: TextStyle(
                      color: palette.accentOn,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (prayer != null) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: today ? palette.accent.withValues(alpha: 0.18) : palette.line),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 14,
              childAspectRatio: 2.3,
              children: [
                for (var i = 0; i < prayer!.all.length; i++)
                  _Cell(
                    label: l10n.t('prayers.${prayerKeys[i]}'),
                    value: fmt.format(prayer!.all[i]),
                    today: today,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, required this.today});
  final String label;
  final String value;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: today ? palette.accentStrong : palette.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: today ? palette.accentStrong : palette.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
