import 'package:flutter/material.dart';
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

    int nextIdx = -1;
    for (var i = 0; i < times.length; i++) {
      if (times[i].isAfter(now)) {
        nextIdx = i;
        break;
      }
    }
    if (nextIdx == -1) return const SizedBox.shrink();

    final remaining = times[nextIdx].difference(now);
    final h = remaining.inHours.remainder(24);
    final m = remaining.inMinutes.remainder(60);
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    final label = l10n.t('prayers.${prayerKeys[nextIdx]}');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('home.next'),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.t('home.in'),
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 22,
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
