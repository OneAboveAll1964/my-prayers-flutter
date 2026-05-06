import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/prayer_time.dart';

class NextPrayerCountdown extends StatelessWidget {
  const NextPrayerCountdown({
    super.key,
    required this.prayer,
    required this.tomorrowPrayer,
    required this.language,
  });

  final PrayerTime prayer;
  final PrayerTime? tomorrowPrayer;
  final String language;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final intl = _intlLocale(language);
    final times = prayer.all;
    final now = DateTime.now();

    int nextIdx = -1;
    for (var i = 0; i < times.length; i++) {
      if (times[i].isAfter(now)) {
        nextIdx = i;
        break;
      }
    }

    DateTime nextAt;
    DateTime previousAt;
    String label;
    if (nextIdx >= 0) {
      nextAt = times[nextIdx];
      label = l10n.t('prayers.${prayerKeys[nextIdx]}');
      previousAt = nextIdx > 0
          ? times[nextIdx - 1]
          : times.first.subtract(const Duration(hours: 6));
    } else if (tomorrowPrayer != null) {
      nextAt = tomorrowPrayer!.fajr;
      label = l10n.t('prayers.fajr');
      previousAt = times.last;
    } else {
      return const SizedBox.shrink();
    }

    final remaining = nextAt.difference(now);
    final totalInterval = nextAt.difference(previousAt).inSeconds;
    final elapsed = totalInterval - remaining.inSeconds;
    final progress = totalInterval > 0
        ? (elapsed / totalInterval).clamp(0.0, 1.0)
        : 0.0;

    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final atTime = DateFormat.Hm(intl).format(nextAt);

    final onAccent = palette.accentOn;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.t('home.next').toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onAccent.withValues(alpha: 0.78),
                  letterSpacing: 1.4,
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: onAccent,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: onAccent,
                      letterSpacing: -1.5,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  atTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onAccent.withValues(alpha: 0.85),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(color: onAccent.withValues(alpha: 0.18)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: onAccent),
                  ),
                ],
              ),
            ),
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
