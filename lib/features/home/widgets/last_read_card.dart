import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/state/favorites_provider.dart';

class LastReadCard extends StatefulWidget {
  const LastReadCard({super.key, required this.entry});
  final LastReadEntry entry;

  @override
  State<LastReadCard> createState() => _LastReadCardState();
}

class _LastReadCardState extends State<LastReadCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chev =
        isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push(
        '/quran/${widget.entry.number}?ayah=${widget.entry.lastAyah}'
        '&name=${Uri.encodeComponent(widget.entry.englishName)}'
        '&ar=${Uri.encodeComponent(widget.entry.name)}'
        '&n=${widget.entry.ayahCount}',
      ),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.accentSoft,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.t('favorites.lastRead').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: palette.accentStrong.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.entry.lastAyah > 1
                        ? '${widget.entry.englishName} · ${widget.entry.number}:${widget.entry.lastAyah}'
                        : widget.entry.englishName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.accentStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.entry.name,
              style: TextStyle(
                color: palette.accentStrong,
                fontFamily: 'UthmanicHafs',
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 6),
            Icon(chev, size: 18, color: palette.accentStrong),
          ],
        ),
      ),
    );
  }
}
