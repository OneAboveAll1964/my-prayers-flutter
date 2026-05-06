import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/prayer_time.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.currentIndex,
    required this.language,
  });

  final PrayerTime prayer;
  final int currentIndex;
  final String language;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final times = prayer.all;
    final intl = _intlLocale(language);

    final rows = <Widget>[];
    for (var i = 0; i < times.length; i++) {
      rows.add(_PrayerRow(
        label: l10n.t('prayers.${prayerKeys[i]}'),
        time: DateFormat.Hm(intl).format(times[i]),
        active: i == currentIndex,
      ));
      if (i < times.length - 1) {
        rows.add(Container(
          height: 1,
          color: palette.line,
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: rows),
    );
  }

  String _intlLocale(String code) {
    if (code == 'ckb' || code == 'ckb_Badini') return 'ar';
    return code;
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.label,
    required this.time,
    required this.active,
  });

  final String label;
  final String time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: active ? palette.accentSoft : Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? palette.accent : palette.lineStrong,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: active ? palette.accent : palette.text,
              fontSize: 16,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
