import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/quran_repository.dart';
import '../../shared/models/quran.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
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
    final font = arabicFontFamilies[settings.arabicFont] ?? 'UthmanicHafs';

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
          action: AppIconButton(
            icon: Icons.text_fields_rounded,
            semanticLabel: l10n.t('settings.arabicFont'),
            onPressed: () {
              showAppSheet(
                context: context,
                title: l10n.t('settings.arabicFont'),
                builder: (ctx) => const ArabicFontPicker(),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const PageLoader()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                  children: [
                    if (q.isEmpty && fav.lastSurah != null)
                      LastReadCard(entry: fav.lastSurah!),
                    if (q.isEmpty && bookmarked.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionLabel(label: l10n.t('favorites.bookmarked')),
                      const SizedBox(height: 6),
                      _SurahList(items: bookmarked, arabicFont: font),
                    ],
                    if (q.isEmpty && fav.ayahs.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionLabel(label: l10n.t('favorites.bookmarkedAyahs')),
                      const SizedBox(height: 6),
                      _AyahBookmarksList(items: fav.ayahs),
                    ],
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          l10n.t('common.noResults'),
                          style: TextStyle(color: palette.textMuted),
                        ),
                      )
                    else
                      _SurahList(items: filtered, arabicFont: font),
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
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: Text(label,
          style: TextStyle(
              color: palette.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4)),
    );
  }
}

class _SurahList extends ConsumerWidget {
  const _SurahList({required this.items, required this.arabicFont});
  final List<SurahMeta> items;
  final String arabicFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
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
            _SurahRow(
              item: items[i],
              arabicFont: arabicFont,
              bookmarked: fav.surahs.contains(items[i].number),
              onBookmarkTap: () => ref
                  .read(favoritesProvider.notifier)
                  .toggleBookmarkSurah(items[i].number),
            ),
            if (i < items.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _SurahRow extends StatefulWidget {
  const _SurahRow({
    required this.item,
    required this.arabicFont,
    required this.bookmarked,
    required this.onBookmarkTap,
  });
  final SurahMeta item;
  final String arabicFont;
  final bool bookmarked;
  final VoidCallback onBookmarkTap;
  @override
  State<_SurahRow> createState() => _SurahRowState();
}

class _SurahRowState extends State<_SurahRow> {
  bool _downBody = false;
  bool _downBm = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _downBody = true),
            onTapCancel: () => setState(() => _downBody = false),
            onTapUp: (_) => setState(() => _downBody = false),
            onTap: () => context.push('/quran/${widget.item.number}'),
            child: AnimatedContainer(
              duration: AppTokens.durationFast,
              color: _downBody ? palette.surface2 : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${widget.item.number}',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.englishName,
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.item.englishNameTranslation} · ${widget.item.ayahCount} ${l10n.t('quran.ayahs')}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.item.name,
                    style: TextStyle(
                      color: palette.text,
                      fontFamily: widget.arabicFont,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _downBm = true),
          onTapCancel: () => setState(() => _downBm = false),
          onTapUp: (_) => setState(() => _downBm = false),
          onTap: widget.onBookmarkTap,
          child: AnimatedContainer(
            duration: AppTokens.durationFast,
            margin: const EdgeInsets.only(right: 8),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _downBm ? palette.surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              widget.bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              size: 18,
              color: widget.bookmarked ? palette.accent : palette.textSubtle,
            ),
          ),
        ),
      ],
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

class _AyahBookmarkRow extends ConsumerStatefulWidget {
  const _AyahBookmarkRow({required this.entry});
  final AyahBookmarkEntry entry;

  @override
  ConsumerState<_AyahBookmarkRow> createState() => _AyahBookmarkRowState();
}

class _AyahBookmarkRowState extends ConsumerState<_AyahBookmarkRow> {
  bool _downBody = false;
  bool _downRm = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = widget.entry;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _downBody = true),
            onTapCancel: () => setState(() => _downBody = false),
            onTapUp: (_) => setState(() => _downBody = false),
            onTap: () =>
                context.push('/quran/${entry.surah}?ayah=${entry.ayah}'),
            child: AnimatedContainer(
              duration: AppTokens.durationFast,
              color: _downBody ? palette.surface2 : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${entry.surah}:${entry.ayah}',
                      style: TextStyle(
                        color: palette.accentStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.surahName,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.preview.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              entry.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.textSubtle,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (entry.arabicName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        entry.arabicName,
                        style: TextStyle(
                          color: palette.text,
                          fontFamily: 'UthmanicHafs',
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _downRm = true),
          onTapCancel: () => setState(() => _downRm = false),
          onTapUp: (_) => setState(() => _downRm = false),
          onTap: () => ref
              .read(favoritesProvider.notifier)
              .toggleBookmarkAyah(entry.surah, entry.ayah),
          child: AnimatedContainer(
            duration: AppTokens.durationFast,
            margin: const EdgeInsets.only(right: 8),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _downRm ? palette.surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(Icons.bookmark_rounded,
                size: 16, color: palette.accent),
          ),
        ),
      ],
    );
  }
}
