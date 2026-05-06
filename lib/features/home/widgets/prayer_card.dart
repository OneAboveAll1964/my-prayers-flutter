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

    final children = <Widget>[];
    for (var i = 0; i < times.length; i++) {
      final active = i == currentIndex;
      final prevActive = i > 0 && i - 1 == currentIndex;
      children.add(_PrayerRow(
        label: l10n.t('prayers.${prayerKeys[i]}'),
        time: DateFormat.Hm(intl).format(times[i]),
        active: active,
      ));
      if (i < times.length - 1 && !active && !prevActive) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(height: 1, color: palette.line),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      child: Column(children: children),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: active ? palette.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: active ? palette.accentStrong : palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: active ? palette.accentStrong : palette.text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.17,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
