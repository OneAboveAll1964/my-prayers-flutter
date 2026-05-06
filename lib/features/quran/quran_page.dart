import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/quran_repository.dart';
import '../../shared/models/quran.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../home/widgets/last_read_card.dart';
import '../settings/widgets/arabic_font_picker.dart';

class QuranPage extends ConsumerStatefulWidget {
  const QuranPage({super.key});
  @override
  ConsumerState<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage> {
  bool _loading = true;
  List<SurahMeta> _list = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await QuranRepository.instance.getSurahList();
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final settings = ref.watch(settingsProvider);

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _list
        : _list.where((s) {
            return s.englishName.toLowerCase().contains(q) ||
                s.name.contains(q) ||
                s.number.toString().contains(q);
          }).toList();

    final bookmarked =
        _list.where((s) => fav.surahs.contains(s.number)).toList();

    return Column(
      children: [
        PageHeader(
          title: l10n.t('quran.title'),
          search: AppTextField(
            hintText: l10n.t('quran.search'),
            prefix:
                Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
            onChanged: (v) => setState(() => _query = v),
          ),
          action: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showAppSheet(
                context: context,
                title: l10n.t('settings.arabicFont'),
                builder: (ctx) => const ArabicFontPicker(),
              );
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(Icons.text_fields_rounded,
                    size: 20, color: palette.textMuted),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const PageLoader()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    if (q.isEmpty && fav.lastSurah != null)
                      LastReadCard(entry: fav.lastSurah!),
                    if (q.isEmpty && bookmarked.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionLabel(label: l10n.t('favorites.bookmarked')),
                      const SizedBox(height: 6),
                      _SurahList(
                        items: bookmarked,
                        arabicFont:
                            arabicFontFamilies[settings.arabicFont] ??
                                'AmiriQuran',
                      ),
                    ],
                    if (q.isEmpty && fav.ayahs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionLabel(label: l10n.t('favorites.bookmarkedAyahs')),
                      const SizedBox(height: 6),
                      _AyahBookmarksList(items: fav.ayahs),
                    ],
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          l10n.t('common.noResults'),
                          style: TextStyle(color: palette.textMuted),
                        ),
                      )
                    else
                      _SurahList(
                        items: filtered,
                        arabicFont:
                            arabicFontFamilies[settings.arabicFont] ??
                                'AmiriQuran',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6, bottom: 4),
      child: Text(label,
          style: TextStyle(
              color: palette.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2)),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.items, required this.arabicFont});
  final List<SurahMeta> items;
  final String arabicFont;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SurahRow(item: items[i], arabicFont: arabicFont),
            if (i < items.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _SurahRow extends StatefulWidget {
  const _SurahRow({required this.item, required this.arabicFont});
  final SurahMeta item;
  final String arabicFont;
  @override
  State<_SurahRow> createState() => _SurahRowState();
}

class _SurahRowState extends State<_SurahRow> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push('/quran/${widget.item.number}'),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        color: _down ? palette.surface2 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${widget.item.number}',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.englishName,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${widget.item.englishNameTranslation} · ${widget.item.ayahCount} ${l10n.t('quran.ayahs')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              widget.item.name,
              style: TextStyle(
                color: palette.text,
                fontFamily: widget.arabicFont,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AyahBookmarksList extends ConsumerWidget {
  const _AyahBookmarksList({required this.items});
  final List<AyahBookmarkEntry> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _AyahBookmarkRow(entry: items[i]),
            if (i < items.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _AyahBookmarkRow extends ConsumerWidget {
  const _AyahBookmarkRow({required this.entry});
  final AyahBookmarkEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/quran/${entry.surah}?ayah=${entry.ayah}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '${entry.surah}:${entry.ayah}',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.surahName,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.preview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        entry.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textSubtle,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref
                  .read(favoritesProvider.notifier)
                  .toggleBookmarkAyah(entry.surah, entry.ayah),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(Icons.bookmark_rounded,
                      size: 16, color: palette.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
