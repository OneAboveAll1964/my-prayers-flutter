import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/surah_name_font_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/state/favorites_provider.dart';
import 'package:ionicons/ionicons.dart';

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
    final isEn = l10n.locale.languageCode == 'en';
    final chev =
        isRtl ? Ionicons.chevron_back : Ionicons.chevron_forward;

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
                  isEn
                      ? Text(
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
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              SurahNameFont.glyphFor(widget.entry.number),
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 26,
                                height: 1.0,
                                color: palette.accentStrong,
                                fontFamily: SurahNameFont.fontFamily,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.entry.lastAyah > 1) ...[
                              Text(
                                ' · ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accentStrong,
                                ),
                              ),
                              Text(
                                '${widget.entry.number}:${widget.entry.lastAyah}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accentStrong,
                                ),
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),
            if (isEn) ...[
              const SizedBox(width: 8),
              Text(
                SurahNameFont.glyphFor(widget.entry.number),
                style: TextStyle(
                  color: palette.accentStrong,
                  fontFamily: SurahNameFont.fontFamily,
                  fontSize: 28,
                  height: 1.0,
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(chev, size: 18, color: palette.accentStrong),
          ],
        ),
      ),
    );
  }
}
