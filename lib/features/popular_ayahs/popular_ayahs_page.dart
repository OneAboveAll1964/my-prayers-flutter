import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/services/surah_name_font_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/page_scaffold.dart';

class PopularAyahsPage extends ConsumerWidget {
  const PopularAyahsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final entries = _popularEntries(l10n);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('popular.title')),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.t('popular.description'),
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _PopularTile(entry: entries[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PopularEntry {
  const PopularEntry({
    required this.surah,
    required this.startAyah,
    required this.endAyah,
    required this.title,
    required this.reference,
    required this.benefit,
  });

  final int surah;
  final int startAyah;
  final int endAyah;
  final String title;
  final String reference;
  final String benefit;
}

List<PopularEntry> _popularEntries(AppL10n l10n) {
  String t(String key) => l10n.t(key);
  return [
    PopularEntry(
      surah: 1,
      startAyah: 1,
      endAyah: 7,
      title: t('popular.fatiha'),
      reference: '1',
      benefit: t('popular.fatiha_benefit'),
    ),
    PopularEntry(
      surah: 2,
      startAyah: 255,
      endAyah: 255,
      title: t('popular.kursi'),
      reference: '2:255',
      benefit: t('popular.kursi_benefit'),
    ),
    PopularEntry(
      surah: 2,
      startAyah: 285,
      endAyah: 286,
      title: t('popular.baqarahLast2'),
      reference: '2:285-286',
      benefit: t('popular.baqarahLast2_benefit'),
    ),
    PopularEntry(
      surah: 18,
      startAyah: 1,
      endAyah: 10,
      title: t('popular.kahfFirst10'),
      reference: '18:1-10',
      benefit: t('popular.kahfFirst10_benefit'),
    ),
    PopularEntry(
      surah: 18,
      startAyah: 101,
      endAyah: 110,
      title: t('popular.kahfLast10'),
      reference: '18:101-110',
      benefit: t('popular.kahfLast10_benefit'),
    ),
    PopularEntry(
      surah: 18,
      startAyah: 1,
      endAyah: 110,
      title: t('popular.kahf'),
      reference: '18',
      benefit: t('popular.kahf_benefit'),
    ),
    PopularEntry(
      surah: 36,
      startAyah: 1,
      endAyah: 83,
      title: t('popular.yaseen'),
      reference: '36',
      benefit: t('popular.yaseen_benefit'),
    ),
    PopularEntry(
      surah: 55,
      startAyah: 1,
      endAyah: 78,
      title: t('popular.rahman'),
      reference: '55',
      benefit: t('popular.rahman_benefit'),
    ),
    PopularEntry(
      surah: 56,
      startAyah: 1,
      endAyah: 96,
      title: t('popular.waqia'),
      reference: '56',
      benefit: t('popular.waqia_benefit'),
    ),
    PopularEntry(
      surah: 59,
      startAyah: 22,
      endAyah: 24,
      title: t('popular.hashrLast3'),
      reference: '59:22-24',
      benefit: t('popular.hashrLast3_benefit'),
    ),
    PopularEntry(
      surah: 67,
      startAyah: 1,
      endAyah: 30,
      title: t('popular.mulk'),
      reference: '67',
      benefit: t('popular.mulk_benefit'),
    ),
    PopularEntry(
      surah: 112,
      startAyah: 1,
      endAyah: 4,
      title: t('popular.ikhlas'),
      reference: '112',
      benefit: t('popular.ikhlas_benefit'),
    ),
    PopularEntry(
      surah: 113,
      startAyah: 1,
      endAyah: 5,
      title: t('popular.falaq'),
      reference: '113',
      benefit: t('popular.falaq_benefit'),
    ),
    PopularEntry(
      surah: 114,
      startAyah: 1,
      endAyah: 6,
      title: t('popular.nas'),
      reference: '114',
      benefit: t('popular.nas_benefit'),
    ),
  ];
}

class _PopularTile extends StatefulWidget {
  const _PopularTile({required this.entry});
  final PopularEntry entry;

  @override
  State<_PopularTile> createState() => _PopularTileState();
}

class _PopularTileState extends State<_PopularTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = widget.entry;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push(
        '/quran/${entry.surah}?ayah=${entry.startAyah}',
      ),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: palette.line),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(text: entry.title),
                        TextSpan(
                          text: '  ${entry.reference}',
                          style: TextStyle(
                            color: palette.textSubtle,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.benefit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.benefit,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              SurahNameFont.glyphFor(entry.surah),
              style: TextStyle(
                color: palette.text,
                fontFamily: SurahNameFont.fontFamily,
                fontSize: 26,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Ionicons.chevron_back
                  : Ionicons.chevron_forward,
              size: 16,
              color: palette.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
