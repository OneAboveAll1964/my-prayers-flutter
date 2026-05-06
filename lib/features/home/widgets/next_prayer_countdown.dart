import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/prayer_time.dart';

class NextPrayerCountdown extends StatelessWidget {
  const NextPrayerCountdown({
    super.key,
    required this.prayer,
    required this.language,
  });

  final PrayerTime prayer;
  final String language;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final times = prayer.all;
    final now = DateTime.now();
    final intl = _intlLocale(language);

    int nextIdx = -1;
    for (var i = 0; i < times.length; i++) {
      if (times[i].isAfter(now)) {
        nextIdx = i;
        break;
      }
    }
    if (nextIdx == -1) return const SizedBox.shrink();

    final remaining = times[nextIdx].difference(now);
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    final label = l10n.t('prayers.${prayerKeys[nextIdx]}');
    final atTime = DateFormat.Hm(intl).format(times[nextIdx]);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.t('home.next').toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.accentOn.withValues(alpha: 0.85),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.accentOn,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: palette.accentOn,
                    letterSpacing: -1,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  atTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.accentOn.withValues(alpha: 0.85),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _intlLocale(String code) {
    if (code == 'ckb' || code == 'ckb_Badini') return 'ar';
    return code;
  }
}
