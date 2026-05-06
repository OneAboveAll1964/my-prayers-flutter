import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/hisnul_repository.dart';
import '../../shared/models/azkar.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';

class AzkarsPage extends ConsumerStatefulWidget {
  const AzkarsPage({super.key});
  @override
  ConsumerState<AzkarsPage> createState() => _AzkarsPageState();
}

class _AzkarsPageState extends ConsumerState<AzkarsPage> {
  List<AzkarCategory> _categories = [];
  List<AzkarChapter> _allChapters = [];
  List<AzkarChapter> _searchResults = [];
  bool _loading = true;
  String _query = '';
  int? _selectedCategoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppL10n.of(context);
    final lang = langKey(l10n.locale);
    final cats = await HisnulMuslimRepository.instance.getCategories(lang);
    final chapters = await HisnulMuslimRepository.instance
        .getChapters(langCode: lang);
    if (!mounted) return;
    final allWord = l10n.t('azkars.all').toLowerCase();
    final filtered = cats
        .where((c) {
          final n = c.name.trim().toLowerCase();
          return n.isNotEmpty &&
              n != allWord &&
              n != 'all' &&
              n != 'الكل' &&
              n != 'كل' &&
              n != 'هەموو' &&
              n != 'هەمی';
        })
        .toList();
    setState(() {
      _categories = filtered;
      _allChapters = chapters;
      _loading = false;
    });
  }

  Future<void> _runSearch(String q) async {
    final l10n = AppL10n.of(context);
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await HisnulMuslimRepository.instance
        .searchChapters(langCode: langKey(l10n.locale), query: q);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);
    final starred = _allChapters
        .where((c) => fav.chapters.contains(c.id))
        .toList();
    final searching = _query.trim().isNotEmpty;

    final filteredChapters = _selectedCategoryId == null
        ? _allChapters
        : _allChapters
            .where((c) => c.categoryId == _selectedCategoryId)
            .toList();

    return Column(
      children: [
        PageHeader(
          title: l10n.t('azkars.title'),
          search: AppTextField(
            hintText: l10n.t('azkars.search'),
            prefix:
                Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
            onChanged: (v) {
              setState(() => _query = v);
              _runSearch(v);
            },
          ),
        ),
        if (!_loading && !searching && _categories.isNotEmpty)
          _CategoryFilterStrip(
            categories: _categories,
            selectedId: _selectedCategoryId,
            allLabel: l10n.t('azkars.all'),
            onPick: (id) => setState(() => _selectedCategoryId = id),
          ),
        Expanded(
          child: _loading
              ? const PageLoader()
              : searching
                  ? _SearchResults(results: _searchResults)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      children: [
                        if (starred.isNotEmpty &&
                            _selectedCategoryId == null) ...[
                          _SectionLabel(label: l10n.t('favorites.starred')),
                          const SizedBox(height: 8),
                          _ChapterCard(chapters: starred, starred: true),
                          const SizedBox(height: 18),
                        ],
                        if (filteredChapters.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              l10n.t('common.noResults'),
                              style: TextStyle(color: palette.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          _ChapterCard(chapters: filteredChapters),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _CategoryFilterStrip extends StatelessWidget {
  const _CategoryFilterStrip({
    required this.categories,
    required this.selectedId,
    required this.allLabel,
    required this.onPick,
  });

  final List<AzkarCategory> categories;
  final int? selectedId;
  final String allLabel;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return _Chip(
              label: allLabel,
              selected: selectedId == null,
              onTap: () => onPick(null),
            );
          }
          final c = categories[i - 1];
          return _Chip(
            label: c.name,
            selected: selectedId == c.id,
            onTap: () => onPick(c.id),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 1.2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? palette.accentStrong : palette.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: palette.textSubtle,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _ChapterCard extends ConsumerWidget {
  const _ChapterCard({required this.chapters, this.starred = false});
  final List<AzkarChapter> chapters;
  final bool starred;

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
          for (var i = 0; i < chapters.length; i++) ...[
            _ChapterRow(
              chapter: chapters[i],
              isStarred: fav.chapters.contains(chapters[i].id),
              showCategory: !starred,
              onStar: () => ref
                  .read(favoritesProvider.notifier)
                  .toggleChapter(chapters[i].id),
            ),
            if (i < chapters.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(height: 1, color: palette.line),
              ),
          ],
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});
  final List<AzkarChapter> results;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          l10n.t('common.noResults'),
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _ChapterCard(chapters: results),
      ],
    );
  }
}

class _ChapterRow extends StatefulWidget {
  const _ChapterRow({
    required this.chapter,
    required this.isStarred,
    required this.onStar,
    this.showCategory = false,
  });

  final AzkarChapter chapter;
  final bool isStarred;
  final VoidCallback onStar;
  final bool showCategory;

  @override
  State<_ChapterRow> createState() => _ChapterRowState();
}

class _ChapterRowState extends State<_ChapterRow> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.push(
          '/azkars/chapter/${widget.chapter.id}?name=${Uri.encodeComponent(widget.chapter.name)}'),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        color: _down ? palette.surface2 : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.chapter.name,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (widget.showCategory) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.chapter.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textSubtle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onStar,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  widget.isStarred
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 20,
                  color: widget.isStarred
                      ? palette.accent
                      : palette.textSubtle,
                ),
              ),
            ),
            Icon(
              isRtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: palette.textSubtle,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
