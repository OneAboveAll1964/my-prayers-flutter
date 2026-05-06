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
              year: _year,
              month: _month,
              monthLabel: DateFormat.yMMMM(intl).format(DateTime(_year, _month)),
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
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                          itemCount: _entries.length,
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            final today = isSameDay(e.key, now);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DayCard(
                                date: e.key,
                                prayer: e.value,
                                today: today,
                                intl: intl,
                              ),
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
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
  });

  final int year;
  final int month;
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.chevron_left_rounded,
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
            icon: Icons.chevron_right_rounded,
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
  });

  final DateTime date;
  final PrayerTime? prayer;
  final bool today;
  final String intl;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    return Container(
      decoration: BoxDecoration(
        color: today ? palette.accentSoft : palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
            color: today ? palette.accent.withValues(alpha: 0.4) : palette.line),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat.d().format(date),
                style: TextStyle(
                  color: today ? palette.accent : palette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat.E(intl).format(date),
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                formatHijriDayMonth(
                    date, intl == 'ar' ? 'ar' : 'en'),
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (prayer != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (var i = 0; i < prayer!.all.length; i++)
                  _Pill(
                    label: l10n.t('prayers.${prayerKeys[i]}'),
                    value: DateFormat.Hm(intl).format(prayer!.all[i]),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(l10n.t('common.error'),
                style: TextStyle(color: palette.textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  color: palette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
