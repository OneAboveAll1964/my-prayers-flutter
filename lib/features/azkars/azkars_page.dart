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
    setState(() {
      _categories = cats;
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
        Expanded(
          child: _loading
              ? const PageLoader()
              : _query.trim().isNotEmpty
                  ? _SearchResults(results: _searchResults)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      children: [
                        if (starred.isNotEmpty) ...[
                          _SectionLabel(label: l10n.t('favorites.starred')),
                          const SizedBox(height: 6),
                          _StarredList(chapters: starred),
                          const SizedBox(height: 14),
                        ],
                        for (var i = 0; i < _categories.length; i++) ...[
                          _CategoryTile(cat: _categories[i]),
                          if (i < _categories.length - 1)
                            const SizedBox(height: 10),
                        ],
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
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          color: palette.textSubtle,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StarredList extends StatelessWidget {
  const _StarredList({required this.chapters});
  final List<AzkarChapter> chapters;

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
          for (var i = 0; i < chapters.length; i++) ...[
            _ChapterListRow(chapter: chapters[i], starred: true),
            if (i < chapters.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({required this.cat});
  final AzkarCategory cat;
  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
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
      onTap: () => context.push('/azkars/category/${widget.cat.id}'),
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.surface,
          border: Border.all(color: palette.line),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.cat.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isRtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: palette.textSubtle,
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < results.length; i++) ...[
                _ChapterListRow(chapter: results[i]),
                if (i < results.length - 1)
                  Container(height: 1, color: palette.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChapterListRow extends StatefulWidget {
  const _ChapterListRow({required this.chapter, this.starred = false});
  final AzkarChapter chapter;
  final bool starred;

  @override
  State<_ChapterListRow> createState() => _ChapterListRowState();
}

class _ChapterListRowState extends State<_ChapterListRow> {
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: _down ? palette.surface2 : Colors.transparent,
        child: Row(
          children: [
            if (widget.starred) ...[
              Icon(Icons.star_rounded,
                  size: 16, color: palette.accent),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                widget.chapter.name,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
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
          ],
        ),
      ),
    );
  }
}
