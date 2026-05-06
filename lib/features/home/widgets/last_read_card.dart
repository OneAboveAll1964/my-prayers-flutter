import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/state/favorites_provider.dart';

class LastReadCard extends StatelessWidget {
  const LastReadCard({super.key, required this.entry});
  final LastReadEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chev = isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/quran/${entry.number}?ayah=${entry.lastAyah}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.menu_book_rounded,
                  size: 18, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('favorites.lastRead'),
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.englishName} · ${entry.number}:${entry.lastAyah}',
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.name,
              style: TextStyle(
                color: palette.textMuted,
                fontFamily: 'AmiriQuran',
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            Icon(chev, size: 18, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}
